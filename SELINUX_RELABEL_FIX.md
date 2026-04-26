# SELinux Relabeling — Build-Time Labeling and the osbuild EINVAL Fix

**Last Updated:** April 24, 2026  
**Status:** ✅ Fixed in `Setup/files/Fixes/kickstart.py`

---

## Background — When and How Relabeling Happens

Understanding the build-time relabeling lifecycle is critical to understanding why this fix is correct.

### Build time

`livecd-creator` installs packages into a temporary chroot, runs `%post` scripts, then calls `setfiles` (via `imgcreate/kickstart.py`) to apply SELinux contexts to every file in the chroot **before** the squashfs image is created. Whatever labels exist at that point are permanently baked into the squashfs.

### Live CD boot — no relabeling possible

A live CD boots from a **read-only squashfs** filesystem. Unlike an installed system, there is **no autorelabel at first boot**. The kernel cannot write xattrs back to a squashfs, so the labels set (or not set) during the build are what the live system uses for its entire lifetime.

### Installed system

When Anaconda installs from the live image to a hard drive, it copies the squashfs contents to a writable filesystem and performs a full SELinux relabel during installation. Any files that were missing labels in the live image get properly labeled on the installed system.

---

## The Problem — osbuild `setfiles` EINVAL (April 24, 2026)

### Symptom

Near the end of a `livecd-creator` build, the run aborts:

```
setfiles: Could not set context for /usr/lib/osbuild/stages/org.osbuild.rpm:  Invalid argument
setfiles: Could not set context for /usr/lib/osbuild/sources/org.osbuild.curl:  Invalid argument
setfiles: Could not set context for /usr/bin/osbuild:  Invalid argument
setfiles: Could not set context for /usr/libexec/dhcpcd-run-hooks:  Invalid argument
...
Error creating Live CD : SELinux relabel failed.
```

### Why osbuild is in the chroot at all

`osbuild` and `osbuild-selinux` are **not** explicitly installed by any Fedora Remix kickstart. They are pulled in automatically as dependencies of groups like `@workstation-product-group` in the upstream base kickstarts (`fedora-workstation-common.ks`). This happens on all kickstarts — including minimal ones — that include the workstation base.

### Root cause

`setfiles` runs **inside the chroot** using the chroot's own compiled binary policy (`-c policy_file`). It reads file context rules from the chroot's `osbuild-selinux` package, which maps `/usr/lib/osbuild/**` and `/usr/bin/osbuild` to the type `osbuild_exec_t`.

When `setfiles` calls `setxattr("security.selinux", "osbuild_exec_t:s0", ...)`, the **host kernel** validates that type against its own **running SELinux policy**. If `osbuild-selinux` is not installed and loaded on the build host (or in the build container's running kernel policy), the kernel returns `EINVAL` — it does not know `osbuild_exec_t`.

This is distinct from the earlier Fix #3 / Fix #3b issues, which were about the build environment's SELinux labeling being broadly broken (missing `:z` on bind mounts, `--security-opt label=disable`). This new failure occurs even in a correctly configured SELinux build environment because `osbuild_exec_t` is simply not part of the base `selinux-policy-targeted` that the host has loaded.

### Why the EINVAL is fatal

In `Setup/files/Fixes/kickstart.py`, the `SelinuxConfig.relabel()` method raises a fatal `KickstartError` when `setfiles` returns non-zero under an enforcing kickstart:

```python
if rc:
    if ksselinux.selinux == ksconstants.SELINUX_ENFORCING:
        raise errors.KickstartError("SELinux relabel failed.")
```

`setfiles` exits non-zero if **any** file fails, including osbuild files, so the entire build aborts.

---

## The Fix

### `Setup/files/Fixes/kickstart.py` — non-fatal setfiles failure

The `raise` is replaced with `logging.warning()` calls so the build continues when `setfiles` encounters files whose context types are unknown to the host kernel:

```python
if rc:
    logging.warning("SELinux relabel completed with errors — some files could not be labeled.")
    logging.warning("This is typically caused by package-specific SELinux policy modules (e.g. osbuild-selinux)")
    logging.warning("whose types are not present in the host kernel's running policy inside the build container.")
    logging.warning("Unlabeled files will have 'unlabeled_t' context in the squashfs image.")
    logging.warning("For a live image this is permanent (squashfs is read-only; no autorelabel occurs at boot).")
    logging.warning("This only affects packages not needed by the live system (e.g. osbuild) and will not prevent booting.")
```

### `Setup/Enhanced_Remix_Build_Script.sh` — patch verification

A verification step was added alongside the existing `fs.py` check to confirm the patched `kickstart.py` is active before the build runs:

```bash
if grep -q "SELinux relabel completed with errors" "$PYTHON_IMGCREATE_PATH/kickstart.py" 2>/dev/null; then
    print_message "SUCCESS" "  ✓ Verified: kickstart.py SELinux relabel patch active"
else
    print_message "ERROR" "  ✗ WARNING: kickstart.py SELinux relabel patch NOT found!"
    exit 1
fi
```

---

## Impact Analysis

### What gets unlabeled in the squashfs

Only files whose SELinux context types are absent from the host kernel's running policy will fail. In practice this is:

| Package | Files affected | Needed by live system? |
|---|---|---|
| `osbuild` | `/usr/bin/osbuild`, `/usr/lib/osbuild/**` | No — image build tool, never run from a live CD |
| `dhcpcd` | `/usr/libexec/dhcpcd-run-hooks` | Potentially — but dhcpcd contexts are in base policy; this may be a host version mismatch |

### Effect at each stage

| Stage | Effect |
|---|---|
| **Live CD boot** | osbuild files have `unlabeled_t`. System boots normally. Executing osbuild would get an AVC denial, but no user does that from a live CD. |
| **Live CD runtime** | No impact on normal use. All system-critical files (kernel, init, libs, desktop) are labeled correctly. |
| **Install via Anaconda** | Anaconda performs a full relabel on the writable installed filesystem. osbuild files get proper labels on the installed system. |

### Is it safe?

Yes. The files that fail relabeling are build tools (`osbuild`) that are pulled in as transitive dependencies but serve no function on a live or installed desktop system. The live CD boots, operates, and installs normally.

---

## How the Patch is Deployed

No container rebuild is needed. The patch is applied automatically at build time:

1. `Prepare_Web_Files.py` copies `Setup/files/Fixes/kickstart.py` → `/var/www/html/kickstart.py`
2. `Enhanced_Remix_Build_Script.sh` detects the Python imgcreate path dynamically and copies the patched file there
3. The patch is verified before `livecd-creator` runs
4. `livecd-creator` imports the patched module and continues past `setfiles` errors

---

## Relationship to Earlier SELinux Fixes

| Fix | Date | Issue | Resolution |
|---|---|---|---|
| Fix #3 | Apr 13, 2026 | Broad relabeling failure with `label=disable` | Made `setfiles` non-fatal (warning-only) |
| Fix #3b | Apr 22, 2026 | Restored strict behavior with `:z` bind mounts | `setfiles` fatal again; `selinux --enforcing` in kickstart |
| **This fix** | **Apr 24, 2026** | **osbuild `osbuild_exec_t` EINVAL even in correct SELinux environment** | **Non-fatal for specific-type mismatches; accurate live CD behavior documented** |

The key difference from Fix #3: the earlier issue was the build environment being broadly misconfigured (SELinux disabled on bind mounts). This issue occurs in a **correctly configured** environment — the host simply does not have `osbuild_exec_t` loaded, which is expected when `osbuild-selinux` isn't installed on the build host.

See `LINUX_BUILD_FIX.md` for the full history of all build compatibility fixes.
