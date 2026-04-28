# Fedora Remix Builder - Physical/Virtual Machine Quickstart Guide

**Last Updated:** April 27, 2026  
**Purpose:** Quick guide to building a custom Fedora Remix ISO on a physical or virtual machine (non-containerized method), led by **`Build_Remix_Physical.sh`**

---

## Overview

This guide will walk you through building a custom Fedora Remix ISO image directly on a physical machine or virtual machine without using containers. This method installs the Fedora Remix build environment directly on your system.

**Build Time:** Approximately 30-45 minutes  
**Output:** A bootable Fedora Remix ISO file (~7-8 GB)

> **💡 Looking for the containerized method?** See **[Quickstart_Container.md](Quickstart_Container.md)** for building with containers (Podman), or use **[Build_Remix.sh](Build_Remix.sh)** to drive the builder image.

**Recommended (native build):** From the repository root, run **[`Build_Remix_Physical.sh`](Build_Remix_Physical.sh)**. It updates `Setup/config.yml` (`fedora_version`), runs `Setup/Prepare_Fedora_Remix_Build.py` and `Setup/Prepare_Web_Files.py` in the correct order, then runs **[`Setup/Enhanced_Remix_Build_Script.sh`](Setup/Enhanced_Remix_Build_Script.sh)** in `/livecd-creator/FedoraRemix` with the kickstart you choose. Use `./Build_Remix_Physical.sh -h` for options (`-v` release, `-k` kickstart, `-l` list).

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

1. Ask for the Fedora release (e.g. `43`) and write it to `Setup/config.yml` as `fedora_version`
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

### Option B: Manual steps (7 steps)

The steps below match what `Build_Remix_Physical.sh` automates, if you prefer to run each command yourself. Prepare order is: **build directory** first, then **web files and patches** (so `/var/www/html` has `kickstart.py` / `fs.py` fixes before `Enhanced_Remix_Build_Script.sh` runs).

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

### Step 4: Prepare the Build Environment

From the `Setup` directory, run the Python scripts in this order (this matches **`Build_Remix_Physical.sh`**):

#### 4a. Prepare Fedora Remix build directory

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

#### 4b. Prepare web files and HTTP server

```bash
sudo python3 Prepare_Web_Files.py
```

**What this does:**
- Installs Apache HTTP server (`httpd`)
- Copies files to `/var/www/html/` (including `kickstart.py` and `fs.py` fixes used during the live build)
- Sets up PXE/boot assets and related web content

**Expected output (example):**
```
Installing packages: httpd
Running command: dnf install -y httpd
...
Setup complete!
```

Always run **4a then 4b** before the enhanced build; the build script looks for patches under `/var/www/html/`.

### Step 5: Configure Fedora Version

Edit the configuration file to set your Fedora version:

```bash
sudo vim Setup/config.yml
```

**Set the Fedora version:**
```yaml
# Fedora version to use for downloading boot files
fedora_version: 43

# Web root directory where files will be served
web_root: "/var/www/html"
```

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

1. **Set `fedora_version` in `Setup/config.yml`** (or pass `-v 44` to **`Build_Remix_Physical.sh`** when you run it).

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

- **Asciidoc (PDF / GitHub):** [README_Physical.adoc](README_Physical.adoc) - Physical/virtual install and build narrative (includes *Build_Remix_Physical.sh*)
- **Container Method:** [Quickstart_Container.md](Quickstart_Container.md) - Containerized build guide
- **Main README:** [README.md](README.md) - Project overview
- **Build Fixes:** [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) - Known issues and solutions
- **SELinux Fix:** [SELINUX_RELABEL_FIX.md](SELINUX_RELABEL_FIX.md) - SELinux relabeling fix details
- **Extended Docs:** [README.adoc](README.adoc) - Detailed documentation

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
3. `./Build_Remix_Physical.sh` (set version, pick kickstart, confirm; script runs prepare + `Enhanced_Remix_Build_Script.sh`)
4. Find the ISO under `/livecd-creator/FedoraRemix/` (e.g. `FedoraRemix.iso`)

**Manual equivalent:** Edit `Setup/config.yml` (`fedora_version`), run `cd Setup && sudo python3 Prepare_Fedora_Remix_Build.py` then `sudo python3 Prepare_Web_Files.py`, customize kickstarts under `/livecd-creator/FedoraRemix/` if needed, then `cd /livecd-creator/FedoraRemix && sudo ./Enhanced_Remix_Build_Script.sh` (or `sudo env REMIX_KICKSTART=… ./Enhanced_Remix_Build_Script.sh` for a variant).

**That's it!** You now have a custom Fedora Remix ISO built on your physical or virtual machine.

---

**Last Updated:** April 27, 2026  
**Version:** 1.1