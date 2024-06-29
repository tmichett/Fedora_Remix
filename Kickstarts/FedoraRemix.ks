# Maintained by the Fedora Workstation WG:
# http://fedoraproject.org/wiki/Workstation
# mailto:desktop@lists.fedoraproject.org

%include fedora-live-base.ks
%include fedora-workstation-common.ks
#
# Disable this for now as packagekit is causing compose failures
# by leaving a gpg-agent around holding /dev/null open.
#
#include snippets/packagekit-cached-metadata.ks
%include FedoraRemixPackages.ks

#network --device=link --bootproto=static --ip=192.168.15.15 --netmask=255.255.255.0 --gateway=192.168.15.1 --nameserver=192.168.15.1

part / --size 20680



%post --nochroot
#if [ ! -e /mnt/sysimage/etc/resolf.conf ]; then
#  cp -P /etc/resolv.conf $INSTALL_ROOT/etc/resolv.conf
#fi
#%post --nochroot
#cp -P /etc/resolv.conf "$INSTALL_ROOT"/etc/resolv.conf
/usr/bin/pip install ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools ## Issues with ansible-cdk# (issues with DNS in Post)

## Install Flatpaks
#/usr/bin/flatpak install flathub com.slack.Slack -y
#/usr/bin/flatpak install flathub us.zoom.Zoom -y

%end


### Fix ISOLinux

%post --nochroot
touch "$LIVE_ROOT/isolinx/travis"

%end


%post
### Fix added for DNS and Network fixes in Post
### https://anaconda-installer.readthedocs.io/en/latest/common-bugs.html#missing-etc-resolv-conf-for-post-scripts

#echo "nameserver 8.8.8.8" >> /etc/resolv.conf

#echo "nameserver 8.8.8.8" >> $INSTALL_ROOT/etc/resolv.conf

#/usr/bin/systemctl restart NetworkManager

#/usr/bin/systemd-resolve --set-dns=192.168.15.1 --interface=eth0

# network --device=link --bootproto=static --ip=192.168.15.15 --netmask=255.255.255.0 --gateway=192.168.15.1 --nameserver=192.168.15.1


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
restorecon -R /home/liveuser/

EOF

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
wget -P /opt -r -nH -np -R "index.htm*" http://localhost/FedoraRemixCustomize
wget -P /opt -r -nH -np -R "index.htm*" http://localhost/FedoraRemixPXE
wget -P /opt -r -nH -np -R "index.htm*" http://localhost/PXEServer

## Setting Theme

echo "Setting Fedora Theme"

/usr/sbin/plymouth-set-default-theme tm-fedora-remix -R

dracut -f --no-kernel


## Fix Networking

echo "Attempting to setup DNS and configure networking"
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


## Setup and Install Ansible and Ansible Navigator
/usr/bin/pip install ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools ## ansible-cdk # (issues with DNS in Post)
#wget -P /opt/ -r -nH -np -R "index.htm*" http://localhost/pip_packages/
#wget -P /opt/ http://localhost/files/python_packages.txt
#cd /opt/pip_packages
#/usr/bin/pip3 install -r /opt/python_packages.txt



## Install Flatpaks
echo "Attempting to install flatpaks"
/usr/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# /usr/bin/flatpak install flathub com.slack.Slack -y
# /usr/bin/flatpak install flathub us.zoom.Zoom -y


## Install Balena Etcher
yum -y localinstall https://github.com/balena-io/etcher/releases/download/v1.18.11/balena-etcher-1.18.11.x86_64.rpm

## Customize Anaconda Installer

echo "Customizing Anaconda"

cd /usr/share/anaconda/pixmaps
rm sidebar-logo.png
rm anaconda_header.png
wget  http://localhost/files/boot/sidebar-logo.png
wget  http://localhost/files/boot/anaconda_header.png
cd /usr/share/anaconda/pixmaps/workstation/
rm sidebar-logo.png
wget  http://localhost/files/boot/sidebar-logo.png

cd /usr/share/anaconda/boot
rm splash.lss
wget  http://localhost/files/boot/splash.lss


## Customize Logos - General
cd /usr/share/pixmaps/
rm fedora-logo*.png
rm fedora_logo_med.png
wget http://localhost/files/logos/fedora-logo-small.png
wget http://localhost/files/logos/fedora-logo.png
wget http://localhost/files/logos/fedora_logo_med.png

cd /usr/share/fedora-logos/
rm fedora*.svg
wget http://localhost/files/logos/fedora_logo.svg
wget http://localhost/files/logos/fedora_logo_darkbackground.svg
wget http://localhost/files/logos/fedora_lightbackground.svg 
wget http://localhost/files/logos/fedora_darkbackground.svg

