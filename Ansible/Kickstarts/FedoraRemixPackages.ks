## Travis's Custom Packages
%packages
## Fix Branding and Logos
#-fedora-logos
#-fedora-release*
#generic-logos
#generic-release
#generic-release-notes
## End Branding and Logos
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
gedit
vlc
code
tmux
ntfs-3g
wget
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

## Remove Tour
-gnome-tour

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

## For Wifi and Networking
@hardware-support
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

## Added packages that were removed in FC40 from default
@Gnome-desktop
libreoffice

## Added for Ansible and JSON Filtering
python-jmespath

## Added for Hardware Testing and Looking
lshw
pciutils

## Added for VSCode Packages
xclip

## Added packages to fix FC41 Terminal
gnome-terminal

## Added for Mlocate replacement for "locate" command
plocate

## Added for Fedora Remix Tools
ttyd
python-qt5
python-pyyaml
util-linux-script
python-qt6


%end
