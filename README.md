# Fedora Remix

A customized Fedora Linux live ISO with pre-configured packages, themes, and utilities.

> **Latest Updates:** See [CHANGELOG.md](CHANGELOG.md) for recent fixes and improvements.  
> **Linux Compatibility:** See [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) for known issues and solutions.

## Quick Start

### Prerequisites
- Podman installed on your system
- Fedora Remix Builder container (see [RemixBuilder](https://github.com/tmichett/RemixBuilder))
- At least 10GB free disk space
- SSH key for GitHub access (optional)

### Building the ISO

1. **Configure the build**:
   ```bash
   # Edit config.yml with your settings
   vim config.yml
   ```

2. **Run the build**:
   ```bash
   # Interactive mode - choose from available kickstarts
   ./Build_Remix.sh
   
   # Or specify directly
   ./Build_Remix.sh -k FedoraRemix        # GNOME desktop (default)
   ./Build_Remix.sh -k FedoraRemixCosmic  # COSMIC desktop
   
   # List available kickstarts
   ./Build_Remix.sh -l
   ```

3. **Find your ISO**:
   - Location: `{Fedora_Remix_Location}/FedoraRemix/{KickstartName}.iso`
   - Examples:
     - `FedoraRemix.iso` (GNOME desktop)
     - `FedoraRemixCosmic.iso` (COSMIC desktop)
   - Size: ~7-8 GB
   - Build time: ~30 minutes

### Linux Build Fix (November 2025)

If you're building on Linux and encounter `/sys` unmount errors, the issue has been resolved! See **[LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md)** for complete details.

**Quick summary of the fix**:
- ✅ Patched imgcreate library to handle systemd-managed filesystems
- ✅ Dynamic Python version detection
- ✅ Automatic verification of patches
- ✅ Builds now complete successfully on Linux

## Documentation

- **[LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md)** - Detailed fix for Linux build issues
- **[README_Scripts_Usage.md](README_Scripts_Usage.md)** - Complete script documentation
- **[README.adoc](README.adoc)** - Extended documentation

## Project Structure

```
Fedora_Remix/
├── Build_Remix.sh              # Main build script (runs container, kickstart selection)
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
