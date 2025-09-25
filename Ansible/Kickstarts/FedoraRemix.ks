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

part / --size 30680



%post --nochroot
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
set -x
touch "$LIVE_ROOT/isolinx/travis"

%end


%post

## Echo Start time to screen
print_banner "🚀 TRAVIS'S FEDORA REMIX 42 BUILD STARTED" "$PURPLE"
print_step "Build initiated at $(date)" "$CYAN"

set -x

# Include formatting functions first for consistent output
%include KickstartSnippets/format-functions.ks

cat >> /etc/rc.d/init.d/livesys << EOF


# disable gnome-software automatically downloading updates
cat >> /usr/share/glib-2.0/schemas/org.gnome.software.gschema.override << FOE
[org.gnome.software]
download-updates=false
FOE

# don't autostart gnome-software session service
rm -f /etc/xdg/autostart/gnome-software-service.desktop

# disable the gnome-software shell search provider
cat >> /usr/share/gnome-shell/search-providers/org.gnome.Software-search-provider.ini << FOE
DefaultDisabled=true
FOE

# don't run gnome-initial-setup
mkdir ~liveuser/.config
touch ~liveuser/.config/gnome-initial-setup-done

# suppress anaconda spokes redundant with gnome-initial-setup
cat >> /etc/sysconfig/anaconda << FOE
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
  sed -i -e 's/NoDisplay=true/NoDisplay=false/' /usr/share/applications/liveinst.desktop ""
  # need to move it to anaconda.desktop to make shell happy
  mv /usr/share/applications/liveinst.desktop /usr/share/applications/anaconda.desktop

  cat >> /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override << FOE
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
  cat >> /usr/share/glib-2.0/schemas/org.gnome.shell.gschema.override << FOE
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
cat > /etc/gdm/custom.conf << FOE
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=liveuser
FOE

# Turn off PackageKit-command-not-found while uninstalled
if [ -f /etc/PackageKit/CommandNotFound.conf ]; then
  sed -i -e 's/^SoftwareSourceSearch=true/SoftwareSourceSearch=false/' /etc/PackageKit/CommandNotFound.conf
fi

# make sure to set the right permissions and selinux contexts
chown -R liveuser:liveuser /home/liveuser/
/usr/sbin/restorecon-R /home/liveuser/

EOF

### Update PATH
echo -e "${GREEN}Adding /usr/local/bin to the PATH... ${NC}"
echo 'export PATH=/usr/local/bin:$PATH' >> /etc/skel/.bashrc

### Download Logos 

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
wget -P /opt -r -nH -np --reject-regex "index\\.html?.*" http://localhost/FedoraRemixCustomize
wget -P /opt -r -nH -np --reject-regex "index\\.html?.*" http://localhost/FedoraRemixPXE
wget -P /opt -r -nH -np --reject-regex "index\\.html?.*" http://localhost/PXEServer

## Setting Theme

print_banner "🎨 CONFIGURING FEDORA REMIX THEME" "$PURPLE"
print_step "Setting Plymouth boot theme to tm-fedora-remix"

/usr/sbin/plymouth-set-default-theme tm-fedora-remix -R

dracut -f --no-kernel


## Fix Networking

print_banner "🌐 NETWORK & DNS CONFIGURATION" "$BLUE"
print_step "Configuring DNS servers and network settings"
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
print_banner "🔧 SYSTEM SERVICES ACTIVATION" "$GREEN"
print_step "Enabling Cockpit web console and SSH daemon"
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
print_banner "📦 SYSTEM UPDATES & MAINTENANCE" "$YELLOW"
print_step "Updating all packages to latest versions"
dnf update -y

## Update Ansible Collections
%include KickstartSnippets/update-ansible-collections.ks

## Create FedoraRemix Custom Tools (LMStudio)
%include KickstartSnippets/install-lmstudio.ks

## Install LogViewer
%include KickstartSnippets/install-logviewer.ks

## Create TMUX Config Directory
%include KickstartSnippets/setup-tmux.ks

## Install VeraCrypt
%include KickstartSnippets/install-veracrypt.ks

## Install and Configure Mutagen
%include KickstartSnippets/install-mutagen.ks

## Install Cursor
%include KickstartSnippets/install-cursor.ks

## Put information in /etc regarding Fedora Remix Versions
date "+This version of Fedora Remix 42 was created on %B %d, %Y" > /etc/fedora_remix_release

## Echo Finish time to screen
print_banner "🎉 TRAVIS'S FEDORA REMIX 42 BUILD COMPLETED!" "$GREEN"
print_step "Build completed successfully at $(date)" "$GREEN"

print_banner "🔥 STARTING ISO CREATION PROCESS" "$YELLOW"
print_step "Preparing to build final ISO image" "$YELLOW"
%end