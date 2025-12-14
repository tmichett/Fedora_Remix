# Maintained by Travis Michette:
# https://github.com/tmichett/Fedora_Remix



# Fedora Remix Base Kickstart packages - Maintained by Fedora Project
%include fedora-live-base.ks
%include fedora-workstation-common.ks
#
# Disable this for now as packagekit is causing compose failures
# by leaving a gpg-agent around holding /dev/null open.
#

#include snippets/packagekit-cached-metadata.ks
%include FedoraRemixPackages.ks

#network --device=link --bootproto=static --ip=192.168.15.15 --netmask=255.255.255.0 --gateway=192.168.15.1 --nameserver=192.168.15.1

# This is set in the fedora-live-base.ks file
# part / --size 30680  



%post --nochroot
# Set proper PATH for nochroot environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Ensure UTF-8 locale settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#if [ ! -e /mnt/sysimage/etc/resolf.conf ]; then
#  cp -P /etc/resolv.conf $INSTALL_ROOT/etc/resolv.conf
#fi
#%post --nochroot
#cp -P /etc/resolv.conf "$INSTALL_ROOT"/etc/resolv.conf
set -x
%include KickstartSnippets/install-ansible.ks

%end


### Fix ISOLinux

%post --nochroot
# Ensure UTF-8 locale settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

set -x
touch "$LIVE_ROOT/isolinux/travis"

%end


%post

# Set proper PATH to prevent mandb warnings and ensure all tools are available
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Ensure UTF-8 locale settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Include formatting functions first for consistent output
%include KickstartSnippets/format-functions.ks

set -x

# Read version from config.yml if available (early definition for use throughout script)
if [ -f "/var/www/html/Setup/config.yml" ]; then
    FEDORA_VERSION=$(grep '^fedora_version:' /var/www/html/Setup/config.yml | awk '{print $2}' | tr -d '"')
elif [ -f "/opt/FedoraRemix/config.yml" ]; then
    FEDORA_VERSION=$(grep '^fedora_version:' /opt/FedoraRemix/config.yml | awk '{print $2}' | tr -d '"')
else
    FEDORA_VERSION="43"  # fallback default
fi

## Echo Start time to screen
ks_print_header "🚀 TRAVIS'S FEDORA REMIX ${FEDORA_VERSION} BUILD STARTED"
ks_print_info "Build initiated at $(date)"

# Create separate live system customization script instead of modifying livesys
ks_print_info "Creating Fedora Remix live system customizations"

# Create our own customization script that runs after livesys
cat > /etc/rc.d/init.d/fedora-remix-live << 'EOF'
#!/bin/bash
#
# fedora-remix-live: Fedora Remix specific live system customizations
#
# chkconfig: 345 01 99
# description: Fedora Remix live system customizations
### BEGIN INIT INFO
# X-Start-After: livesys
### END INIT INFO

. /etc/init.d/functions

if ! strstr "`cat /proc/cmdline`" rd.live.image || [ "$1" != "start" ]; then
    exit 0
fi

if [ -e /.fedora-remix-configured ] ; then
    exit 0
fi

exists() {
    which $1 >/dev/null 2>&1 || return
    $*
}

# disable gnome-software automatically downloading updates
cat >> /usr/share/glib-2.0/schemas/org.gnome.software.gschema.override << 'FOE'
[org.gnome.software]
download-updates=false
FOE

# don't autostart gnome-software session service
rm -f /etc/xdg/autostart/gnome-software-service.desktop

# disable the gnome-software shell search provider
cat >> /usr/share/gnome-shell/search-providers/org.gnome.Software-search-provider.ini << 'FOE'
DefaultDisabled=true
FOE

# suppress anaconda spokes redundant with gnome-initial-setup
cat >> /etc/sysconfig/anaconda << 'FOE'
[NetworkSpoke]
visited=1

[PasswordSpoke]
visited=1

[UserSpoke]
visited=1
FOE

# make the installer show up
if [ -f /usr/share/applications/liveinst.desktop ]; then
  # Show harddisk install in shell dash
  sed -i -e 's/NoDisplay=true/NoDisplay=false/' /usr/share/applications/liveinst.desktop
  # need to move it to anaconda.desktop to make shell happy
  mv /usr/share/applications/liveinst.desktop /usr/share/applications/anaconda.desktop

  cat >> /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override << 'FOE'
