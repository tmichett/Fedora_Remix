# Changelog - Fedora Remix Builder

All notable changes to the Fedora Remix Builder project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Fixed
- **2026-11-05**: Fedora 45 `livecd-creator` transaction failed with `NOKEY` (key id `655a4b02f577861e` and the third-party repo keys)
  - Cause: rpm `%_pkgverify_level all` checks the empty install root; `imgcreate/dnfinst.py` never imports repo keys
  - Fix: `Setup/files/Fixes/import_installroot_keys.py`, hooked from `Setup/Enhanced_Remix_Build_Script.sh` before `do_transaction`
  - RPM Fusion keys are extracted from the release RPM; the standalone key URLs 404
  - Container image was not rebuilt
  - Write-up: [Notes/Fedora45_GPG_Key_Import.md](Notes/Fedora45_GPG_Key_Import.md)
  - Result: `FedoraRemix.iso` 8.4 GB in 16m 5s

- **2026-02-22**: SELinux permission denied error on `/tmp/remix_kickstart.txt`
  - Removed temp file bind mount that caused SELinux conflicts
  - Container now creates kickstart file in its own tmpfs
  - Relies on `REMIX_KICKSTART` environment variable as primary method
  - Files changed: `Build_Remix.sh` (lines 261-279)
  - Issue: Container failed to start on systems with SELinux enforcing
  - Result: Builds now start successfully on all Linux systems

### Changed
- **2026-02-22**: Simplified container volume mounts in `Build_Remix.sh`
  - Removed temporary file creation for kickstart selection
  - Streamlined podman run command
  - Improved SELinux compatibility

---

## [2025-11-22] - Linux Compatibility Fix

### Fixed
- **2025-11-22**: systemd `/sys` filesystem unmount errors during ISO build
  - Patched `imgcreate/fs.py` to handle `/sys` unmount failures gracefully
  - Added dynamic Python version detection for patch installation
  - Implemented automatic patch verification before build starts
  - Files changed: `Setup/Prepare_Fedora_Remix_Build.py`, `Setup/Enhanced_Remix_Build_Script.sh`
  - Issue: ISO builds failed on Linux after 15+ minutes at cleanup phase
  - Result: Builds complete successfully in ~30 minutes, producing 7.9GB ISOs

### Added
- **2025-11-22**: Comprehensive documentation in `LINUX_BUILD_FIX.md`
  - Detailed root cause analysis
  - Step-by-step debugging journey
  - Testing and verification procedures
  - Troubleshooting guide

---

## [2025-11-22] - Kickstart Selection Feature

### Added
- **2025-11-22**: Interactive kickstart selection menu in `Build_Remix.sh`
  - Color-coded menu for selecting Remix variants
  - Command-line options: `-k`, `-l`, `-h`
  - Support for multiple kickstart variants (FedoraRemix, FedoraRemixCosmic, etc.)
  - Automatic filtering of package/repo snippet files
  - Output ISO named after selected kickstart

### Changed
- **2025-11-22**: Enhanced `Build_Remix.sh` with better user experience
  - Beautiful formatted menu using box-drawing characters
  - Default selection support (press Enter for FedoraRemix)
  - Improved configuration display before build
  - Better error messages and validation

---

## Earlier Versions

See git history for changes prior to November 2025.
