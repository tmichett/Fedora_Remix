"""Import repository OpenPGP keys into a livecd-creator install root.

Fedora 45 sets rpm's %_pkgverify_level to all. livecd-tools installs into an
empty install root and never sets gpgkey= on kickstart repositories, so the
transaction fails with "does not verify ... NOKEY". Stage the third-party
keys used by the standard remix repos, then import those plus the matching
Fedora release keys before the rpm transaction.
"""

import glob
import os
import shutil
import subprocess
import tempfile
import urllib.request

REMIX_KEY_DIR = "/usr/share/pki/rpm-gpg-remix"
FEDORA_KEY_DIR = "/usr/share/pki/rpm-gpg"

# Direct key files. RPM Fusion stopped publishing standalone key URLs; the
# key is extracted from the release RPM below.
DIRECT_KEYS = (
    ("google", "https://dl.google.com/linux/linux_signing_key.pub"),
    ("microsoft", "https://packages.microsoft.com/keys/microsoft.asc"),
    ("github-cli", "https://cli.github.com/packages/githubcli-archive-keyring.asc"),
    ("copr-fedoraremix", "https://download.copr.fedorainfracloud.org/results/tmichett/FedoraRemix/pubkey.gpg"),
    ("copr-yazi", "https://download.copr.fedorainfracloud.org/results/lihaohong/yazi/pubkey.gpg"),
)


def _detect_releasever(releasever):
    if releasever:
        return str(releasever)
    try:
        with open("/etc/fedora-release", encoding="utf-8") as handle:
            for token in handle.read().split():
                if token.isdigit():
                    return token
    except OSError:
        pass
    return None


def _download(url, dest):
    request = urllib.request.Request(url, headers={"User-Agent": "fedora-remix-builder"})
    with urllib.request.urlopen(request, timeout=180) as response, open(dest, "wb") as handle:
        shutil.copyfileobj(response, handle)


def _extract_rpmfusion_key(url, keyname, dest_dir):
    with tempfile.TemporaryDirectory() as tmp:
        rpm_path = os.path.join(tmp, "release.rpm")
        _download(url, rpm_path)
        payload = subprocess.run(["rpm2cpio", rpm_path], check=True, capture_output=True).stdout
        subprocess.run(["cpio", "-id", "--quiet"], input=payload, cwd=tmp, check=True)
        matches = glob.glob(os.path.join(tmp, "**", keyname), recursive=True)
        if not matches:
            raise FileNotFoundError(f"{keyname} not found in {url}")
        shutil.copy(os.path.realpath(matches[0]), os.path.join(dest_dir, keyname))


def stage_remix_keys(releasever, dest=REMIX_KEY_DIR):
    """Download third-party repo keys for this Fedora release."""
    releasever = _detect_releasever(releasever)
    if not releasever:
        raise RuntimeError("Could not determine Fedora release for GPG key staging")

    os.makedirs(dest, exist_ok=True)
    for name in os.listdir(dest):
        path = os.path.join(dest, name)
        if os.path.isfile(path) or os.path.islink(path):
            os.remove(path)

    print(f"Staging OpenPGP keys for Fedora {releasever} in {dest}")
    for name, url in DIRECT_KEYS:
        print(f"  {name}: {url}")
        _download(url, os.path.join(dest, name))

    fusion = (
        (
            f"https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-{releasever}.noarch.rpm",
            f"RPM-GPG-KEY-rpmfusion-free-fedora-{releasever}",
        ),
        (
            f"https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-{releasever}.noarch.rpm",
            f"RPM-GPG-KEY-rpmfusion-nonfree-fedora-{releasever}",
        ),
    )
    for url, keyname in fusion:
        print(f"  {keyname}: {url}")
        _extract_rpmfusion_key(url, keyname, dest)

    staged = sorted(os.listdir(dest))
    if len(staged) < len(DIRECT_KEYS) + len(fusion):
        raise RuntimeError(f"Incomplete key set in {dest}: {staged}")
    print(f"Staged {len(staged)} third-party keys")
    return dest


def _key_files(releasever):
    files = []
    if releasever:
        files.extend(glob.glob(os.path.join(FEDORA_KEY_DIR, f"RPM-GPG-KEY-fedora-{releasever}-*")))
        files.extend(glob.glob(os.path.join(FEDORA_KEY_DIR, f"RPM-GPG-KEY-{releasever}-fedora")))
    if os.path.isdir(REMIX_KEY_DIR):
        for name in sorted(os.listdir(REMIX_KEY_DIR)):
            path = os.path.join(REMIX_KEY_DIR, name)
            if os.path.isfile(path):
                files.append(path)

    unique = []
    seen = set()
    for path in files:
        real = os.path.realpath(path)
        if real in seen or not os.path.isfile(real):
            continue
        seen.add(real)
        unique.append(real)
    return unique


def import_installroot_keys(installroot, releasever=None):
    """Import Fedora and staged third-party keys into installroot's rpmdb."""
    releasever = _detect_releasever(releasever)
    os.makedirs(os.path.join(installroot, "var", "lib", "rpm"), exist_ok=True)
    subprocess.run(["rpm", "--root", installroot, "--initdb"], check=False)

    keys = _key_files(releasever)
    if not keys:
        raise RuntimeError(
            f"No OpenPGP keys found for install root {installroot} (releasever={releasever})"
        )

    print(f"Importing {len(keys)} OpenPGP keys into {installroot} (Fedora {releasever})")
    for key in keys:
        print(f"  rpm --import {key}")
        subprocess.run(["rpm", "--root", installroot, "--import", key], check=True)
    return keys


if __name__ == "__main__":
    import sys

    if len(sys.argv) == 3 and sys.argv[1] == "--stage":
        stage_remix_keys(sys.argv[2])
    else:
        raise SystemExit("usage: import_installroot_keys.py --stage <fedora-version>")