[org.gnome.shell]
favorite-apps=['firefox.desktop', 'org.gnome.Calendar.desktop', 'rhythmbox.desktop', 'org.gnome.Photos.desktop', 'org.gnome.Nautilus.desktop', 'anaconda.desktop']
FOE

  # Make the welcome screen show up
  if [ -f /usr/share/anaconda/gnome/fedora-welcome.desktop ]; then
    mkdir -p ~liveuser/.config/autostart
    cp /usr/share/anaconda/gnome/fedora-welcome.desktop /usr/share/applications/
    cp /usr/share/anaconda/gnome/fedora-welcome.desktop ~liveuser/.config/autostart/
  fi

  # Disable GNOME welcome tour so it doesn't overlap with Fedora welcome screen
  cat >> /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override << 'FOE'
welcome-dialog-last-shown-version='4294967295'
FOE

  # Copy Anaconda branding in place
  if [ -d /usr/share/lorax/product/usr/share/anaconda ]; then
    cp -a /usr/share/lorax/product/* /
  fi
fi

# rebuild schema cache with any overrides we installed
glib-compile-schemas /usr/share/glib-2.0/schemas

# set up auto-login
cat > /etc/gdm/custom.conf << 'FOE'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=liveuser
FOE

# Turn off PackageKit-command-not-found while uninstalled
if [ -f /etc/PackageKit/CommandNotFound.conf ]; then
  sed -i -e 's/^SoftwareSourceSearch=true/SoftwareSourceSearch=false/' /etc/PackageKit/CommandNotFound.conf
fi

# Mark as configured
touch /.fedora-remix-configured

EOF

# Make the script executable and enable it
chmod 755 /etc/rc.d/init.d/fedora-remix-live
/sbin/restorecon /etc/rc.d/init.d/fedora-remix-live
/sbin/chkconfig --add fedora-remix-live

# Ensure liveuser home directory is properly set up later
ks_print_info "Live system customization script created and enabled"

# Add liveuser home directory setup to our custom script
cat >> /etc/rc.d/init.d/fedora-remix-live << 'EOF'

# don't run gnome-initial-setup for liveuser
if [ -d /home/liveuser ]; then
    mkdir -p /home/liveuser/.config
    touch /home/liveuser/.config/gnome-initial-setup-done
    chown -R liveuser:liveuser /home/liveuser/
    restorecon -R /home/liveuser/ 2>/dev/null || true
fi

EOF

### Update PATH
echo -e "${GREEN}Adding /usr/local/bin to the PATH... ${NC}"
echo 'export PATH=/usr/local/bin:$PATH' >> /etc/skel/.bashrc

### Download Logos 

ks_print_section "🖼️ DOWNLOADING FEDORA REMIX LOGOS & BRANDING"
ks_print_info "Downloading logos, themes, and branding assets"

wget -O /usr/share/pixmaps/login-logo.png http://localhost/files/fedorap_small.png

wget -O /etc/dconf/db/gdm.d/01-logo http://localhost/files/01-logo

wget -O /etc/dconf/db/gdm.d/01-banner-message http://localhost/files/01-banner-message

wget -O /etc/dconf/profile/gdm http://localhost/files/gdm_config

wget -O /usr/share/pixmaps/bootloader/bootlogo_128.png http://localhost/files/bootlogo_128.png

wget -O /usr/share/pixmaps/bootloader/bootlogo_256.png http://localhost/files/bootlogo_256.png

wget -O /usr/share/anaconda/boot/splash.png http://localhost/tm-fedora-remix/logo.png

wget -O /etc/dconf/db/gdm.d/01-background http://localhost/files/01-background

wget -O /etc/dconf/db/gdm.d/01-disable-power-save http://localhost/files/01-disable-power-save

wget -O /etc/dconf/db/local.d/01-disable-power-save http://localhost/files/01-disable-power-save

wget -O /etc/dconf/db/local.d/01-enabled-extensions http://localhost/files/01-enabled-extensions

wget -O /etc/dconf/db/local.d/01-wallpaper-logo http://localhost/files/01-wallpaper-logo

dconf update

wget -P /usr/share/plymouth/themes/ -r -nH -np -R "index.htm*" http://localhost/tm-fedora-remix/

cp /usr/share/plymouth/themes/tm-fedora-remix/watermark.* /usr/share/plymouth/themes/spinner/

cp /usr/share/plymouth/themes/tm-fedora-remix/logo.* /usr/share/plymouth/themes/spinner/

## Setting up Customization Pieces

ks_print_section "🛠️ SETTING UP CUSTOMIZATION COMPONENTS"
ks_print_info "Downloading customization tools and configurations"

wget -P /opt -r -nH -np --reject-regex "index\\.html?.*" http://localhost/FedoraRemixCustomize
wget -P /opt -r -nH -np --reject-regex "index\\.html?.*" http://localhost/FedoraRemixPXE
wget -P /opt -r -nH -np --reject-regex "index\\.html?.*" http://localhost/PXEServer

## Setting Theme

ks_print_section "🎨 CONFIGURING FEDORA REMIX THEME"
ks_print_info "Setting Plymouth boot theme to tm-fedora-remix"

/usr/sbin/plymouth-set-default-theme tm-fedora-remix -R

echo "=== Configuring dracut for live boot support ==="

# Create dracut configuration to ensure livenet modules are always included
# Note: curl and wget should already be available from base packages
mkdir -p /etc/dracut.conf.d
cat > /etc/dracut.conf.d/02-livenet.conf << 'EOF'
# Ensure livenet and related modules are included for live boot
add_dracutmodules+=" livenet network-legacy dmsquash-live url-lib "
install_items+=" /usr/bin/curl /usr/bin/wget /usr/bin/getopt "
# Force include networking tools and dependencies
install_optional_items+=" /usr/bin/ping /usr/bin/dig /lib*/libnss_dns.so.* "
# Include essential libraries for URL handling
install_optional_items+=" /lib*/libcurl.so.* /lib*/libssl.so.* /lib*/libcrypto.so.* "
EOF

