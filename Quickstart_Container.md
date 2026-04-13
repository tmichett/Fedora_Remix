# Fedora Remix Builder - Container Quickstart Guide

**Last Updated:** April 13, 2026  
**Purpose:** Quick guide to building a custom Fedora Remix ISO using the containerized build system

---

## Overview

This guide will walk you through building a custom Fedora Remix ISO image using the Fedora Remix Builder container. The entire build process runs in a container, making it consistent across different systems.

**Build Time:** Approximately 30-45 minutes  
**Output:** A bootable Fedora Remix ISO file (~7-8 GB)

---

## Prerequisites

### Required Software

Before starting, ensure your system has:

1. **Git** - For cloning the repository
   ```bash
   # Fedora/RHEL
   sudo dnf install git
   
   # Ubuntu/Debian
   sudo apt install git
   ```

2. **Podman** - Container runtime (recommended) or Docker
   ```bash
   # Fedora/RHEL
   sudo dnf install podman
   
   # Ubuntu/Debian
   sudo apt install podman
   ```

3. **Sudo Access** - Required for loop device creation on Linux
   - The build script will automatically use `sudo` when needed

### System Requirements

- **Disk Space:** At least 20 GB free (for packages, cache, and ISO)
- **Memory:** 4 GB minimum, 8 GB recommended
- **CPU:** Multi-core processor recommended (build is CPU-intensive)
- **Internet:** Required for downloading packages and container image

### Supported Operating Systems

- ✅ Fedora Linux (39, 40, 41, 42, 43)
- ✅ RHEL/CentOS/Rocky/Alma Linux (8, 9)
- ✅ Ubuntu/Debian (with Podman installed)
- ✅ macOS (with Podman Desktop)

---

## Quick Start (5 Steps)

### Step 1: Clone the Repository

```bash
# Clone the Fedora Remix repository
git clone https://github.com/tmichett/Fedora_Remix.git

# Navigate to the project directory
cd Fedora_Remix
```

### Step 2: Configure Container Properties

Edit the main configuration file to set up the build environment:

```bash
vim config.yml
```

**Required Settings:**

```yaml
Container_Properties:
  Fedora_Version: "43"                              # Fedora version for container
  SSH_Key_Location: "~/.ssh/github_id"              # Your SSH key location
  Fedora_Remix_Location: "/home/travis/Remix_Builder"  # Output directory
  GitHub_Registry_Owner: "tmichett"                 # Container registry owner
```

**Key Configuration Options:**

- **`Fedora_Version`**: Must match the Fedora version you want to build (e.g., "43")
- **`SSH_Key_Location`**: Path to your SSH key (used for git operations in container)
- **`Fedora_Remix_Location`**: Where the ISO and build artifacts will be saved
- **`GitHub_Registry_Owner`**: GitHub username/org that hosts the container image

**Example Configuration:**

```yaml
Container_Properties:
  Fedora_Version: "43"
  SSH_Key_Location: "~/.ssh/id_rsa"
  Fedora_Remix_Location: "/home/myuser/FedoraBuilds"
  GitHub_Registry_Owner: "tmichett"
```

### Step 3: Configure Remix Build Settings

Edit the Setup configuration file:

```bash
vim Setup/config.yml
```

**Required Settings:**

```yaml
# Fedora version to use for downloading boot files
fedora_version: 43    # MUST match Fedora_Version in config.yml

# Web root directory where files will be served
web_root: "/var/www/html"
```

**⚠️ CRITICAL:** The `fedora_version` here **MUST match** the `Fedora_Version` in the main `config.yml` file!

**Example:**
```yaml
fedora_version: 43
web_root: "/var/www/html"
```

### Step 4: Verify Configuration (Recommended)

Run the verification script to check your configuration:

```bash
./Verify_Build_Remix.sh
```

**What it checks:**
- ✅ Fedora versions match between both config files
- ✅ Container image availability
- ✅ Configuration summary
- ✅ Confirms before building

