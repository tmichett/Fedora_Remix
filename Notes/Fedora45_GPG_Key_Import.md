# Fedora 45 GPG key import for livecd-creator

**Date:** 2026-11-05
**Status:** Resolved for the default `FedoraRemix.ks` build. The code change is uncommitted.
**ISO:** `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso` (8.4 GB, bootable, 16m 5s)

This is the full record of why Fedora 45 remix builds died in about 20 seconds with `NOKEY`, which keys the transaction required, and what the build now imports.

## What broke

Fedora 45 sets rpm's `%_pkgverify_level` to `all`. On Fedora 44 that macro was `digest`, so a missing key was only a warning. On Fedora 45, `livecd-creator` aborts the transaction.

The builder container already trusts the Fedora 45 key. `livecd-creator` installs into a second, empty RPM database under `/var/tmp/imgcreate-*/install_root`. Fedora 45 checks signatures against that empty database. `livecd-tools` 31.0 never puts `gpgkey=` on the kickstart repos and never imports keys before `do_transaction`.

Check the macro inside the image:

```bash
podman run --rm --entrypoint rpm ghcr.io/tmichett/fedora-remix-builder:45 --eval '%_pkgverify_level'
# all
```

The container key is present, and it is the same id the build rejected:

```text
gpg-pubkey-4f50a6114cd5c6976a7f1179655a4b02f577861e-6888bc98 Fedora (45) <fedora-45-primary@fedoraproject.org> public key
```

The error key id `655a4b02f577861e` is the last 16 hex digits of that key.

Failed log: `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix-Build-110526-0151.log` (20 seconds, exit 1).

```text
Error creating Live CD : Unable to install: Transaction test error:
  package libgcc-16.2.1-3.fc45.x86_64 does not verify: Header OpenPGP V4 RSA/SHA256 signature, key ID 655a4b02f577861e: NOKEY
```

`imgcreate/dnfinst.py` from `livecd-tools-31.0-23.fc45` (it uses `python3-dnf` 4.24, not dnf5, for the install):

```python
self.download_packages(dlpkgs, DownloadProgress())
# FIXME: sigcheck?

ret = self.do_transaction(TransactionProgress())
```

`addRepository()` sets `baseurl` or `mirrorlist` only. The kickstart `repo` lines in `fedora-repo-not-rawhide.ks` and `FedoraRemixRepos.ks` also omit `--gpgkey`.

Versions in the image that reproduced this: `rpm-6.1.0-1.fc45`, `livecd-tools-31.0-23.fc45`, `dnf5-5.4.6.0-3.fc45`, `python3-dnf-4.24.0-5.fc45`.

## Every key the failed transaction named

Counts are from `FedoraRemix-Build-110526-0151.log`.

| Error key id | Packages | Signer | Example package |
| --- | ---: | --- | --- |
| `655a4b02f577861e` | 2529 | Fedora 45 | `libgcc-16.2.1-3.fc45.x86_64` |
| `6a2af96194843c65` | 6 | RPM Fusion nonfree (2020) | `fdk-aac-3.0.0-1.fc45`, `rpmfusion-nonfree-release-45-2` |
| `e06f8ecdd651ff2e` | 4 | RPM Fusion free (2020) | `x264-libs`, `rpmfusion-free-release-45-2` |
| `1e8c9a37f5114475` | 3 | COPR `tmichett/FedoraRemix` | `fedora_remix_tools-1.0-9`, `dyff-1.9.3-1.fc44`, `LogViewer-4.0.5-0` |
| `bc2926706c3c5e76` | 2 | COPR `lihaohong/yazi` | `yazi-26.9.1-1.fc45`, `resvg-0.47.0-1.fc45` |
| `fd533c07c264648f` | 1 | Google Linux Packages Signing Authority | `google-chrome-stable-157.0.8103.38-1` |
| `eb3e94adbe1229cf` | 1 | Microsoft (Release signing) | `code-1.145.0-1793749416.el8` |
| `5612b36462313325` | 1 | GitHub CLI | `gh-2.103.3-1` |