echo "=== Creating livenet URL handler functions ==="
# Create a backup URL handler in case the dracut one fails
cat > /usr/lib/dracut/modules.d/99local-url-handler/module-setup.sh << 'EOF'
#!/bin/bash

check() {
    return 0
}

depends() {
    echo livenet
    return 0
}

install() {
    inst_simple "$moddir/get_url_handler.sh" "/lib/get_url_handler"
    inst_multiple curl wget
}
EOF

mkdir -p /usr/lib/dracut/modules.d/99local-url-handler
cat > /usr/lib/dracut/modules.d/99local-url-handler/get_url_handler.sh << 'EOF'
#!/bin/bash
# Backup URL handler function for livenet

get_url_handler() {
    local url="$1"
    local target="$2"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$target" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$target" "$url"
    else
        return 1
    fi
}
EOF

chmod +x /usr/lib/dracut/modules.d/99local-url-handler/module-setup.sh
chmod +x /usr/lib/dracut/modules.d/99local-url-handler/get_url_handler.sh

echo "=== Regenerating initramfs with live boot support ==="
# Regenerate initramfs with proper modules for live boot functionality
# The configuration file will ensure livenet modules are included
if [ -f /boot/vmlinuz-$(uname -r) ]; then
    echo "Building initramfs for kernel $(uname -r)"
    dracut -f --force /boot/initramfs-$(uname -r).img $(uname -r)
    # Verify the modules were included
    if lsinitrd /boot/initramfs-$(uname -r).img | grep -q livenet; then
        echo "SUCCESS: Livenet modules successfully included in initramfs"
    else
        echo "WARNING: Livenet modules may not be included - trying alternative approach"
        dracut -f -a "livenet network-legacy dmsquash-live" --install "curl wget" /boot/initramfs-$(uname -r).img $(uname -r)
    fi
else
    echo "WARNING: Kernel not found, regenerating all initramfs images"
    dracut -f --regenerate-all
fi


## Fix Networking

ks_print_section "🌐 NETWORK & DNS CONFIGURATION"
ks_print_info "Configuring DNS servers and network settings"
echo "nameserver 8.8.8.8" > /etc/resolv.conf
/usr/bin/mkdir /FedoraRemix
cat /etc/resolv.conf > /FedoraRemix/DNS.txt
/usr/sbin/ip a >> /FedoraRemix/DNS.txt

#/usr/bin/systemd-resolve --status >> /FedoraRemix/DNS.txt
#/usr/bin/resolvectl  >> /FedoraRemix/DNS.txt
#/usr/bin/resolvectl

#echo "Restarting Network Manager" 

#systemctl restart NetworkManager

#/usr/bin/nmcli con show

## Ansible installation handled by KickstartSnippets/install-ansible.ks in %post --nochroot section
## Duplicate installation removed to improve performance
#wget -P /opt/ -r -nH -np -R "index.htm*" http://localhost/pip_packages/
#wget -P /opt/ http://localhost/files/python_packages.txt
#cd /opt/pip_packages
#/usr/bin/pip3 install -r /opt/python_packages.txt


## Enable WiFi Support for PXE Boot Clients
%include KickstartSnippets/enable-wifi-pxeboot.ks