**Sample Output:**
```
╔══════════════════════════════════════════════════════════════════════╗
║ Configuration Summary                                                ║
╠══════════════════════════════════════════════════════════════════════╣
║  Container Configuration (config.yml)                              ║
║    Fedora Version: 43                                            ║
║  Remix Configuration (Setup/config.yml)                            ║
║    Fedora Version: 43                                            ║
╚══════════════════════════════════════════════════════════════════════╝

✅ Versions match! Container and Remix both use Fedora 43

Do you want to proceed with the build? [y/N]: y
```

### Step 5: Build the ISO

If you used the verification script and confirmed, the build starts automatically.

Otherwise, run the build script directly:

```bash
./Build_Remix.sh
```

**Build Process:**
1. Container starts with systemd
2. Prepares build environment
3. Downloads and installs packages (~15-20 minutes)
4. Runs post-installation scripts
5. Creates the ISO image (~5-10 minutes)
6. ISO saved to your configured output directory

**Expected Output Location:**
```
/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso
```

---

## Optional Customization

### Customizing Packages

To add or remove RPM packages from your remix:

**Edit the package list:**
```bash
vim Setup/Kickstarts/FedoraRemixPackages.ks
```

**Add packages:**
```bash
# Add your packages here
vim
tmux
htop
```

**Remove packages:**
```bash
# Comment out or delete unwanted packages
# firefox  # Removed
```

**Package Categories:**
- Base system packages
- Desktop environment packages
- Development tools
- Multimedia applications
- Custom applications

### Customizing Kickstart Files

For advanced customization of the installation and system configuration:

**Main Kickstart Files:**
```bash
Setup/Kickstarts/
├── FedoraRemix.ks              # Main kickstart (default)
├── FedoraRemixCosmic.ks        # COSMIC desktop variant
├── FedoraRemixKDE.ks           # KDE Plasma variant
├── FedoraRemixLab.ks           # Lab/Development variant
├── FedoraRemixPackages.ks      # Package list (edit this for packages)
└── FedoraRemixRepos.ks         # Repository configuration
```

**Kickstart Snippets:**
```bash
Setup/Kickstarts/KickstartSnippets/
├── create-ansible-user.ks      # Create ansible user
└── customize-anaconda.ks       # Anaconda installer customization
```

**What you can customize:**
- System packages and package groups
- User accounts and passwords
- Network configuration
- Firewall rules
- SELinux settings
- Post-installation scripts
- Boot loader configuration
- Partition layout
- Repository sources

**Example: Adding a Custom User**

Create a new snippet in `Setup/Kickstarts/KickstartSnippets/`:

```bash
vim Setup/Kickstarts/KickstartSnippets/create-myuser.ks
```

```bash
# Create custom user
user --name=myuser --groups=wheel --password=encrypted_password --iscrypted
```

Then include it in your main kickstart:

```bash
vim Setup/Kickstarts/FedoraRemix.ks
```

```bash
%include Setup/Kickstarts/KickstartSnippets/create-myuser.ks
```

### Customizing Look and Feel

**Branding and Themes:**
```bash
Setup/files/
├── boot/                       # Boot splash screens
│   ├── splash.png             # Boot menu background
│   └── anaconda_header.png    # Installer header
├── FedoraRemixOrange.png      # Desktop wallpaper
└── Cursor.desktop             # Desktop shortcuts
```

**GRUB Theme:**
```bash
Grub_Theme/Fedora_Remix_Theme/
├── FedoraRemix.jpeg           # GRUB background options
├── FedoraRemix2.jpeg
└── ...
```

**To customize:**
1. Replace image files with your own (keep same dimensions)
2. Update references in kickstart files if needed
3. Rebuild the ISO

---

## Building Different Variants

The project includes several pre-configured variants:

### Default Fedora Remix (GNOME)
```bash
./Verify_Build_Remix.sh
# Select: 1) FedoraRemix
```

### COSMIC Desktop Variant
```bash
./Build_Remix.sh --kickstart FedoraRemixCosmic
```

