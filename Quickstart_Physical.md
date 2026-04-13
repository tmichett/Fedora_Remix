# Fedora Remix Builder - Physical/Virtual Machine Quickstart Guide

**Last Updated:** April 13, 2026  
**Purpose:** Quick guide to building a custom Fedora Remix ISO on a physical or virtual machine (non-containerized method)

---

## Overview

This guide will walk you through building a custom Fedora Remix ISO image directly on a physical machine or virtual machine without using containers. This method installs the Fedora Remix build environment directly on your system.

**Build Time:** Approximately 30-45 minutes  
**Output:** A bootable Fedora Remix ISO file (~7-8 GB)

> **💡 Looking for the containerized method?** See **[Quickstart_Container.md](Quickstart_Container.md)** for building with containers (recommended for most users).

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

## Quick Start (7 Steps)

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

Run the Python automation scripts to set up the build environment:

#### 4a. Prepare Web Files and HTTP Server

```bash
cd Setup
sudo python3 Prepare_Web_Files.py
```

**What this does:**
- Installs Apache HTTP server (`httpd`)
- Copies necessary files to `/var/www/html/`
- Sets up local repository assets
- Configures the web server for the build process

**Expected output:**
```
Installing packages: httpd
Running command: dnf install -y httpd
...
Setup complete!
```

#### 4b. Prepare Fedora Remix Build Directory

```bash
sudo python3 Prepare_Fedora_Remix_Build.py
```

**What this does:**
- Creates `/livecd-creator/FedoraRemix` directory
- Copies kickstart files to the build directory
- Copies build scripts
- Sets up the build environment

**Expected output:**
```
Copying ../Remix_Build_Script.sh to /livecd-creator/FedoraRemix/Remix_Build_Script.sh
Setup complete!
```

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

Navigate to the build directory and run the build script:

```bash
cd /livecd-creator/FedoraRemix
time sudo ./Remix_Build_Script.sh
```

**Build Process:**
1. Reads kickstart configuration
2. Downloads and installs packages (~15-20 minutes)
3. Runs post-installation scripts
4. Creates the ISO image (~5-10 minutes)
5. ISO saved to `/livecd-creator/FedoraRemix/`

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

**Output Location:**
```
/livecd-creator/FedoraRemix/FedoraRemix.iso
```

---

## Build Directory Structure

After running the setup scripts, your build environment will look like this:

```
/livecd-creator/FedoraRemix/
├── FedoraRemix.ks              # Main kickstart file
├── FedoraRemixPackages.ks      # Package list
├── FedoraRemixRepos.ks         # Repository configuration
├── Remix_Build_Script.sh       # Build script
└── FedoraRemix.iso            # Output ISO (after build)
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
   sudo livecd-creator -c FedoraRemixKDE.ks -f FedoraRemixKDE
   ```

### Automating Builds

Create a build automation script:

```bash
#!/bin/bash
# automated-build.sh

cd ~/Fedora_Remix
git pull

cd Setup
sudo python3 Prepare_Web_Files.py
sudo python3 Prepare_Fedora_Remix_Build.py

cd /livecd-creator/FedoraRemix
time sudo ./Remix_Build_Script.sh

# Copy ISO to distribution directory
cp /livecd-creator/FedoraRemix/*.iso /var/www/html/isos/
```

### Building for Different Fedora Versions

To build for a different Fedora version:

1. **Update configuration:**
   ```bash
   sudo vim Setup/config.yml
   # Change: fedora_version: 44
   ```

2. **Re-run setup scripts:**
   ```bash
   cd Setup
   sudo python3 Prepare_Web_Files.py
   sudo python3 Prepare_Fedora_Remix_Build.py
   ```

3. **Build as normal**

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

**Minimum Steps to Build:**

1. Install Fedora Remix or use existing Fedora installation
2. Clone repository: `git clone https://github.com/tmichett/Fedora_Remix.git`
3. Run setup scripts:
   - `sudo python3 Setup/Prepare_Web_Files.py`
   - `sudo python3 Setup/Prepare_Fedora_Remix_Build.py`
4. Edit `Setup/config.yml` - Set Fedora version
5. Customize kickstart files (optional):
   - `/livecd-creator/FedoraRemix/FedoraRemixPackages.ks` - Packages
   - `/livecd-creator/FedoraRemix/FedoraRemix.ks` - System config
6. Build: `cd /livecd-creator/FedoraRemix && sudo ./Remix_Build_Script.sh`
7. Wait 30-45 minutes
8. Find ISO at `/livecd-creator/FedoraRemix/FedoraRemix.iso`

**That's it!** You now have a custom Fedora Remix ISO built on your physical or virtual machine.

---

**Last Updated:** April 13, 2026  
**Version:** 1.0