## Install Flatpaks
%include KickstartSnippets/install-flatpaks.ks

## Install Balena Etcher
%include KickstartSnippets/install-balena-etcher.ks

## Customize Anaconda Installer
%include KickstartSnippets/customize-anaconda.ks

## Customize Gnome Wallpaper for FC42
%include KickstartSnippets/customize-gnome-wallpaper.ks

## Customize Grub Boot Menu
%include KickstartSnippets/customize-grub.ks

## Create VSCode Extension Directory
%include KickstartSnippets/setup-vscode-extensions.ks

## Add Fedora Dynamic MotD Script
%include KickstartSnippets/setup-dynamic-motd.ks

## Customize BASH Prompts and Shell 
%include KickstartSnippets/customize-bash-shell.ks

### Removal of network fix
#rm /etc/resolv.conf

## Setting up Firstboot
%include KickstartSnippets/setup-firstboot.ks

## Enable Cockpit and SSHD
ks_print_section "🔧 SYSTEM SERVICES ACTIVATION"
ks_print_info "Enabling Cockpit web console and SSH daemon"
systemctl enable cockpit.socket
systemctl enable sshd.service

## Enable YAD Scripts and Looks
%include KickstartSnippets/setup-yad-scripts.ks

## Install Gnome-Tweaks and Prepare Packages
%include KickstartSnippets/install-gnome-tweaks.ks

## Create Ansible-User with Password and Add to Sudoers
%include KickstartSnippets/create-ansible-user.ks

## Download and Install Calibre
%include KickstartSnippets/install-calibre.ks

## Attempt to Install Gnome Extensions and Setup Desktop Icons
%include KickstartSnippets/setup-gnome-extensions.ks
%include KickstartSnippets/setup-desktop-icons.ks

## Install UDP Cast 
%include KickstartSnippets/install-udpcast.ks

## Install OhMyBash
%include KickstartSnippets/install-ohmybash.ks

## Set BASHRC Defaults
%include KickstartSnippets/set-bash-defaults.ks

## Install Podman BootC from Repo
%include KickstartSnippets/install-podman-bootc.ks

## Update to Latest Packages
ks_print_section "📦 SYSTEM UPDATES & MAINTENANCE"
ks_print_info "Updating all packages to latest versions"
dnf update -y

## Ensure anaconda-webui is updated to fix locale-id bug (rhinstaller/anaconda-webui commit 82438d4)
ks_print_info "Ensuring anaconda-webui has the locale-id fix"
dnf update -y anaconda-webui anaconda anaconda-live

## Update Ansible Collections
%include KickstartSnippets/update-ansible-collections.ks

## Create FedoraRemix Custom Tools (LMStudio)
%include KickstartSnippets/install-lmstudio.ks

## Create TMUX Config Directory
%include KickstartSnippets/setup-tmux.ks

## Install VeraCrypt
%include KickstartSnippets/install-veracrypt.ks

## Install and Configure Mutagen
%include KickstartSnippets/install-mutagen.ks

## Install Cursor
%include KickstartSnippets/install-cursor.ks

## Clean up man page database to prevent warnings
ks_print_section "📚 DOCUMENTATION CLEANUP"
ks_print_info "Updating man page database and cleaning up warnings"

# Ensure proper environment for mandb
export MANPATH=/usr/share/man:/usr/local/share/man

# Regenerate man database with proper error handling (English only for performance)
if command -v mandb >/dev/null 2>&1; then
    ks_print_info "Regenerating man page database (English only)"
    # Process only English man pages to reduce build time and avoid locale-specific warnings
    export LC_ALL=C
    mandb -c /usr/share/man 2>/dev/null || ks_print_warning "Some man pages may have formatting issues (non-critical)"
    # Restore UTF-8 locale
    export LC_ALL=en_US.UTF-8
else
    ks_print_warning "mandb command not found, skipping man page database update"
fi

## Put information in /etc regarding Fedora Remix Versions
date "+This version of Fedora Remix ${FEDORA_VERSION} was created on %B %d, %Y" > /etc/fedora_remix_release

## Echo Finish time to screen
ks_print_header "🎉 TRAVIS'S FEDORA REMIX ${FEDORA_VERSION} BUILD COMPLETED!"
ks_print_success "Build completed successfully at $(date)"

ks_print_header "🔥 STARTING ISO CREATION PROCESS"
ks_print_info "Preparing to build final ISO image"

# Write timestamp for ISO creation start (used by Enhanced build script for timing)
echo $(date +%s) > /tmp/iso_creation_start_time.txt
%end