### KDE Plasma Variant
```bash
./Build_Remix.sh --kickstart FedoraRemixKDE
```

### Lab/Development Variant
```bash
./Build_Remix.sh --kickstart FedoraRemixLab
```

**Each variant includes:**
- Different desktop environment
- Variant-specific packages
- Customized configurations
- Optimized for different use cases

---

## Configuration File Reference

### Main Configuration (`config.yml`)

**Location:** `/home/travis/Github/Fedora_Remix/config.yml`

**Purpose:** Controls the container build environment

**Full Example:**
```yaml
Container_Properties:
  # Fedora version for the container (must match Setup/config.yml)
  Fedora_Version: "43"
  
  # SSH key for git operations (optional but recommended)
  SSH_Key_Location: "~/.ssh/github_id"
  
  # Output directory for ISO and build artifacts
  Fedora_Remix_Location: "/home/travis/Remix_Builder"
  
  # GitHub Container Registry owner (for pulling container image)
  GitHub_Registry_Owner: "tmichett"
  
  # Note: Image_Name is auto-generated as:
  # ghcr.io/{GitHub_Registry_Owner}/fedora-remix-builder:{Fedora_Version}
```

### Setup Configuration (`Setup/config.yml`)

**Location:** `/home/travis/Github/Fedora_Remix/Setup/config.yml`

**Purpose:** Controls the remix build process

**Full Example:**
```yaml
# Configuration file for Prepare_Web_Files.py

# Fedora boot files to download for PXE boot
fedora_boot_files:
  - "vmlinuz"
  - "initrd.img"

# Fedora version to use for downloading boot files
# MUST match Fedora_Version in main config.yml
fedora_version: 43

# Web root directory where files will be served
web_root: "/var/www/html"
```

---

## Troubleshooting

### Version Mismatch Error

**Problem:**
```
⚠️ Version mismatch detected!
  Container is configured for Fedora 43
  Remix is configured for Fedora 42
```

**Solution:**
Update both config files to use the same version:
```bash
# Edit main config
vim config.yml
# Set: Fedora_Version: "43"

# Edit setup config
vim Setup/config.yml
# Set: fedora_version: 43
```

### Container Image Not Found

**Problem:**
```
⚠️ Container image not found locally
```

**Solution 1:** Let it pull automatically (slower)
- The image will be pulled from GitHub Container Registry
- Takes 5-15 minutes depending on connection

**Solution 2:** Build container locally (faster for repeated builds)
```bash
cd /home/travis/Github/RemixBuilder
./build.sh
```

### SELinux Relabeling Errors

**Problem:**
```
setfiles: Could not set context for /usr/share/accountsservice: Invalid argument
Error creating Live CD : SELinux relabel failed.
```

**Solution:**
This is fixed in the latest version. Ensure you have the patched `kickstart.py`:
```bash
ls -lh Setup/files/Fixes/kickstart.py
```

If missing, pull the latest changes:
```bash
git pull origin main
```

See `SELINUX_RELABEL_FIX.md` for details.

### Build Fails After 15 Minutes

**Problem:**
```
Error creating Live CD : Unable to unmount filesystem at /var/tmp/imgcreate-*/install_root/sys
```

**Solution:**
This is fixed in the latest version. Ensure you have the patched `fs.py`:
```bash
ls -lh Setup/files/Fixes/fs.py
```

See `LINUX_BUILD_FIX.md` for details.

### Insufficient Disk Space

**Problem:**
```
Error: Not enough free space
```

**Solution:**
- Ensure at least 20 GB free space
- Clean up old builds:
  ```bash
  rm -rf /home/travis/Remix_Builder/FedoraRemix/*.iso
  rm -rf /livecd-creator/package-cache/*
  ```

---

## Build Output

### Successful Build

