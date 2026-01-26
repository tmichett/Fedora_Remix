## Travis's Custom Packages for COSMIC Desktop Remix
%packages

# Remove GNOME-related groups (the '-' prefix excludes them)
-@gnome-desktop
-@gnome-software-development

# Add the COSMIC Desktop Environment groups
@cosmic-desktop
@cosmic-desktop-apps

# Optional: Add common workstation tools that are usually pulled by GNOME
@base-x
@fonts
@hardware-support

## Fix Branding and Logos
#-fedora-logos
#-fedora-release*
#generic-logos
#generic-release
#generic-release-notes
## End Branding and Logos

## Remove GNOME-specific packages that may conflict or are unnecessary
-gnome-tour
-gnome-terminal
-gnome-software
-gnome-shell-extension-*
-gnome-tweaks

vim
sshfs
@Virtualization
guestfs-tools
python3-libguestfs
@RPM Development Tools
@Development Tools
createrepo
rclone
isomd5sum
rpm-sign
git-lfs
python3-pip
vim-enhanced
dbus-x11
google-chrome-stable
ImageMagick
mock
git
vlc
## VLC Plugin conflicts removing plugin
-vlc-plugins-freeworld  
code
tmux
ntfs-3g
wget
curl
unzip
fedora-remix-logos
gh
syslinux-perl
yad
pykickstart
terminator
sshuttle
cockpit*
meson
ninja-build
pinentry
make
genisoimage
xorriso
libxml2
mc
fuse-sshfs
yum-utils
cargo
golang

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


## Telecon and Media
obs-studio

## Course and Classroom Building DLE-DOIT
python3-devel
gcc
python3
rsync
jq
yq
tree
pre-commit
uv
toolbox
python-pyyaml

## Speech Synthasis
speech-dispatcher
speech-dispatcher-utils

## Ansible Roles
linux-system-roles
sshpass

## For Wifi and Networking
NetworkManager-wifi 
iwl*
usbutils ## provides lsusb
inxi
pciutils ## Provides lspci
wireguard-tools

## Other Wifi Packages
atheros-firmware
b43-fwcutter
b43-openfwwf
brcmfmac-firmware
iwlegacy-firmware
iwlwifi-dvm-firmware
iwlwifi-mvm-firmware
libertas-firmware
mt7xxx-firmware
nxpwireless-firmware
realtek-firmware
tiwilink-firmware
atmel-firmware
zd1211-firmware

# Web Browsers
firefox
chromium

## Added for Ansible and JSON Filtering
python-jmespath

## Added for Hardware Testing and Looking
lshw

## Added for VSCode Packages
xclip

## Added for Mlocate replacement for "locate" command
plocate

## Added for Fedora Remix Tools
ttyd
python-qt5
util-linux-script

## Artur's CLI Utils
zoxide
eza ## Needs repo
btop
bat
yazi  ## Needs repo
dust  ## Needs repo

## Networking and Diagnostic Utilities
nmap 
iptraf-ng
wireshark
fastfetch

## Remote Access
remmina

## New Tools
procs
duf
httpie
fd
ripgrep
fzf
util-linux
fio
f3

## Fedora Remix Packages
dyff
LogViewer

## LibreOffice (standalone, not tied to GNOME)
libreoffice

## Text Editors (COSMIC-friendly alternatives)
gedit

%end

