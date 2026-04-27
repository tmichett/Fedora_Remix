# Fedora Remix Builder - Container Quickstart Guide

**Last Updated:** April 22, 2026  
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

3. **Vim** (or another editor) - The steps below use `vim` to edit configuration files
   ```bash
   # Fedora/RHEL
   sudo dnf install vim
   ```
   You can use `nano` or a graphical editor instead; replace `vim` in the commands in this guide with whatever you prefer.

4. **osbuild-selinux** - Required for SELinux-aware image builds on Fedora/RHEL hosts
   ```bash
   sudo dnf install osbuild-selinux
   ```

5. **Sudo Access** - Required for loop device creation on Linux
   - The build script will automatically use `sudo` when needed

#### Optional: tools for testing the built ISO in a local VM (Fedora host)

If you plan to boot and test the ISO on the **same** machine (for example with **virt-manager**), install the virtualization stack:

```bash
sudo dnf install virt-manager libvirt qemu
sudo systemctl enable libvirtd --now
```

Without these packages you can still **build** the ISO; you would test it on another system, on bare metal, or by installing a VM stack later.

#### Optional: Enable SSH for remote access to the build system

If you are connecting to the build system **remotely** (e.g., SSHing in from another machine to run builds), enable the SSH daemon:

```bash
systemctl enable sshd --now
```

This is not needed if you are working directly on the build machine.

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

**Build Process (default):** The script starts the container **detached** and **streams the build** by following `/tmp/entrypoint.log` **in the same terminal** (you do not need a second window or `podman exec` just to watch progress). A typical run looks like:

1. Container starts with systemd.
2. Message that the container runs detached and this terminal will follow the log.
3. Prepares build environment (patches, cache, and so on).
4. Downloads and installs packages (often the longest phase).
5. Runs post-installation scripts and creates the ISO.
6. When the **build step inside the entrypoint** finishes, the log follow stops. The script prints a short **success or failure** line, then something like: the **container is still running** for inspection, with examples for a shell: `podman exec -it remix-builder bash` (or `sudo podman` on Linux if your script uses it).

**Stopping the container when you are done**  
The build container is only needed while you want to **inspect** the build environment. When you are finished (or to free resources before using the machine for something else), stop it (use `sudo` the same way you do for `podman` in your setup):

```bash
podman stop remix-builder
```

On Linux, if the script used `sudo podman` to start the container, use `sudo podman stop remix-builder`.

**Interactive attach (optional):** If you want the old behavior and attach the terminal directly to the container (no host-side log follow), use `./Build_Remix.sh --attach` or set `REMIX_BUILD_ATTACH=1` before running the script.

**Build Process (summary):**
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
`Build_Remix.sh` is configured for **host SELinux**: bind mounts use **`:z`** and **`--security-opt label=disable` is not used**, so `setfiles` inside the container can complete. Ensure you are on a current `Fedora_Remix` tree and that **`Setup/files/Fixes/kickstart.py`** is present (the build installs it into `imgcreate`).

If relabel still fails:

1. On the **host** (Fedora), check for denials: `sudo ausearch -m avc -ts recent`
2. Confirm output and workspace paths support extended attributes (avoid odd network-only mounts for the ISO output tree if possible)
3. See **`LINUX_BUILD_FIX.md`** (Fix #3 / Fix #3b) for the full write-up

Historical note: `SELINUX_RELABEL_FIX.md` describes an older “warn and continue” approach; the default is again **strict relabel** with **enforcing** in the live kickstart when the container setup is correct.

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

### After the log follow ends

When you run `./Build_Remix.sh` in the default mode, your terminal shows the **same** build output that is written to `/tmp/entrypoint.log` in the container. After the **remix-builder** entrypoint completes, the script prints whether the build **succeeded** or **failed** and reminds you that the **container is still running**. Use **`podman stop remix-builder`** (with `sudo` if your build used `sudo podman`) to stop it when you no longer need a shell inside the container.

### Successful Build

**Expected output (excerpt from the end of the build log):**
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
   - If you installed **virt-manager**, **libvirt**, and **qemu** (and enabled **libvirtd**) as described in **Prerequisites** (optional VM testing tools), use **virt-manager** on the same machine
   - Otherwise use GNOME Boxes, VirtualBox, or another hypervisor
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
5. Wait 30-45 minutes (build log streams in the same terminal; when the follow step ends, run `podman stop remix-builder` if you are done with the container)
6. Find ISO at `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso`

**Optional Customization:**

- Edit `Setup/Kickstarts/FedoraRemixPackages.ks` - Add/remove packages
- Edit kickstart files in `Setup/Kickstarts/` - Advanced customization
- Replace branding files in `Setup/files/` - Custom look and feel

**That's it!** You now have a custom Fedora Remix ISO ready to use.

---

**Last Updated:** April 22, 2026  
**Version:** 1.1