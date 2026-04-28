# Fedora Remix Quickstart Guide

A comprehensive guide for building and customizing Fedora Remix using the containerized build system.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Architecture](#project-architecture)
3. [Prerequisites](#prerequisites)
4. [Building Without a Container](#building-without-a-container)
5. [Quick Start](#quick-start)
6. [Version and Title Configuration](#version-and-title-configuration)
7. [RemixBuilder Container](#remixbuilder-container)
8. [Setup Directory Reference](#setup-directory-reference)
9. [Python Scripts Deep Dive](#python-scripts-deep-dive)
10. [Kickstart Files Overview](#kickstart-files-overview)
11. [Building the Remix ISO](#building-the-remix-iso)
12. [Post-Installation Customization](#post-installation-customization)
13. [Fedora Remix Tools](#fedora-remix-tools)
14. [Configuration Files](#configuration-files)
15. [Troubleshooting](#troubleshooting)

---

## Overview

The Fedora Remix project consists of multiple repositories that work together to create, build, and customize a custom Fedora Live ISO:

| Repository | Purpose |
|------------|---------|
| **Fedora_Remix** | Main project with kickstart files, customizations, and build setup |
| **RemixBuilder** | Containerized build environment using Podman |
| **FedoraRemixCustomize** | Ansible playbooks for post-installation customization |
| **Fedora_Remix_Tools** | Qt5-based GUI toolkit for system management |

---

## Project Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        BUILD PHASE                                  │
├─────────────────────────────────────────────────────────────────────┤
│  RemixBuilder Container                                             │
│  ├── Prepares web files and build environment                      │
│  ├── Runs livecd-creator with kickstart configuration              │
│  └── Produces FedoraRemix.iso                                      │
├─────────────────────────────────────────────────────────────────────┤
│  Fedora_Remix/Setup                                                 │
│  ├── Kickstarts/ (modular kickstart configuration)                 │
│  ├── files/ (branding, extensions, boot themes)                    │
│  └── Python/Bash scripts for build orchestration                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     POST-INSTALL PHASE                              │
├─────────────────────────────────────────────────────────────────────┤
│  FedoraRemixCustomize                                               │
│  ├── GNOME Extensions deployment                                    │
│  ├── GNOME Tweaks configuration                                     │
│  └── Fingerprint service enablement                                 │
├─────────────────────────────────────────────────────────────────────┤
│  Fedora_Remix_Tools                                                 │
│  ├── PyQt5 GUI for system management                                │
│  ├── RPM package for distribution                                   │
│  └── Config-driven menu system                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Host System Requirements

- **Podman** installed and configured
- **GitHub Personal Access Token** with `write:packages` permission (for pushing container images)
- **SSH key** for GitHub access
- **~15GB free disk space** for the build

### For Linux Hosts

```bash
# Install Podman
sudo dnf install podman

# Verify installation
podman --version
```

### For macOS Hosts

```bash
# Install Podman via Homebrew
brew install podman

# Initialize and start Podman machine
podman machine init
podman machine start
```

---

## Building Without a Container

If you want to build the Fedora Remix directly on a Fedora Linux system without using the container, you need to install the required packages manually.

### Required System Packages

```bash
# Core build tools
sudo dnf install -y \
    livecd-tools \
    python3-pyyaml \
    python3 \
    vim \
    git \
    rsync

# Fedora 42+: install util-linux-script if you need standalone script(1) split from util-linux
# (Prepare_Fedora_Remix_Build.py adds this automatically on F42+.)

# HTTP server for hosting files during build
sudo dnf install -y httpd

# For SSH filesystem mounting (optional but recommended)
sudo dnf install -y sshfs

# For remote repository access
sudo dnf install -y curl wget
```

### Package Summary Table

| Package | Purpose |
|---------|---------|
| `livecd-tools` | Core tool for creating Live ISO images (includes `livecd-creator`) |
| `python3-pyyaml` | YAML parsing for configuration files |
| `python3` | Python interpreter for setup scripts |
| `httpd` | Apache web server for hosting build files |
| `sshfs` | SSH filesystem for remote mounting (optional) |
| `vim` | Text editor for configuration |
| `git` | Version control and repository cloning |
| `rsync` | File synchronization |
| `util-linux-script` | (Fedora 42+) Optional; `script` for livecd logging — on older Fedora it is in **`util-linux`** |

### Manual Build Steps (Without Container)

Prefer **`./Build_Remix_Physical.sh`** from the Fedora_Remix repo root (sets version/PXE prompts, runs prepare scripts, then the enhanced livecd build).

Manual equivalent — **prepare build tree first**, then web files ([README_Scripts_Usage.md](../README_Scripts_Usage.md)):

```bash
cd Fedora_Remix/Setup

# 1. Create /livecd-creator/FedoraRemix and copy kickstarts/scripts
sudo python3 Prepare_Fedora_Remix_Build.py

# 2. Configure httpd / web assets (optional: PXE files per Setup/config.yml)
sudo python3 Prepare_Web_Files.py

cd /livecd-creator/FedoraRemix
sudo ./Enhanced_Remix_Build_Script.sh
```

### SELinux Considerations

The build scripts automatically set SELinux to permissive mode:

```bash
# This is done automatically by the build scripts
sudo setenforce 0
```

---

## Quick Start

### Step 1: Clone Required Repositories

```bash
# Clone all related repositories
git clone https://github.com/tmichett/Fedora_Remix.git
git clone https://github.com/tmichett/RemixBuilder.git
git clone https://github.com/tmichett/FedoraRemixCustomize.git
git clone https://github.com/tmichett/Fedora_Remix_Tools.git
```

### Step 2: Configure the Build

1. **In your `Fedora_Remix` clone**, align versions and PXE options (recommended):
   ```bash
   cd Fedora_Remix
   ./Update_Remix_Config.sh
   ```
   Then edit root **`config.yml`** for paths: **`SSH_Key_Location`**, **`Fedora_Remix_Location`**, **`GitHub_Registry_Owner`** (image name is derived from owner + **`Fedora_Version`**).

2. **RemixBuilder `config.yml`** (if you build/push the container image from [RemixBuilder](https://github.com/tmichett/RemixBuilder)): set **`Fedora_Version`** to the same numeric release as **`Fedora_Remix/Setup/config.yml`**. Optionally copy this file into the Fedora_Remix repo root for **`Build_Remix.sh`**.

3. **`Fedora_Remix/Setup/config.yml`** — after **`Update_Remix_Config.sh`**, **`fedora_version`** matches **`Fedora_Version`**; keep **`web_root`** and **`include_pxeboot_files`** as documented in [Quickstart_Container.md](../Quickstart_Container.md).

### Step 3: Build and Run

```bash
# Option A: Build container locally
cd RemixBuilder
./build.sh

# Option B: Use pre-built container from registry
# (Skip build.sh if image already exists)

# Run the build from the Fedora_Remix repo root (where Build_Remix.sh lives)
cd /path/to/Fedora_Remix
./Build_Remix.sh
```

### Step 4: Get Your ISO

After successful build, the ISO is located at:
```
/livecd-creator/FedoraRemix/FedoraRemix.iso
```

---

## Version and Title Configuration

### Where to Change the Fedora Version

When building for a new Fedora version (e.g., upgrading from 43 to 44), keep settings aligned.

**Fastest:** from **`Fedora_Remix`**, run **`./Update_Remix_Config.sh`** — it updates **`Fedora_Version`** (root `config.yml`) and **`fedora_version`** (`Setup/config.yml`) together.

#### 1. RemixBuilder Configuration (container image)

**File:** `RemixBuilder/config.yml` — set **`Fedora_Version`** to your target (e.g. `"44"`). Image tag is **`ghcr.io/{GitHub_Registry_Owner}/fedora-remix-builder:{Fedora_Version}`** (no separate `Image_Name` field in current trees).

#### 2. Setup Configuration

**File:** `Fedora_Remix/Setup/config.yml` — **`fedora_version`** must match **`Fedora_Version`**. Use **`Update_Remix_Config.sh`** or edit by hand.

This controls:
- PXE boot file downloads from the correct Fedora version (when **`include_pxeboot_files`** is true)
- Version displayed in build messages

#### 3. Build Scripts (Automatic)

The build scripts (`Enhanced_Remix_Build_Script.sh` and `Remix_Build_Script.sh`) automatically read the version from `config.yml`:

```bash
# From Enhanced_Remix_Build_Script.sh (lines 48-61)
get_fedora_version() {
    local config_file="config.yml"
    if [ -f "$config_file" ]; then
        local version=$(grep '^fedora_version:' "$config_file" | awk '{print $2}' | tr -d '"')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "42"  # fallback default
        fi
    else
        echo "42"  # fallback default
    fi
}
```

> **Note:** If `config.yml` is not found, the scripts default to version `42`.

### Where to Change the ISO Title

The ISO title (volume ID) is set in the build scripts and appears in file managers when mounting the ISO.

#### Build Script Title Configuration

**File:** `Fedora_Remix/Setup/Enhanced_Remix_Build_Script.sh`

```bash
# Line 65-66 - Title is built dynamically from version
readonly FEDORA_VERSION=$(get_fedora_version)
readonly BUILD_TITLE="FEDORA_REMIX_${FEDORA_VERSION}"
```

The title is automatically set to `FEDORA_REMIX_XX` where `XX` is the version number.

#### Customizing the Title

To customize the title format, edit `Enhanced_Remix_Build_Script.sh`:

```bash
# Example: Change to a custom title format
readonly BUILD_TITLE="MY_CUSTOM_REMIX_${FEDORA_VERSION}"
```

Or for a completely static title:

```bash
readonly BUILD_TITLE="TRAVIS_FEDORA_REMIX"
```

> **Important:** The title must be ISO 9660 compliant (uppercase letters, numbers, underscores only, max 32 characters).

### How to Update the Build Script

The build scripts can be modified to change build behavior:

#### Key Variables in `Enhanced_Remix_Build_Script.sh`

| Variable | Line | Purpose |
|----------|------|---------|
| `BUILD_NAME` | 44 | Output ISO filename (default: `FedoraRemix`) |
| `KS_FILE` | 45 | Kickstart file to use (default: `FedoraRemix.ks`) |
| `CACHE_DIR` | 46 | Package cache directory |
| `BUILD_TITLE` | 66 | ISO volume ID/title |

#### Modifying the livecd-creator Command

The actual build command is in the `run_build()` function (line 260):

```bash
livecd-creator --cache="$CACHE_DIR" -f "$BUILD_NAME" -c "$KS_FILE" --title="$BUILD_TITLE"
```

**Common modifications:**

```bash
# Add verbose output
livecd-creator --cache="$CACHE_DIR" -f "$BUILD_NAME" -c "$KS_FILE" --title="$BUILD_TITLE" --debug

# Use a different kickstart
readonly KS_FILE="FedoraRemix-Custom.ks"

# Change output filename
readonly BUILD_NAME="MyCustomRemix"
```

#### Classic Build Script (`Remix_Build_Script.sh`)

For simpler builds, the classic script at line 29:

```bash
script -c "livecd-creator --cache=/livecd-creator/package-cache -f FedoraRemix -c FedoraRemix.ks --title=\"FEDORA_REMIX_${FEDORA_VERSION}\" 2>&1" FedoraBuild-$(date +%m%d%y-%k%M).out
```

### Version Update Checklist

When updating to a new Fedora version:

- [ ] Update `RemixBuilder/config.yml` → `Fedora_Version`
- [ ] Update `RemixBuilder/config.yml` → `Image_Name` tag
- [ ] Update `Fedora_Remix/Setup/config.yml` → `fedora_version`
- [ ] Rebuild the container: `./build.sh`
- [ ] (Optional) Push new container: `./push.sh`
- [ ] Run the build: `./Build_Remix.sh`

---

## RemixBuilder Container

The RemixBuilder project provides a Podman container that automates the entire Fedora Remix build process.

### Container Structure

| Component | Description |
|-----------|-------------|
| `Containerfile` | Defines the container image based on Fedora |
| `build.sh` | Builds the container image |
| `push.sh` | Pushes container to GitHub Container Registry |
| `Build_Remix.sh` | Runs the container and executes the build |
| `entrypoint.sh` | Automated build script run inside container |
| `config.yml` | Central configuration file |

### Volume Mounts

When running `Build_Remix.sh`, these volumes are mounted:

| Host Path | Container Path | Mode |
|-----------|----------------|------|
| `SSH_Key_Location` | `/root/github_id` | Read-only |
| `Fedora_Remix_Location` | `/livecd-creator` | Read-write |
| Current directory | `/root/workspace` | Read-write |

### Container Build Process

The `entrypoint.sh` script executes automatically:

1. Waits for workspace directory availability
2. Runs `Prepare_Web_Files.py` - Sets up web server and downloads PXE boot files
3. Runs `Prepare_Fedora_Remix_Build.py` - Prepares build directories and files
4. Runs `Enhanced_Remix_Build_Script.sh` - Executes livecd-creator

### Building the Container

```bash
cd RemixBuilder

# Build the container image
./build.sh

# Push to GitHub Container Registry (requires login)
./push.sh
```

### Running the Build Container

```bash
# Start the build process
./Build_Remix.sh

# Inside the container, you can:
# - View logs: journalctl -u remix-builder.service -n 100
# - Check log file: tail -f /tmp/entrypoint.log
# - Exit container: type 'exit' or 'poweroff'
```

---

## Setup Directory Reference

The `Fedora_Remix/Setup` directory contains all build configuration and assets.

### Directory Structure

```
Setup/
├── config.yml                       # Web files configuration
├── Prepare_Web_Files.py             # Sets up HTTP server and files
├── Prepare_Fedora_Remix_Build.py    # Prepares build environment
├── Enhanced_Remix_Build_Script.sh   # Main build script with rich output
├── Remix_Build_Script.sh            # Classic build script
│
├── Kickstarts/                      # Kickstart configuration
│   ├── FedoraRemix.ks               # Main kickstart file
│   ├── FedoraRemixPackages.ks       # Package selections
│   ├── FedoraRemixRepos.ks          # Third-party repositories
│   ├── fedora-live-base.ks          # Base live system config
│   ├── fedora-workstation-common.ks # Workstation packages
│   ├── KickstartSnippets/           # Modular installation snippets
│   │   ├── install-ansible.ks
│   │   ├── install-cursor.ks
│   │   ├── install-flatpaks.ks
│   │   ├── setup-gnome-extensions.ks
│   │   └── ... (29 total snippets)
│   └── Extra/                       # Alternative configurations
│
├── files/                           # Assets for the Remix
│   ├── boot/                        # Boot theme and splash screens
│   ├── extensions/                  # GNOME shell extensions
│   ├── logos/                       # Branding images
│   ├── VSCode/                      # VSCode extensions (.vsix)
│   └── Fixes/                       # Python patches
│
├── Scripts/                         # Utility scripts
│   ├── download_vscode_extensions.sh
│   └── update_vscode_kickstart.sh
│
└── collections/                     # Ansible collection requirements
    └── requirements.yml
```

---

## Python Scripts Deep Dive

The Setup directory contains two essential Python scripts that prepare the build environment.

### `Prepare_Web_Files.py`

This script sets up the HTTP server environment that the kickstart uses to download files during the build process.

#### What It Does

1. **Loads Configuration**
   - Reads `config.yml` to get `fedora_version` and `web_root` settings
   - Default web root: `/var/www/html`

2. **Installs Apache (httpd)**
   ```python
   install_packages("httpd")
   ```

3. **Copies Build Assets**
   - `./files/` → `/var/www/html/files/` (logos, extensions, configs)
   - `./files/boot/tm-fedora-remix/` → `/var/www/html/tm-fedora-remix/` (boot theme)
   - Apache config → `/etc/httpd/conf.d/`

4. **Clones Git Repositories**
   ```python
   clone_git_repo("https://github.com/tmichett/FedoraRemixCustomize.git", f"{web_root}/FedoraRemixCustomize")
   clone_git_repo("https://github.com/tmichett/PXEServer.git", f"{web_root}/PXEServer")
   ```

5. **Downloads PXE Boot Files**
   - Downloads `vmlinuz` and `initrd.img` from Fedora mirrors
   - URL pattern: `https://download.fedoraproject.org/pub/fedora/linux/releases/{version}/Server/x86_64/os/images/pxeboot/`

6. **Copies Additional Resources**
   - YAD scripts → `/var/www/html/scripts/`
   - VSCode extensions → `/var/www/html/VSCode/`
   - Python patches (kickstart.py, fs.py) → `/var/www/html/`

7. **Enables HTTP Service**
   ```python
   enable_service("httpd")
   ```

#### Configuration File

```yaml
# Setup/config.yml
fedora_boot_files:
  - "vmlinuz"
  - "initrd.img"
fedora_version: 43
web_root: "/var/www/html"
include_pxeboot_files: false
```

### `Prepare_Fedora_Remix_Build.py`

This script prepares the livecd-creator build environment.

#### What It Does

1. **Installs Required Packages**
   ```python
   remix_packages = ["vim", "livecd-tools", "sshfs"]
   # util-linux-script appended on Fedora 42+ (see Prepare_Fedora_Remix_Build.py)
   install_packages(remix_packages)
   ```

2. **Creates Directory Structure**
   ```python
   remix_directories = [
       "/livecd-creator/FedoraRemix",
       "/livecd-creator/package-cache"
   ]
   ```

3. **Copies Kickstart Files**
   - Syncs entire `./Kickstarts/` directory → `/livecd-creator/FedoraRemix/`
   - Uses rsync for efficient copying

4. **Copies Python Automation Scripts**
   ```python
   copy_file("./Prepare_Fedora_Remix_Build.py", "/livecd-creator/FedoraRemix/")
   copy_file("./Prepare_Web_Files.py", "/livecd-creator/FedoraRemix/")
   ```

5. **Copies Build Scripts with Executable Permissions**
   ```python
   exec_mode = 0o755
   copy_file("./Enhanced_Remix_Build_Script.sh", "/livecd-creator/FedoraRemix/", exec_mode)
   copy_file("../Remix_Build_Script.sh", "/livecd-creator/FedoraRemix/", exec_mode)
   ```

6. **Copies Configuration**
   ```python
   copy_file("./config.yml", "/livecd-creator/FedoraRemix/config.yml")
   ```

#### Output Structure

After running, the `/livecd-creator/FedoraRemix/` directory contains:

```
/livecd-creator/FedoraRemix/
├── config.yml
├── Enhanced_Remix_Build_Script.sh    # Recommended build script
├── Remix_Build_Script.sh             # Classic build script
├── Prepare_Fedora_Remix_Build.py
├── Prepare_Web_Files.py
├── FedoraRemix.ks                    # Main kickstart
├── FedoraRemixPackages.ks
├── FedoraRemixRepos.ks
├── fedora-live-base.ks
├── fedora-workstation-common.ks
├── fedora-repo.ks
├── fedora-repo-not-rawhide.ks
└── KickstartSnippets/
    └── (29+ snippet files)
```

---

## Kickstart Files Overview

The Fedora Remix uses a modular kickstart system with files organized hierarchically.

### Kickstart Architecture

```
FedoraRemix.ks (Main Entry Point)
├── %include fedora-live-base.ks
│   └── %include fedora-repo.ks
│       ├── %include fedora-repo-not-rawhide.ks
│       └── %include FedoraRemixRepos.ks
├── %include fedora-workstation-common.ks
├── %include FedoraRemixPackages.ks
└── %include KickstartSnippets/*.ks (29+ files)
```

### Core Kickstart Files

| File | Purpose |
|------|---------|
| `FedoraRemix.ks` | Main kickstart - orchestrates the entire build |
| `fedora-live-base.ks` | Base live system configuration (language, keyboard, partitioning, live scripts) |
| `fedora-repo.ks` | Standard Fedora repository definitions |
| `fedora-repo-not-rawhide.ks` | Stable (non-rawhide) repository mirrors |
| `fedora-workstation-common.ks` | Standard GNOME workstation packages |
| `FedoraRemixPackages.ks` | Custom package selections for the Remix |
| `FedoraRemixRepos.ks` | Third-party repositories (Google Chrome, VSCode, RPM Fusion, etc.) |

### FedoraRemix.ks - Main Kickstart

This is the entry point that includes all other files and contains the `%post` scripts.

**Key Sections:**

```kickstart
# Include base configurations
%include fedora-live-base.ks
%include fedora-workstation-common.ks
%include FedoraRemixPackages.ks

# Post-installation scripts (chroot environment)
%post --nochroot
# Install Ansible early (needs network before chroot)
%include KickstartSnippets/install-ansible.ks
%end

# Main post-installation (inside chroot)
%post
# Read version from config
FEDORA_VERSION=$(grep '^fedora_version:' /var/www/html/Setup/config.yml | awk '{print $2}')

# Download branding and customizations from local HTTP server
wget -O /usr/share/pixmaps/login-logo.png http://localhost/files/fedorap_small.png
wget -O /etc/dconf/db/gdm.d/01-logo http://localhost/files/01-logo
# ... more downloads ...

# Include all customization snippets
%include KickstartSnippets/install-flatpaks.ks
%include KickstartSnippets/customize-anaconda.ks
%include KickstartSnippets/setup-gnome-extensions.ks
# ... 29+ more snippets ...
%end
```

### FedoraRemixPackages.ks - Custom Packages

Defines all custom packages for the Remix:

```kickstart
%packages
# Development Tools
@Development Tools
@RPM Development Tools
vim-enhanced
git
code  # VSCode

# Virtualization
@Virtualization
guestfs-tools
podman-machine
buildah
skopeo

# Media & Graphics
vlc
kdenlive
obs-studio
gimp
inkscape

# Browsers
firefox
chromium
google-chrome-stable

# Networking & Hardware
@hardware-support
NetworkManager-wifi
iwl*  # Intel WiFi firmware
wireguard-tools

# Ansible & Automation
linux-system-roles
python-jmespath

# CLI Utilities
zoxide
eza
btop
bat
fzf

# Remove unwanted
-gnome-tour
-vlc-plugins-freeworld  # Conflicts with vlc-plugins-base
%end
```

### FedoraRemixRepos.ks - Third-Party Repositories

```kickstart
# Extra Repos (RPM Fusion uses metalinks; eza ships from Fedora rust-eza — see FedoraRemixRepos.ks)
repo --name="rpmfusion-free" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
repo --name="rpmfusion-nonfree" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name="google-chrome" --baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
repo --name="vscode" --baseurl=https://packages.microsoft.com/yumrepos/vscode
repo --name="GithubCLITools" --baseurl=https://cli.github.com/packages/rpm
repo --name="DUST-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/gourlaysama/dust/fedora-$releasever-$basearch/
repo --name="YAZI-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/lihaohong/yazi/fedora-$releasever-$basearch/
repo --name="FedoraRemix-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/tmichett/FedoraRemix/fedora-$releasever-$basearch/
```

### fedora-live-base.ks - Base Live System

Sets up the foundational live system:

```kickstart
# Locale and keyboard
lang en_US.UTF-8
keyboard us
timezone US/Eastern

# Security
selinux --enforcing
firewall --enabled --service=mdns

# Partitioning (30GB root)
zerombr
clearpart --all
part / --size 30480 --fstype ext4

# Network (static for build, DHCP for live)
network --device=link --bootproto=static --ip=192.168.1.15 --netmask=255.255.255.0 --gateway=192.168.1.1 --nameserver=192.168.1.1 --activate

# Essential packages
%packages
kernel
kernel-modules
kernel-modules-extra
anaconda
anaconda-live
anaconda-webui
dracut-live
glibc-all-langpacks  # All locale data for installer
%end
```

### KickstartSnippets Directory

Contains 29+ modular files for specific customizations:

| Category | Files |
|----------|-------|
| **Application Installation** | `install-ansible.ks`, `install-cursor.ks`, `install-flatpaks.ks`, `install-lmstudio.ks`, `install-veracrypt.ks`, `install-vlc.ks`, `install-calibre.ks`, `install-balena-etcher.ks`, `install-mutagen.ks`, `install-udpcast.ks`, `install-ohmybash.ks`, `install-podman-bootc.ks`, `install-gnome-tweaks.ks` |
| **System Customization** | `customize-anaconda.ks`, `customize-bash-shell.ks`, `customize-gnome-wallpaper.ks`, `customize-grub.ks` |
| **GNOME & Desktop** | `setup-gnome-extensions.ks`, `setup-desktop-icons.ks`, `setup-vscode-extensions.ks` |
| **System Setup** | `setup-firstboot.ks`, `setup-tmux.ks`, `setup-dynamic-motd.ks`, `setup-yad-scripts.ks`, `create-ansible-user.ks`, `set-bash-defaults.ks`, `update-ansible-collections.ks` |
| **Networking** | `enable-wifi-pxeboot.ks` |
| **Formatting** | `format-functions.ks` (shared formatting functions) |

### format-functions.ks - Shared Formatting

Provides rich visual output during kickstart execution:

```bash
# Unicode symbols for visual feedback
readonly CHECKMARK="✅"
readonly CROSS="❌"
readonly PACKAGE="📦"
readonly DOWNLOAD="📥"

# Formatting functions
ks_print_header() {
    echo -e "\n╔══════════════════════════════════════════════════════════════╗"
    echo -e "║ $message                                                      ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝\n"
}

ks_print_success() {
    echo -e "✅ $(date '+%H:%M:%S') ${GREEN}${message}${NC}"
}

ks_print_step() {
    # Creates progress bars: [2/5] ████████░░░░░░░░░░░░ Installing packages
}
```

### Customizing Kickstarts

#### Adding a New Package

Edit `FedoraRemixPackages.ks`:

```kickstart
%packages
# Add your package
my-custom-package
%end
```

#### Adding a New Snippet

1. Create `KickstartSnippets/install-myapp.ks`:

```bash
## Install My Custom Application
ks_print_section "📦 INSTALLING MY APPLICATION"
ks_print_download "my-application"
wget -O /tmp/myapp.rpm https://example.com/myapp.rpm
dnf install -y /tmp/myapp.rpm
ks_print_success "My Application installed successfully"
```

2. Include in `FedoraRemix.ks`:

```kickstart
%post
# ... existing includes ...
%include KickstartSnippets/install-myapp.ks
%end
```

#### Disabling a Feature

Comment out the `%include` line in `FedoraRemix.ks`:

```kickstart
## Disable LM Studio installation
# %include KickstartSnippets/install-lmstudio.ks
```

---

## Building the Remix ISO

### Using the Enhanced Build Script

The recommended method uses the enhanced build script with rich visual output:

```bash
cd /livecd-creator/FedoraRemix

# Run the enhanced build
sudo ./Enhanced_Remix_Build_Script.sh
```

**Features:**
- ✅ Prerequisites checking
- 📊 Visual progress tracking
- 🎯 Rich Unicode formatting
- 📝 Comprehensive logging to `FedoraBuild-MMDDYY-HHMM.log`
- ⏱️ Build timing statistics

### Manual Build (if needed)

```bash
# Direct livecd-creator command
sudo livecd-creator \
  --cache=/livecd-creator/package-cache \
  -f FedoraRemix \
  -c FedoraRemix.ks \
  --title="FEDORA_REMIX_43"
```

### Build Output

| Output | Location |
|--------|----------|
| ISO Image | `/livecd-creator/FedoraRemix/FedoraRemix.iso` |
| Build Log | `/livecd-creator/FedoraRemix/FedoraBuild-*.log` |
| Package Cache | `/livecd-creator/package-cache/` |

---

## Post-Installation Customization

### FedoraRemixCustomize Project

After installing Fedora Remix, use the Ansible playbooks for additional customization:

```bash
cd FedoraRemixCustomize
```

### Available Playbooks

| Playbook | Purpose |
|----------|---------|
| `Deploy_Gnome_Extensions.yml` | Install GNOME Shell extensions (DING, Add-to-Desktop) |
| `Deploy_Gnome_Tweaks.yml` | Configure GNOME Tweaks settings |
| `Enable_Gnome_Extensions.yml` | Enable installed extensions |
| `Enable_Fingerprint_Services.yml` | Configure fingerprint authentication |

### Running Playbooks

```bash
# Install GNOME extensions
ansible-playbook Deploy_Gnome_Extensions.yml

# Enable fingerprint services
ansible-playbook Enable_Fingerprint_Services.yml
```

### Included GNOME Extensions

| Extension | Purpose |
|-----------|---------|
| **DING** (Desktop Icons NG) | Enables desktop icons on GNOME |
| **Add-to-Desktop** | Right-click context menu to create desktop shortcuts |

---

## Fedora Remix Tools

A PyQt5-based GUI toolkit for managing the Fedora Remix system.

### Features

- **Config-driven menus** via `config.yml`
- **Real-time command output** with detachable terminal window
- **Multi-column layout** support
- **Interactive input** for commands requiring user input

### Installation

The tools are distributed as an RPM package:

```bash
# Build the RPM
cd Fedora_Remix_Tools
./RPM_Build.sh

# Install
sudo dnf install ~/rpmbuild/RPMS/noarch/FedoraRemixTools-*.rpm
```

### Running Manually

```bash
# Create virtual environment
uv venv menu_venv --python=3.12
source menu_venv/bin/activate
uv pip install PyQt5 PyYaml

# Run the menu
python menu.py
```

### Configuration

The `config.yml` file defines the menu structure:

```yaml
icon: smallicon.png
logo: logo.png
logo_size: 320x240
menu_title: Fedora Remix Toolkit
num_columns: 3

menu_items:
  - name: Fedora Remix Basic Tasks
    column: 1
    submenu_columns: 3
    items:
      - name: Update Packages
        command: sudo /opt/FedoraRemix/scripts/update_pkgs.sh
      - name: Create Root SSH Keys
        command: sudo /opt/FedoraRemix/scripts/create_ssh_key.sh
```

### Available Tool Categories

| Category | Tasks |
|----------|-------|
| **Basic Tasks** | Update packages, root password, SSH keys, GRUB customization |
| **User Operations** | SSH key creation, sudoers update, GNOME customization |
| **Maintenance** | Python kickstart fix, fingerprint services |

---

## Configuration Files

### RemixBuilder `config.yml`

```yaml
Container_Properties:
  Fedora_Version: "43"
  SSH_Key_Location: "~/.ssh/github_id"
  Fedora_Remix_Location: "/path/to/Fedora_Remix"
  GitHub_Registry_Owner: "username"
  Image_Name: "ghcr.io/username/fedora-remix-builder:43"
```

### Setup `config.yml`

```yaml
fedora_boot_files:
  - "vmlinuz"
  - "initrd.img"
fedora_version: 43
web_root: "/var/www/html"
```

### Version Synchronization

> ⚠️ **Important:** Always ensure `fedora_version` values match across all config files:
> - `RemixBuilder/config.yml` → `Fedora_Version`
> - `Fedora_Remix/Setup/config.yml` → `fedora_version`

---

## Troubleshooting

### Container Won't Start

```bash
# Check if Podman is running
podman info

# Verify image exists
podman images | grep fedora-remix-builder

# Check config.yml paths
cat config.yml
```

### Build Fails with `/sys` Unmount Errors

This is a known issue fixed in the latest version. The `fs.py` patch is automatically applied:

```bash
# Verify patch is in place (inside container)
grep "Ignore unmount errors for /sys" /usr/lib/python3.*/site-packages/imgcreate/fs.py
```

### SSH Operations Fail

```bash
# Verify SSH key permissions
chmod 600 ~/.ssh/github_id

# Test SSH connection
ssh -T git@github.com
```

### View Build Logs

```bash
# Inside container
journalctl -u remix-builder.service -n 100

# Or view log file
tail -f /tmp/entrypoint.log

# Build-specific log
cat /livecd-creator/FedoraRemix/FedoraBuild-*.log
```

### Low Disk Space Warnings

The build requires ~15GB. Free up space or expand the disk:

```bash
# Check available space
df -h /livecd-creator

# Clear package cache (if rebuilding)
rm -rf /livecd-creator/package-cache/*
```

### Missing Dependencies in Kickstart

If packages fail to install, check repository availability:

```bash
# Inside container, verify repos
dnf repolist

# Check specific package
dnf info <package-name>
```

---

## Workflow Summary

### Complete Build Workflow

```
1. Clone repositories
   ↓
2. Configure config.yml files (match Fedora versions)
   ↓
3. Build container: ./build.sh (or use existing image)
   ↓
4. Run build: ./Build_Remix.sh
   ↓
5. Container automatically:
   - Prepares web files
   - Copies kickstarts
   - Runs livecd-creator
   ↓
6. Retrieve ISO from /livecd-creator/FedoraRemix/FedoraRemix.iso
   ↓
7. Boot and install Fedora Remix
   ↓
8. Use FedoraRemixCustomize and Fedora_Remix_Tools for post-install
```

### File Locations Reference

| Purpose | Location |
|---------|----------|
| Container config | `RemixBuilder/config.yml` |
| Build config | `Fedora_Remix/Setup/config.yml` |
| Kickstart files | `Fedora_Remix/Setup/Kickstarts/` |
| Branding/assets | `Fedora_Remix/Setup/files/` |
| Ansible playbooks | `FedoraRemixCustomize/*.yml` |
| GUI tools | `Fedora_Remix_Tools/rpmbuild/SOURCES/` |
| Built ISO | `/livecd-creator/FedoraRemix/FedoraRemix.iso` |

---

## Additional Resources

- [Kickstarts README](../Setup/Kickstarts/README.md) - Detailed kickstart documentation
- [Linux Build Fix](../LINUX_BUILD_FIX.md) - Solutions for Linux-specific build issues
- [RemixBuilder README](../../RemixBuilder/README.md) - Container build details

---

*Last updated: December 2025*