One missing key fails the whole transaction, so every signer in the kickstart set has to be imported before `do_transaction`.

## Where each key comes from

Fedora 45 is already in the image (`fedora-gpg-keys-45-1`). `RPM-GPG-KEY-fedora-45-x86_64` and `RPM-GPG-KEY-fedora-45-primary` are the same file. Importing either one is enough.

```text
/usr/share/pki/rpm-gpg/RPM-GPG-KEY-fedora-45-x86_64
```

These standalone RPM Fusion URLs return **404** on Fedora 45:

```text
https://download1.rpmfusion.org/free/fedora/RPM-GPG-KEY-rpmfusion-free-fedora-45
https://download1.rpmfusion.org/nonfree/fedora/RPM-GPG-KEY-rpmfusion-nonfree-fedora-45
```

The release RPMs return 200. Inside each RPM the Fedora 45 name is a symlink to the 2020 key:

```text
https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-45.noarch.rpm
  usr/share/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-45
    -> RPM-GPG-KEY-rpmfusion-free-fedora-2020

https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-45.noarch.rpm
  usr/share/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-45
    -> RPM-GPG-KEY-rpmfusion-nonfree-fedora-2020
```

Extract with `rpm2cpio` (that does not require the key you are extracting) and import the real file.

Direct key URLs used by the fix:

```text
https://dl.google.com/linux/linux_signing_key.pub
https://packages.microsoft.com/keys/microsoft.asc
https://cli.github.com/packages/githubcli-archive-keyring.asc
https://download.copr.fedorainfracloud.org/results/tmichett/FedoraRemix/pubkey.gpg
https://download.copr.fedorainfracloud.org/results/lihaohong/yazi/pubkey.gpg
```

The GitHub CLI keyring still contains expired primary `23F3D4EA75716059` (expired 2026-09-05). `rpm --import` warns and also imports the live signing key `5612b36462313325`, which is the id on `gh-2.103.3-1`. Google's key prints warnings for older expired subkeys; `google-chrome-stable-157.0.8103.38-1` still verifies.

## Proof the import is sufficient

```bash
rm -rf /tmp/ir && mkdir -p /tmp/ir
rpm --root /tmp/ir --initdb
rpm --root /tmp/ir --import /usr/share/pki/rpm-gpg/RPM-GPG-KEY-fedora-45-x86_64
rpmkeys --root /tmp/ir -K libgcc-16.2.1-3.fc45.x86_64.rpm
# libgcc-16.2.1-3.fc45.x86_64.rpm: digests signatures OK
```

After importing the full set, `rpm --root /tmp/ir -q gpg-pubkey` showed:

```text
gpg-pubkey-4f50a6114cd5c6976a7f1179655a4b02f577861e-6888bc98 Fedora (45) <fedora-45-primary@fedoraproject.org> public key
gpg-pubkey-e9a491a3de247814e7e067eae06f8ecdd651ff2e-5dadbbc1 RPM Fusion free repository for Fedora (2020) <rpmfusion-buildsys@lists.rpmfusion.org> public key
gpg-pubkey-79bdb88f9bbf73910fd4095b6a2af96194843c65-5dadbc64 RPM Fusion nonfree repository for Fedora (2020) <rpmfusion-buildsys@lists.rpmfusion.org> public key
gpg-pubkey-eb4c1bfd4f042f6dddccec917721f63bd38b4796-570c8cd3 Google Inc. (Linux Packages Signing Authority) <linux-packages-keymaster@google.com> public key
gpg-pubkey-bc528686b50d79e339d3721ceb3e94adbe1229cf-5631588c Microsoft (Release signing) <gpgsecurity@microsoft.com> public key
gpg-pubkey-2c6106201985b60e6c7ac87323f3d4ea75716059-63172e8a GitHub CLI <opensource+cli@github.com> public key
gpg-pubkey-7f38bbb59d064dbcb3d84d725612b36462313325-69d4e1f8 GitHub CLI <opensource+cli@github.com> public key
gpg-pubkey-1432ada3f76111b46b8fc5f31e8c9a37f5114475-68f03fb5 tmichett_FedoraRemix (None) <tmichett#FedoraRemix@copr.fedorahosted.org> public key
gpg-pubkey-fa32fc04c04fd33ae5924f4cbc2926706c3c5e76-67e6bfd5 lihaohong_yazi (None) <lihaohong#yazi@copr.fedorahosted.org> public key
```