**Expected output:**
```
✅ 🚀 Live CD created successfully!
  🕐 Total Build Time:          30m 46s (1846 seconds)
  📦 Package Installation:     15m 42s (942 seconds)
  🚀 ISO File Creation:        15m 4s (904 seconds)
✅ 📦 Generated: FedoraRemix.iso (7.9G)

╔══════════════════════════════════════════════════════════════════════════════╗
║ BUILD COMPLETED SUCCESSFULLY!                                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Output Files

**ISO Image:**
```
/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso
```

**Build Log:**
```
/home/travis/Remix_Builder/FedoraRemix/FedoraRemix-Build-MMDDYY-HHMM.log
```

**Package Cache:**
```
/livecd-creator/package-cache/
```

---

## Next Steps

### Testing Your ISO

1. **Verify the ISO:**
   ```bash
   ls -lh /home/travis/Remix_Builder/FedoraRemix/*.iso
   ```

2. **Test in a VM:**
   - Use GNOME Boxes, VirtualBox, or virt-manager
   - Boot from the ISO
   - Test Live environment
   - Test installation

3. **Create Bootable USB:**
   ```bash
   sudo dd if=/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso \
           of=/dev/sdX bs=4M status=progress
   ```
   Replace `/dev/sdX` with your USB device.

### Distributing Your ISO

**Options:**
- Upload to file sharing service
- Host on web server
- Distribute via USB drives
- Create torrent for large-scale distribution

---

## Advanced Topics

### Building for Different Fedora Versions

To build for a different Fedora version:

1. Update both config files:
   ```bash
   # config.yml
   Fedora_Version: "44"
   
   # Setup/config.yml
   fedora_version: 44
   ```

2. Verify the container image exists:
   ```bash
   podman pull ghcr.io/tmichett/fedora-remix-builder:44
   ```

3. Build as normal

### Automating Builds

Create a build script:

```bash
#!/bin/bash
# automated-build.sh

cd /home/travis/Github/Fedora_Remix

# Update to latest code
git pull

# Run build with auto-confirmation
echo "y" | ./Verify_Build_Remix.sh

# Copy ISO to distribution directory
cp /home/travis/Remix_Builder/FedoraRemix/*.iso /var/www/html/isos/
```

### Building Multiple Variants

```bash
#!/bin/bash
# build-all-variants.sh

for variant in FedoraRemix FedoraRemixCosmic FedoraRemixKDE; do
    echo "Building $variant..."
    ./Build_Remix.sh --kickstart $variant
done
```

---

## Additional Resources

### Documentation

- **Main README:** `README.md` - Project overview
- **Build Fixes:** `LINUX_BUILD_FIX.md` - Known issues and solutions
- **SELinux Fix:** `SELINUX_RELABEL_FIX.md` - SELinux relabeling fix details
- **Verification Script:** `VERIFY_BUILD_REMIX_USAGE.md` - Verification tool guide
- **Container Build:** `/home/travis/Github/RemixBuilder/README.md` - Container documentation

### Repository Links

- **Fedora Remix:** https://github.com/tmichett/Fedora_Remix
- **Remix Builder Container:** https://github.com/tmichett/RemixBuilder
- **Container Registry:** https://ghcr.io/tmichett/fedora-remix-builder

### Getting Help

1. Check the documentation files
2. Review build logs for errors
3. Check GitHub Issues
4. Consult Fedora documentation for kickstart syntax

---

## Summary

**Minimum Steps to Build:**

1. Clone repository: `git clone https://github.com/tmichett/Fedora_Remix.git`
2. Edit `config.yml` - Set container properties
3. Edit `Setup/config.yml` - Set remix version (must match!)
4. Run `./Verify_Build_Remix.sh` - Verify and build
5. Wait 30-45 minutes
6. Find ISO at `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso`

**Optional Customization:**

- Edit `Setup/Kickstarts/FedoraRemixPackages.ks` - Add/remove packages
- Edit kickstart files in `Setup/Kickstarts/` - Advanced customization
- Replace branding files in `Setup/files/` - Custom look and feel

**That's it!** You now have a custom Fedora Remix ISO ready to use.

---

**Last Updated:** April 13, 2026  
**Version:** 1.0