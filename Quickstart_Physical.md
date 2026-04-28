# Fedora Remix Builder - Physical/Virtual Machine Quickstart Guide

**Last Updated:** April 28, 2026  
**Purpose:** Quick guide to building a custom Fedora Remix ISO on a physical or virtual machine (non-containerized method), led by **`Build_Remix_Physical.sh`**

---

## Overview

This guide will walk you through building a custom Fedora Remix ISO image directly on a physical machine or virtual machine without using containers. This method installs the Fedora Remix build environment directly on your system.

**Build Time:** Approximately 30-45 minutes  
**Output:** A bootable Fedora Remix ISO file (~7-8 GB)

> **💡 Looking for the containerized method?** See **[Quickstart_Container.md](Quickstart_Container.md)** for building with containers (Podman), or use **[Build_Remix.sh](Build_Remix.sh)** to drive the builder image.

**Configure first (recommended):** **[`Update_Remix_Config.sh`](Update_Remix_Config.sh)** interactively sets **`SSH_Key_Location`**, **`Fedora_Remix_Location`**, **`GitHub_Registry_Owner`**, Fedora release, and whether to stage **PXE Linux** boot artifacts (`vmlinuz`, `initrd.img` in the web tree). It updates the root **`config.yml`** under **`Container_Properties`**, and **`Setup/config.yml`** (`fedora_version`, `include_pxeboot_files`), replacing most manual YAML edits. If you use **`ghcr.io/tmichett/fedora-remix-builder`** from the registry later, keep **`GitHub_Registry_Owner`** **`tmichett`**. See [Step 4](#step-4-fedora-release-and-pxe-update_remix_configsh) for PXE caveats on old or very new Fedora versions.

**Recommended (native build):** From the repository root, run **[`Build_Remix_Physical.sh`](Build_Remix_Physical.sh)**. It updates `Setup/config.yml` (`fedora_version`), runs `Setup/Prepare_Fedora_Remix_Build.py` and `Setup/Prepare_Web_Files.py` in the correct order, then runs **[`Setup/Enhanced_Remix_Build_Script.sh`](Setup/Enhanced_Remix_Build_Script.sh)** in `/livecd-creator/FedoraRemix` with the kickstart you choose. Use `./Build_Remix_Physical.sh -h` for options (`-v` release, `-k` kickstart, `-l` list). You can run **`Update_Remix_Config.sh`** first so version and PXE settings are already correct before this script prompts.

---

## Prerequisites

### Required: Fedora Remix Installation

This method requires you to first install Fedora Remix on a physical or virtual machine. You have two options:

#### Option 1: Download Pre-built Fedora Remix ISO

1. **Download the latest Fedora Remix LiveISO:**
   - https://drive.google.com/drive/folders/1UAT07AJIrTdMk3ke_QE6S6vz-qn6qGtR

2. **Create bootable media:**
   - **Physical Machine:** Use Balena Etcher or Fedora Media Writer to create a bootable USB
   - **Virtual Machine:** Attach the ISO to your VM and boot from it

#### Option 2: Use Existing Fedora Installation

If you already have Fedora installed, you can use it as your build system. The setup scripts will install all necessary packages.

### System Requirements

- **Disk Space:** At least 20 GB free (for packages, cache, and ISO)
- **Memory:** 4 GB minimum, 8 GB recommended
- **CPU:** Multi-core processor recommended (build is CPU-intensive)
- **Internet:** Required for downloading packages
- **User Account:** Regular user with sudo privileges

### Supported Systems

- ✅ Fedora Linux (39, 40, 41, 42, 43)
- ✅ Physical machines
- ✅ Virtual machines (VirtualBox, VMware, KVM/QEMU, etc.)

---

## Quick start

You can use the **automated script** (fewer steps) or the **manual** path (same operations by hand). Both end with an ISO under `/livecd-creator/FedoraRemix/`.

### Option A: One script (recommended)

After [Step 1](#step-1-install-fedora-remix-if-not-already-installed) through [Step 3](#step-3-clone-the-fedora-remix-repository) (install, sudo, clone repo), run from the **repository root** (the directory that contains `Build_Remix_Physical.sh`):

```bash
cd /path/to/Fedora_Remix
chmod +x Build_Remix_Physical.sh   # if needed
./Build_Remix_Physical.sh
```

The script will:

1. Ask for the Fedora release (e.g. `43`) and write it to `Setup/config.yml` as `fedora_version`—unless you already set version and PXE options with **`Update_Remix_Config.sh`**
2. Offer a **kickstart menu** (e.g. `FedoraRemix`, `FedoraRemixCosmic`); you can also pass `-k` / `-l` (list) on the command line
3. Run, in order: `sudo python3 Setup/Prepare_Fedora_Remix_Build.py` then `sudo python3 Setup/Prepare_Web_Files.py` (from `Setup/`, as required for paths)
4. `cd` to `/livecd-creator/FedoraRemix` and run `sudo env REMIX_KICKSTART=… ./Enhanced_Remix_Build_Script.sh` (the enhanced `livecd-creator` flow with the same UX style as the repo’s other helper scripts)

Useful options:

| Option | Purpose |
|--------|--------|
| `-v 43` | Set Fedora version without a prompt |
| `-k FedoraRemix` | Choose kickstart without the menu |
| `-l` | List available `FedoraRemix*.ks` base names and exit |
| `-h` | Help |

**Customize first:** If you need to edit kickstarts before the first run, do [Step 6 (manual)](#step-6-customize-your-remix-optional) *after* `Prepare_Fedora_Remix_Build.py` has populated `/livecd-creator/FedoraRemix/`, or run the script’s prepare steps manually once, edit files, then run the build part only (`cd /livecd-creator/FedoraRemix && sudo env REMIX_KICKSTART=FedoraRemix ./Enhanced_Remix_Build_Script.sh`).

Then skip to [Build output](#build-output) and [Troubleshooting](#troubleshooting).

### Option B: Manual steps (8 steps)

The steps below match what `Build_Remix_Physical.sh` automates, if you prefer to run each command yourself. After [Step 4](#step-4-fedora-release-and-pxe-update_remix_configsh), prepare order is: **build directory** first, then **web files and patches** (so `/var/www/html` has `kickstart.py` / `fs.py` fixes before `Enhanced_Remix_Build_Script.sh` runs).

### Step 1: Install Fedora Remix (If Not Already Installed)

If you downloaded the Fedora Remix LiveISO:

1. **Boot from the ISO:**
   - Insert USB or attach ISO to VM
   - Select "Start Fedoraremix" from GRUB menu

2. **Launch the installer:**
   - Click the icon in the top left beside "Apps"
   - Select the Anaconda installer icon from the dock

3. **Complete installation:**
   - Select language and keyboard layout
   - Choose installation destination (disk/partition)
   - Create a user account (make sure to check "Make this user administrator")
   - Optionally set root password
   - Click "Begin Installation"

4. **Reboot after installation:**
   - Remove installation media
   - Boot into your new Fedora Remix system

5. **Update the system:**
   ```bash
   sudo dnf update -y
   ```

### Step 2: Configure User for Building

Ensure your user has proper sudo access:

```bash
# Verify you're in the wheel group
groups

# If not in wheel group, add yourself (requires root)
su -
usermod -aG wheel yourusername
exit

# Test sudo access
sudo whoami
# Should output: root
```

**Optional: Configure passwordless sudo** (for convenience):

```bash
sudo visudo
# Add this line (replace 'yourusername' with your username):
yourusername ALL=(ALL) NOPASSWD: ALL
```

### Step 3: Clone the Fedora Remix Repository

```bash
# Clone the repository
git clone https://github.com/tmichett/Fedora_Remix.git

# Navigate to the project directory
cd Fedora_Remix
```

### Step 4: Fedora release and PXE (`Update_Remix_Config.sh`)

From the **repository root**, run the helper script **instead of manually editing** both config files:

```bash
chmod +x Update_Remix_Config.sh   # once
./Update_Remix_Config.sh
```

**What it configures**

- Root **`config.yml`**: `Container_Properties` — `SSH_Key_Location`, `Fedora_Remix_Location`, `GitHub_Registry_Owner`, `Fedora_Version` (keeps the tree aligned if you use container tools later or share the clone).
- **`Setup/config.yml`**: `fedora_version` (must match `Fedora_Version`), and `include_pxeboot_files`.

When **`include_pxeboot_files`** is **true**, **`Prepare_Web_Files.py`** downloads **PXE/Linux** installer images (`vmlinuz`, `initrd.img`) into the web tree so you can optionally use this host with **httpd** as part of a **network (PXE)** install setup for your Remix. If you answer **no**, the preparer skips those downloads (`include_pxeboot_files: false`).

> **Important:** For some **older** (including EOL) or **very new** Fedora spins, those artifacts may be **missing** or not at the **standard mirror paths** `Prepare_Web_Files.py` uses; enabling PXE assets can cause **prepare or build failure**. If you are **not** using PXE/Linux network boot from this machine, choose **no** and keep `include_pxeboot_files: false`.

**Manual alternative:** edit `sudo vim config.yml` and `sudo vim Setup/config.yml` so `Fedora_Version` and `fedora_version` agree, and set `include_pxeboot_files` explicitly, for example:

```yaml
fedora_version: 43
web_root: "/var/www/html"
include_pxeboot_files: false
```

### Step 5: Prepare the Build Environment

From the `Setup` directory, run the Python scripts in this order (this matches **`Build_Remix_Physical.sh`**):

#### 5a. Prepare Fedora Remix build directory

```bash
cd Setup
sudo python3 Prepare_Fedora_Remix_Build.py
```

**What this does:**
- Creates `/livecd-creator/FedoraRemix`
- Copies kickstart files, `Enhanced_Remix_Build_Script.sh`, and related files
- Copies `Setup/config.yml` to `/livecd-creator/FedoraRemix/config.yml` (used for ISO title / version)

**Expected output (example):**
```
Copying ../Remix_Build_Script.sh to /livecd-creator/FedoraRemix/Remix_Build_Script.sh
Setup complete!
```

#### 5b. Prepare web files and HTTP server

```bash
sudo python3 Prepare_Web_Files.py
```

**What this does:**
- Installs Apache HTTP server (`httpd`)
- Copies files to `/var/www/html/` (including `kickstart.py` and `fs.py` fixes used during the live build)
- If `include_pxeboot_files` is true in `Setup/config.yml`, downloads **PXE/Linux** `vmlinuz` and `initrd.img` for the chosen `fedora_version`; otherwise skips those downloads

**Expected output (example):**
```
Installing packages: httpd
Running command: dnf install -y httpd
...
Setup complete!
```

Always run **5a then 5b** before the enhanced build; the build script looks for patches under `/var/www/html/`.

### Step 6: Customize Your Remix (Optional)

The kickstart files are now located in `/livecd-creator/FedoraRemix/`. Customize them as needed:

#### Customize Packages

Edit the package list to add or remove software:

```bash
sudo vim /livecd-creator/FedoraRemix/FedoraRemixPackages.ks
```

**Add packages:**
```bash
# Add your packages here
vim
tmux
htop
ansible
```

**Remove packages:**
```bash
# Comment out or delete unwanted packages
# firefox  # Removed
```

#### Customize System Configuration

Edit the main kickstart file for system-level customizations:

```bash
sudo vim /livecd-creator/FedoraRemix/FedoraRemix.ks
```

**What you can customize:**
- User accounts and passwords
- Network configuration
- Firewall rules
- SELinux settings
- Post-installation scripts
- Boot loader configuration
- Custom commands and scripts

**Example customizations in FedoraRemix.ks:**
```bash
## Add Fedora Dynamic MotD Script
cd /usr/bin
wget http://localhost/files/fedora-dynamic-motd.sh
chmod +x /usr/bin/fedora-dynamic-motd.sh
echo /usr/bin/fedora-dynamic-motd.sh >> /etc/profile

## Customize BASH Prompts and Shell
mkdir /opt/bash
cd /opt/bash
wget http://localhost/files/bashrc.append
git clone https://github.com/tmichett/bash-git-prompt.git /opt/bash-git-prompt --depth=1
```

### Step 7: Build the ISO

From the build directory, use the **enhanced** script (recommended; same as `Build_Remix_Physical.sh`):

```bash
cd /livecd-creator/FedoraRemix
time sudo ./Enhanced_Remix_Build_Script.sh
```

For a **variant** other than the default, set `REMIX_KICKSTART` to the kickstart base name (no `.ks`), matching the file in this directory, for example:

```bash
sudo env REMIX_KICKSTART=FedoraRemixCosmic ./Enhanced_Remix_Build_Script.sh
```

**Legacy:** `Remix_Build_Script.sh` is the older, simpler script; prefer `Enhanced_Remix_Build_Script.sh` for consistent logging and behavior with the rest of the repo.

**Build Process:**
1. Reads kickstart configuration
2. Downloads and installs packages (~15-20 minutes)
3. Runs post-installation scripts
4. Creates the ISO image (~5-10 minutes)
5. ISO saved in `/livecd-creator/FedoraRemix/` (e.g. `FedoraRemix.iso` or `FedoraRemixCosmic.iso` depending on kickstart)

**Expected output:**
```
fedora                                           19 MB/s |  35 MB     00:01
updates                                         3.8 MB/s | 5.8 MB     00:01
...
Pass 4: Checking reference counts
Pass 5: Checking group summary information
_FedoraRemix: 371986/1324512 files (0.2% non-contiguous), 4248977/5294080 blocks

real    34m41.254s
user    143m42.195s
sys     5m11.054s
```

**Output Location (default kickstart):**

```text
/livecd-creator/FedoraRemix/FedoraRemix.iso
```

(Variant kickstarts produce a matching name, e.g. `FedoraRemixCosmic.iso`.)

---

## Build Directory Structure

After running the setup scripts, your build environment will look like this:

```
/livecd-creator/FedoraRemix/
├── FedoraRemix.ks                 # Main kickstart file
├── FedoraRemixPackages.ks         # Package list
├── FedoraRemixRepos.ks            # Repository configuration
├── config.yml                     # fedora_version (and related) for the enhanced script
├── Enhanced_Remix_Build_Script.sh   # Recommended build driver
├── Remix_Build_Script.sh         # Legacy build script
└── FedoraRemix.iso                # Output ISO (after build; name follows kickstart)
```

---

## Customization Guide

### Package Customization

The `FedoraRemixPackages.ks` file contains all packages to be installed:

```bash
sudo vim /livecd-creator/FedoraRemix/FedoraRemixPackages.ks
```

**Package categories included:**
```bash
## Image Editing and Manipulation
inkscape
gimp
krita
netpbm-progs
scribus

## Video Editing and Manipulation
kdenlive

## Container Tools
buildah
skopeo
podman-machine

## Development Tools
git
vim
code  # VS Code
```

**To add packages:**
- Simply add package names to the appropriate section
- One package per line

**To remove packages:**
- Comment out with `#` or delete the line

### System Configuration Customization

The `FedoraRemix.ks` file controls system configuration:

```bash
sudo vim /livecd-creator/FedoraRemix/FedoraRemix.ks
```

**Common customizations:**

1. **Add custom users:**
   ```bash
   user --name=myuser --groups=wheel --password=encrypted_password --iscrypted
   ```

2. **Configure network:**
   ```bash
   network --bootproto=dhcp --device=eth0 --onboot=yes
   ```

3. **Set timezone:**
   ```bash
   timezone America/New_York --utc
   ```

4. **Configure firewall:**
   ```bash
   firewall --enabled --service=ssh
   ```

5. **Add post-installation scripts:**
   ```bash
   %post
   # Your custom commands here
   echo "Custom setup complete" > /root/setup.log
   %end
   ```

### Repository Configuration

Edit repository sources:

```bash
sudo vim /livecd-creator/FedoraRemix/FedoraRemixRepos.ks
```

**Add custom repositories:**
```bash
repo --name="custom-repo" --baseurl=https://example.com/repo/
```

---

## Troubleshooting

### kickstart.py URLGrabber Error

**Problem:**
```
TypeError: quote() doesn't support 'encoding' for bytes
```

**Solution:**
This is a known issue with newer Fedora releases. The fix is included in the repository:

```bash
# The fix is automatically applied by Prepare_Web_Files.py
# If you encounter this error, ensure you ran the setup scripts
cd ~/Fedora_Remix/Setup
sudo python3 Prepare_Web_Files.py
```

The patched `kickstart.py` file is located in `Setup/files/Fixes/kickstart.py` and is automatically installed to the correct location.

### SELinux Relabeling Errors

**Problem:**
```
setfiles: Could not set context for /usr/share/accountsservice: Invalid argument
Error creating Live CD : SELinux relabel failed.
```

**Solution:**
This is fixed in the latest version. Pull the latest changes:

```bash
cd ~/Fedora_Remix
git pull origin main
cd Setup
sudo python3 Prepare_Web_Files.py
```

See [SELINUX_RELABEL_FIX.md](SELINUX_RELABEL_FIX.md) for details.

### Build Fails with Unmount Errors

**Problem:**
```
Error creating Live CD : Unable to unmount filesystem at /var/tmp/imgcreate-*/install_root/sys
```

**Solution:**
This is fixed in the latest version. Ensure you have the patched `fs.py`:

```bash
cd ~/Fedora_Remix
git pull origin main
cd Setup
sudo python3 Prepare_Web_Files.py
```

See [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) for details.

### Insufficient Disk Space

**Problem:**
```
Error: Not enough free space
```

**Solution:**
- Ensure at least 20 GB free space
- Clean up old builds:
  ```bash
  sudo rm -rf /livecd-creator/FedoraRemix/*.iso
  sudo rm -rf /var/cache/dnf/*
  ```

### HTTP Server Not Running

**Problem:**
Build fails because it can't download files from localhost

**Solution:**
Ensure Apache is running:

```bash
# Check status
sudo systemctl status httpd

# Start if not running
sudo systemctl start httpd

# Enable to start on boot
sudo systemctl enable httpd

# Verify it's serving files
curl http://localhost/
```

---

## Build Output

### Successful Build

**Expected output:**
```
Pass 4: Checking reference counts
Pass 5: Checking group summary information
_FedoraRemix: 371986/1324512 files (0.2% non-contiguous), 4248977/5294080 blocks

real    34m41.254s
user    143m42.195s
sys     5m11.054s
```

### Output Files

**ISO Image:**
```
/livecd-creator/FedoraRemix/FedoraRemix.iso
```

**Build Log:**
```
/livecd-creator/FedoraRemix/FedoraBuild-*.out
```

**Verify the ISO:**
```bash
ls -lh /livecd-creator/FedoraRemix/*.iso
# Expected: ~7-8 GB file
```

---

## Next Steps

### Testing Your ISO

1. **Copy ISO to accessible location:**
   ```bash
   cp /livecd-creator/FedoraRemix/FedoraRemix.iso ~/
   ```

2. **Test in a VM:**
   - Use GNOME Boxes, VirtualBox, or virt-manager
   - Attach the ISO as a CD/DVD
   - Boot from the ISO
   - Test Live environment
   - Test installation

3. **Create Bootable USB:**
   ```bash
   sudo dd if=/livecd-creator/FedoraRemix/FedoraRemix.iso \
           of=/dev/sdX bs=4M status=progress
   ```
   ⚠️ Replace `/dev/sdX` with your USB device.

### Distributing Your ISO

**Options:**
- Upload to file sharing service
- Host on web server
- Distribute via USB drives
- Create torrent for large-scale distribution

---

## Advanced Topics

### Building Different Variants

To build different desktop environments or configurations:

1. **Create a new kickstart file:**
   ```bash
   sudo cp /livecd-creator/FedoraRemix/FedoraRemix.ks \
           /livecd-creator/FedoraRemix/FedoraRemixKDE.ks
   ```

2. **Modify for KDE:**
   ```bash
   sudo vim /livecd-creator/FedoraRemix/FedoraRemixKDE.ks
   # Change desktop environment packages
   ```

3. **Build with new kickstart:**
   ```bash
   cd /livecd-creator/FedoraRemix
   sudo env REMIX_KICKSTART=FedoraRemixKDE ./Enhanced_Remix_Build_Script.sh
   ```
   (Or use the same flags / menu with `Build_Remix_Physical.sh -k FedoraRemixKDE`.)

### Automating Builds

From the repository root, prefer **`Build_Remix_Physical.sh`** (see [Option A](#option-a-one-script-recommended)) so `fedora_version`, prepare scripts, and `Enhanced_Remix_Build_Script.sh` stay aligned. After `git pull`, run it with `-v` and `-k` to skip version and kickstart prompts; you still confirm once before the script updates config and runs prepare plus build.

```bash
cd ~/Fedora_Remix
git pull
./Build_Remix_Physical.sh -v 43 -k FedoraRemix
```

Copy the finished ISO to a web tree if needed:

```bash
cp /livecd-creator/FedoraRemix/*.iso /var/www/html/isos/
```

### Building for Different Fedora Versions

To build for a different Fedora version:

1. **Run `./Update_Remix_Config.sh`** or **set `fedora_version` / `Fedora_Version` in YAML** (or pass `-v 44` to **`Build_Remix_Physical.sh`** when you run it). If you use PXE assets, check that `include_pxeboot_files` still makes sense for that release.

2. **Re-run setup scripts** (or run **`Build_Remix_Physical.sh`** again for a full refresh):
   ```bash
   cd Setup
   sudo python3 Prepare_Fedora_Remix_Build.py
   sudo python3 Prepare_Web_Files.py
   ```

3. **Build as usual** (`Build_Remix_Physical.sh` or `Enhanced_Remix_Build_Script.sh` in `/livecd-creator/FedoraRemix`).

---

## Comparison: Physical vs Container Method

| Feature | Physical/Virtual | Container |
|---------|-----------------|-----------|
| **Setup Time** | Longer (requires full OS install) | Faster (just run container) |
| **Disk Usage** | More (full OS + build tools) | Less (only build environment) |
| **Isolation** | Less (modifies host system) | More (contained environment) |
| **Flexibility** | More control over build system | Standardized environment |
| **Best For** | Dedicated build machines | Quick builds, CI/CD |

**When to use Physical/Virtual method:**
- You want full control over the build environment
- You're building on a dedicated machine
- You need to customize the build system itself
- You're already running Fedora

**When to use Container method:**
- You want quick, reproducible builds
- You're building on different systems
- You want isolation from your host system
- You prefer standardized environments

See [Quickstart_Container.md](Quickstart_Container.md) for the container method.

---

## Additional Resources

### Documentation

- **Asciidoc (PDF / GitHub):** [README_Physical.adoc](README_Physical.adoc) - Physical/virtual install and build narrative (includes *Build_Remix_Physical.sh* and *[Update_Remix_Config.sh](Update_Remix_Config.sh)*)
- **Container Method:** [Quickstart_Container.md](Quickstart_Container.md) - Containerized build guide
- **Main README:** [README.md](README.md) - Project overview
- **Build Fixes:** [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) - Known issues and solutions
- **SELinux Fix:** [SELINUX_RELABEL_FIX.md](SELINUX_RELABEL_FIX.md) - SELinux relabeling fix details
- **Docs folder:** [docs/README.adoc](docs/README.adoc)

### Repository Links

- **Fedora Remix:** https://github.com/tmichett/Fedora_Remix
- **Pre-built ISOs:** https://drive.google.com/drive/folders/1UAT07AJIrTdMk3ke_QE6S6vz-qn6qGtR
- **Documentation Site:** https://tmichett.github.io/Fedora_Remix/

### Getting Help

1. Check the documentation files
2. Review build logs for errors
3. Check GitHub Issues
4. Consult Fedora documentation for kickstart syntax

---

## Summary

**Shortest path (recommended):**

1. Install Fedora Remix (or use Fedora) and ensure sudo works
2. `git clone https://github.com/tmichett/Fedora_Remix.git` and `cd Fedora_Remix`
3. **`./Update_Remix_Config.sh`** to set SSH path, remix directory, **`GitHub_Registry_Owner`** (keep **`tmichett`** for **`ghcr.io/tmichett/...`**), Fedora release, and PXE (recommended; use **no** for PXE if you only need a local ISO)
4. `./Build_Remix_Physical.sh` (set version if not already done, pick kickstart, confirm; script runs prepare + `Enhanced_Remix_Build_Script.sh`)
5. Find the ISO under `/livecd-creator/FedoraRemix/` (e.g. `FedoraRemix.iso`)

**Manual equivalent:** Run **`Update_Remix_Config.sh`** (or edit root `config.yml` and `Setup/config.yml` manually), then run `cd Setup && sudo python3 Prepare_Fedora_Remix_Build.py` then `sudo python3 Prepare_Web_Files.py`, customize kickstarts under `/livecd-creator/FedoraRemix/` if needed, then `cd /livecd-creator/FedoraRemix && sudo ./Enhanced_Remix_Build_Script.sh` (or `sudo env REMIX_KICKSTART=… ./Enhanced_Remix_Build_Script.sh` for a variant).

**That's it!** You now have a custom Fedora Remix ISO built on your physical or virtual machine.

---

**Last Updated:** April 28, 2026  
**Version:** 1.2