`rpmkeys --root /tmp/ir -K` then printed `digests signatures OK` for `libgcc`, both RPM Fusion release RPMs, Chrome, VS Code, `yazi`, `fedora_remix_tools`, `dyff`, and `LogViewer`.

## What changed

The container image was left as published. The remix repo patches `dnfinst.py` in the running container, the same way it already patches `fs.py` and `kickstart.py`.

| File | Change |
| --- | --- |
| `Setup/files/Fixes/import_installroot_keys.py` | New. `--stage <version>` downloads third-party keys into `/usr/share/pki/rpm-gpg-remix`. `import_installroot_keys(installroot, releasever)` runs `rpm --root … --initdb` and `rpm --import` for the Fedora release keys plus that directory. |
| `Setup/Enhanced_Remix_Build_Script.sh` | Copies the helper into the `imgcreate` package and inserts the call immediately before `do_transaction`. Stages keys before `livecd-creator`. |
| `Setup/Prepare_Web_Files.py` | Copies the helper to the web root with the other imgcreate patches. |

Hook inserted into the image's `dnfinst.py` at runtime:

```python
# FIXME: sigcheck?
# Fedora 45 enforces signatures. Import keys into the empty install root first.
from imgcreate.import_installroot_keys import import_installroot_keys
import_installroot_keys(self.conf.installroot, self.releasever)

ret = self.do_transaction(TransactionProgress())
```

The successful build log line:

```text
Importing 8 OpenPGP keys into /var/tmp/imgcreate-iyvtwufi/install_root (Fedora 45)
```

Eight files, because the Fedora arch key and the Fedora primary key are the same inode and are imported once.

## Build that confirmed it

```bash
cd ~/Github/Fedora_Remix
REMIX_INCLUDE_PXEBOOT=false ./Build_Remix.sh -k FedoraRemix
```

```text
Kickstart: FedoraRemix.ks
Container: ghcr.io/tmichett/fedora-remix-builder:45
PXEBoot:   false
ISO:       /home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso
```

```text
Live CD created successfully!
Total Build Time:          16m 5s (965 seconds)
Package Installation:      6m 49s (409 seconds)
ISO File Creation:         9m 16s (556 seconds)
Generated: FedoraRemix.iso (8.4G)
```

```text
ISO 9660 CD-ROM filesystem data (DOS/MBR boot sector) 'FedoraRemix' (bootable)
```

Success log: `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix-Build-110526-1703.log`.

## Left as warnings

`%post` still prints two warnings. They did not fail this ISO.

- `plymouth-set-default-theme tm-fedora-remix` reports `/usr/lib64/plymouth/two-step.so does not exist`.
- `FedoraRemix.ks` writes `/usr/lib/dracut/modules.d/99local-url-handler/module-setup.sh` before `mkdir` of that directory, so that file is missing. `uname -r` inside the script is the host kernel (`7.2.5-200.fc44`), so the script takes the `dracut --regenerate-all` branch.

## Rebuild rule

A new third-party repo in `Setup/Kickstarts/FedoraRemixRepos.ks` needs its public key added to `DIRECT_KEYS` in `import_installroot_keys.py`, or the next Fedora 45 build fails the same way on that one key id. The container image does not need a rebuild for this fix.