## Customize Gnome Wallpaper
mkdir -p /usr/share/backgrounds/f40/default/
cd /usr/share/backgrounds/f40/default/
rm *.png
wget http://localhost/files/f38-01-night.png
wget http://localhost/files/f38-01-day.png
mv f38-01-night.png f40-01-night.png
mv f38-01-day.png f40-01-day.png
mv /usr/share/backgrounds/gnome/adwaita-l.jpg /usr/share/backgrounds/gnome/adwaita-l.orig
cp f40-01-day.png /usr/share/backgrounds/gnome/adwaita-l.jpg

## Customize Grub Boot Menu

echo "Attempting to customize GRUB"

/usr/bin/mkdir /boot/grub2/images
cd /etc/default
wget  http://localhost/files/boot/grub
cp /usr/share/plymouth/themes/tm-fedora-remix/watermark.* /boot/grub2/images
mkdir /opt/FedoraRemix
cd /opt/FedoraRemix/ 
wget http://localhost/files/boot/grub
/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg

## Create VSCode Extension Directory
## TODO: Automate this part
mkdir VSCode
cd VSCode
wget http://localhost/VSCode/ChrisChinchilla.vale-vscode-0.21.0.vsix
wget http://localhost/VSCode/asciidoctor.asciidoctor-vscode-3.3.1.vsix
wget http://localhost/VSCode/flobilosaurus.vscode-asciidoc-slides-1.3.0.vsix
wget http://localhost/VSCode/redhat.ansible-24.9.320163.vsix
wget http://localhost/VSCode/redhat.vscode-yaml-1.15.0.vsix


## Add Fedora Dynamic MotD Script
cd /usr/bin
wget http://localhost/fedora-dynamic-motd.sh

### Removal of network fix
#rm /etc/resolv.conf

## Setting up Firstboot
## Copy resourcse and enable the service
#systemctl enable firststart.service
systemctl enable systemd-firstboot.service
cd /etc/systemd/system 
wget http://localhost/files/boot/fixgrub.service
cd /opt/FedoraRemix/
wget http://localhost/files/boot/fixgrub.sh
chmod +x /opt/FedoraRemix/fixgrub.sh
chmod 644  /etc/systemd/system/fixgrub.service
systemctl enable fixgrub.service

## Enable Cockpit and SSHD
echo "Enabling Cockpit and SSHD Services"
systemctl enable cockpit.socket
systemctl enable sshd.service

## Enable YAD Scripts and Looks
cd /opt/FedoraRemix/
wget -r -nH -np -R "index.htm*" http://localhost/scripts/
wget http://localhost/files/Wallpaper.png
cd /opt/FedoraRemix/scripts
wget http://localhost/files/boot/fixgrub.sh
chmod +x *.sh


mkdir /opt/FedoraRemix/logos
wget -O /opt/FedoraRemix/logos/splash.png http://localhost/tm-fedora-remix/logo.png
cd /opt/FedoraRemix
wget http://localhost/Fedora_Remix_Apps.desktop
wget http://localhost/Fedora_Remix_Customize.sh
cp /opt/FedoraRemix/Fedora_Remix_Apps.desktop /usr/share/gnome/autostart/
cp /opt/FedoraRemix/Fedora_Remix_Apps.desktop /usr/share/applications/
chmod +x Fedora_Remix_Customize.sh

## Install Gnome-Tweaks and Prepare Packages
cd /opt/FedoraRemixCustomize/
ansible-playbook Deploy_Gnome_Tweaks.yml --connection=local > /FedoraRemix/Deploy_Gnome_Tweaks.log

## Create Ansible-User with Password and Add to Sudoers
/usr/sbin/groupadd -g 700 ansible-user
/usr/sbin/useradd -u 700 -g 700 -c "Ansible User" ansible-user
echo "ansiblepass" | passwd ansible-user --stdin
echo "ansible-user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible-user

## Download and Install Calibre
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

## Attempt to Install Gnome Extensions

#!/bin/bash
USER="$(whoami)"
cd /opt/FedoraRemixCustomize/
ansible-playbook Enable_Gnome_Extensions.yml 

## Customize Extensions for all Users 
#!/bin/bash
cd /opt/FedoraRemixCustomize/Files/extensions/
rsync -avz * /usr/share/gnome-shell/extensions/
chown root:root -R /usr/share/gnome-shell/extensions/
chmod 755  -R /usr/share/gnome-shell/extensions

## Enabled Desktop Icons


## Update to Latest Packages
dnf update -y

%end
