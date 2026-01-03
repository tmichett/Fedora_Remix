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
python3-pip
vim-enhanced
dbus-x11
google-chrome-stable
git
gedit
tmux
fedora-remix-logos
gh
syslinux-perl
terminator
sshuttle
cockpit*
mc
fuse-sshfs
yum-utils

## Remove Tour
-gnome-tour

## Course and Classroom Building DLE-DOIT
python3-devel
python3
rsync
jq
yq
tree
uv
python-pyyaml

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
copr-cli


## Artur's CLI Utils
zoxide
eza ## Needs repo
btop
bat
fzf
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

## Fedora Remix Packages
## Comes from COPR Repository
dyff
LogViewer
fedora_remix_tools

%end
