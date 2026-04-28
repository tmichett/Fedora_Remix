# Fedora Remix

A customized Fedora Linux live ISO with pre-configured packages, themes, and utilities.

> **Latest Updates:** See [CHANGELOG.md](CHANGELOG.md) for recent fixes and improvements.  
> **Linux Compatibility:** See [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) for known issues and solutions.

## Quick Start

> **📚 New to building Fedora Remix?** See **[Quickstart_Container.md](Quickstart_Container.md)** for a complete step-by-step guide from repository clone to ISO creation.

### Prerequisites
- Podman installed on your system
- Fedora Remix Builder container (see [RemixBuilder](https://github.com/tmichett/RemixBuilder))
- At least 20GB free disk space
- SSH key for GitHub access (optional)

### Configuration (before your first build)

From the **repository root**, align the container tag and remix web settings in one step (recommended instead of hand-editing YAML):

```bash
chmod +x Update_Remix_Config.sh   # once
./Update_Remix_Config.sh
```

This interactively sets **`SSH_Key_Location`**, **`Fedora_Remix_Location`**, **`GitHub_Registry_Owner`**, **`Fedora_Version`** (root `config.yml`), plus **`fedora_version`** and **`include_pxeboot_files`** (`Setup/config.yml`). PXE boot artifacts are optional; answer **no** if you only need an ISO ([Quickstart_Container.md](Quickstart_Container.md) explains when PXE can fail on old or very new Fedora versions). If you pull the **published** image from **`ghcr.io/tmichett/fedora-remix-builder`**, keep **`GitHub_Registry_Owner`** as **`tmichett`**. You can still edit **`config.yml`** by hand first so the script’s defaults match your host (Enter at each prompt keeps the shown value).

### Building the ISO (Containerized Method - Recommended)

1. **Verify and configure** (Recommended):
   ```bash
   # Run verification script - checks configuration and starts build
   ./Verify_Build_Remix.sh
   ```
   
   The verification script will:
   - ✅ Check Fedora versions match between config files
   - ✅ Verify container image availability
   - ✅ Optionally confirm **PXE/web boot file** preference (`include_pxeboot_files`) if unset
   - ✅ Display configuration summary
   - ✅ Confirm before building
   - ✅ Automatically launch the build if approved

2. **Or configure and build manually**:
   ```bash
   ./Update_Remix_Config.sh           # preferred: paths, registry owner, Fedora + PXE in sync
   # optional: vim config.yml first so script defaults match your machine
   
   # Run the build
   ./Build_Remix.sh
   ```

3. **Build specific variants**:
   ```bash
   # Interactive mode - choose from available kickstarts
   ./Build_Remix.sh
   
   # Or specify directly
   ./Build_Remix.sh -k FedoraRemix        # GNOME desktop (default)
   ./Build_Remix.sh -k FedoraRemixCosmic  # COSMIC desktop
   
   # List available kickstarts
   ./Build_Remix.sh -l
   ```

4. **Find your ISO**:
   - Location: `{Fedora_Remix_Location}/FedoraRemix/{KickstartName}.iso`
   - Examples:
     - `FedoraRemix.iso` (GNOME desktop)
     - `FedoraRemixCosmic.iso` (COSMIC desktop)
   - Size: ~7-8 GB
   - Build time: ~30-45 minutes

### Linux Build Fix (November 2025)

If you're building on Linux and encounter `/sys` unmount errors, the issue has been resolved! See **[LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md)** for complete details.

**Quick summary of the fix**:
- ✅ Patched imgcreate library to handle systemd-managed filesystems
- ✅ Dynamic Python version detection
- ✅ Automatic verification of patches
- ✅ Builds now complete successfully on Linux

## Documentation

### Getting Started
- **[Quickstart_Container.md](Quickstart_Container.md)** - 🚀 Complete quickstart guide for containerized builds
- **[Quickstart_Physical.md](Quickstart_Physical.md)** - Native (physical/VM) build with `Build_Remix_Physical.sh`
- **[VERIFY_BUILD_REMIX_USAGE.md](VERIFY_BUILD_REMIX_USAGE.md)** — `Verify_Build_Remix.sh` walkthrough
- **[Notes/Fedora_Remix_Quickstart.md](Notes/Fedora_Remix_Quickstart.md)** - Long-form notes (RemixBuilder + kickstarts)

### Build Methods
- **Containerized (Recommended)** - Use `./Verify_Build_Remix.sh` or `./Build_Remix.sh`
- **Physical/Virtual** - See **[README_Physical.adoc](README_Physical.adoc)** for building on physical or virtual machines without containers

### Troubleshooting & Fixes
- **[LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md)** - Detailed fixes for Linux build issues (3 major fixes)
- **[SELINUX_RELABEL_FIX.md](SELINUX_RELABEL_FIX.md)** - SELinux relabeling error fix (April 2026)

### Reference
- **[README_Scripts_Usage.md](README_Scripts_Usage.md)** - Prepare scripts, web setup, Python workflow
- **[docs/README.adoc](docs/README.adoc)** - Short AsciiDoc readme (docs folder)

## Project Structure

```
Fedora_Remix/
├── Build_Remix.sh              # Main build script (runs container, kickstart selection)
├── Update_Remix_Config.sh      # Interactive: SSH path, remix dir, registry owner, Fedora + PXE (config.yml + Setup/config.yml)
├── config.yml                  # Build configuration
├── Setup/                      # Build preparation scripts
│   ├── Enhanced_Remix_Build_Script.sh
│   ├── Prepare_Web_Files.py
│   ├── Prepare_Fedora_Remix_Build.py
│   ├── Kickstarts/            # Kickstart files for customization
│   │   ├── FedoraRemix.ks             # GNOME variant (default)
│   │   ├── FedoraRemixCosmic.ks       # COSMIC variant
│   │   ├── FedoraRemixPackages.ks     # GNOME packages
│   │   ├── FedoraRemixCosmicPackages.ks  # COSMIC packages
│   │   └── KickstartSnippets/         # Modular snippets
│   │       ├── customize-gnome-wallpaper.ks
│   │       ├── customize-cosmic-wallpaper.ks
│   │       └── ...
│   └── files/
│       └── Fixes/             # Python patches for livecd-tools
│           ├── fs.py          # Systemd /sys unmount fix
│           └── kickstart.py   # Kickstart compatibility fix
└── Files/                     # Customization files (themes, configs)
```

## Available Remix Variants

| Variant | Kickstart | Desktop | Description |
|---------|-----------|---------|-------------|
| **FedoraRemix** | `FedoraRemix.ks` | GNOME | Default variant with GNOME desktop, extensions, and full customization |
| **FedoraRemixCosmic** | `FedoraRemixCosmic.ks` | COSMIC | System76's COSMIC desktop environment (Fedora 43+) |

### COSMIC Desktop Spin (New!)

The COSMIC desktop spin provides System76's new Rust-based desktop environment:
- Modern, tiling-capable compositor
- Native Wayland support
- Custom theming with Fedora Remix wallpapers
- `greetd` display manager with auto-login support

```bash
# Build the COSMIC variant
./Build_Remix.sh -k FedoraRemixCosmic
```

## Customization

Edit these files to customize your Fedora Remix:

### GNOME Variant
- **`Setup/Kickstarts/FedoraRemix.ks`** - Main kickstart configuration
- **`Setup/Kickstarts/FedoraRemixPackages.ks`** - Package selection
- **`Setup/Kickstarts/FedoraRemixRepos.ks`** - Repository configuration

### COSMIC Variant
- **`Setup/Kickstarts/FedoraRemixCosmic.ks`** - Main COSMIC kickstart
- **`Setup/Kickstarts/FedoraRemixCosmicPackages.ks`** - COSMIC package selection
- **`Setup/Kickstarts/KickstartSnippets/customize-cosmic-wallpaper.ks`** - COSMIC wallpapers

### Shared
- **`Files/`** - Custom files, themes, and configurations

## Troubleshooting

### Build fails with unmount errors
See [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) - Python version detection fix required

### Container won't start
```bash
# Check if container is stuck
sudo podman ps -a | grep remix-builder

# Force cleanup
sudo podman kill remix-builder && sudo podman rm -f remix-builder
```

### Build succeeds but ISO is corrupt
- Check available disk space (need 10GB+)
- Review build log in `/home/travis/Remix_Builder/FedoraRemix/FedoraBuild-*.log`

## Contributing

Contributions welcome! Please ensure:
- Scripts are tested on both Linux and macOS
- Documentation is updated for any changes
- Kickstart files maintain Fedora compatibility

## License

See individual license files within the project.
