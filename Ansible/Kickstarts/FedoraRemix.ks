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

# part / --size 20680
# Commented out - partition definition is handled by fedora-live-base.ks



%post --nochroot
#if [ ! -e /mnt/sysimage/etc/resolf.conf ]; then
#  cp -P /etc/resolv.conf $INSTALL_ROOT/etc/resolv.conf
#fi
#%post --nochroot
#cp -P /etc/resolv.conf "$INSTALL_ROOT"/etc/resolv.conf
set -x
/usr/bin/pip install ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools --no-warn-script-location --root-user-action=ignore ## Issues with ansible-cdk# (issues with DNS in Post)

%end


### Fix ISOLinux

%post --nochroot
set -x
# Create isolinux directory if it doesn't exist and add marker file
if [ -d "$LIVE_ROOT" ]; then
    mkdir -p "$LIVE_ROOT/isolinux" 2>/dev/null || mkdir -p "$LIVE_ROOT/isolinx" 2>/dev/null || true
    touch "$LIVE_ROOT/isolinux/travis" 2>/dev/null || touch "$LIVE_ROOT/isolinx/travis" 2>/dev/null || echo "Could not create travis marker file"
fi

%end


%post

## Enhanced kickstart start banner
ks_print_header "FEDORA REMIX KICKSTART INSTALLATION"
ks_print_info "Kickstart started on $(date)"
ks_print_info "Building ${BOLD}Travis's Fedora Remix 42${NC}"

set -x
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
/usr/sbin/restorecon-R /home/liveuser/

EOF

## Load shared formatting functions for enhanced output
# Try multiple possible locations for format-functions.ks
if [ -f "KickstartSnippets/format-functions.ks" ]; then
    source KickstartSnippets/format-functions.ks
elif [ -f "/kickstart-root/KickstartSnippets/format-functions.ks" ]; then
    source /kickstart-root/KickstartSnippets/format-functions.ks
else
    # Fallback: Define all functions inline
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # Enhanced color definitions
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly BOLD='\033[1m'
    readonly DIM='\033[2m'
    readonly NC='\033[0m'

    # Unicode symbols (fallback to ASCII if needed)
    readonly CHECKMARK="[OK]"
    readonly CROSS="[ERROR]"
    readonly ARROW=">"
    readonly GEAR="[CONFIG]"
    readonly ROCKET="[START]"
    readonly PACKAGE="[PKG]"
    readonly WRENCH="[TOOL]"
    readonly DOWNLOAD="[DOWN]"
    readonly INSTALL="[INST]"
    readonly CONFIG="[CONF]"
    readonly SUCCESS_STAR="*"
    readonly WARNING_SIGN="!"
    readonly INFO_ICON="i"
    readonly FIRE="[FIRE]"
    readonly SPARKLES="[DONE]"

    # Formatting functions
    ks_print_header() {
        local message="$1"
        echo -e "\n${CYAN}===============================================================================${NC}"
        printf "${CYAN}${NC} ${BOLD}${WHITE}%-76s${NC} ${CYAN}${NC}\n" "$message"
        echo -e "${CYAN}===============================================================================${NC}\n"
    }

    ks_print_section() {
        local message="$1"
        echo -e "\n${PURPLE}${SUCCESS_STAR}==============================================================================${NC}"
        echo -e "${PURPLE}${SUCCESS_STAR}${NC} ${BOLD}${WHITE}$message${NC}"
        echo -e "${PURPLE}${SUCCESS_STAR}==============================================================================${NC}\n"
    }

    ks_print_info() {
        local message="$1"
        echo -e "${BLUE}${INFO_ICON}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${message}"
    }

    ks_print_success() {
        local message="$1"
        echo -e "${GREEN}${CHECKMARK}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${GREEN}${message}${NC}"
    }

    ks_print_warning() {
        local message="$1"
        echo -e "${YELLOW}${WARNING_SIGN}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${YELLOW}${message}${NC}"
    }

    ks_print_error() {
        local message="$1"
        echo -e "${RED}${CROSS}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${RED}${message}${NC}"
    }

    ks_print_install() {
        local package="$1"
        echo -e "${BLUE}${INSTALL}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} Installing ${GREEN}${package}${NC}..."
    }

    ks_print_download() {
        local item="$1"
        echo -e "${CYAN}${DOWNLOAD}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} Downloading ${GREEN}${item}${NC}..."
    }

    ks_print_configure() {
        local component="$1"
        echo -e "${PURPLE}${CONFIG}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} Configuring ${GREEN}${component}${NC}..."
    }

    ks_print_step() {
        local step_num="$1"
        local total_steps="$2"
        local description="$3"
        echo -e "${WHITE}${BOLD}[$step_num/$total_steps]${NC} ${description}"
    }

    ks_separator() {
        echo -e "${DIM}${WHITE}-------------------------------------------------------------------------------${NC}"
    }

    ks_completion_banner() {
        local component="$1"
        echo -e "\n${GREEN}${SPARKLES}${SPARKLES}${SPARKLES}${NC} ${BOLD}${GREEN}$component installation completed successfully!${NC} ${GREEN}${SPARKLES}${SPARKLES}${SPARKLES}${NC}\n"
    }
fi

### Update PATH
ks_print_configure "System PATH environment"
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

ks_print_configure "Plymouth boot theme"

/usr/sbin/plymouth-set-default-theme tm-fedora-remix -R

dracut -f --no-kernel


## Fix Networking

ks_print_configure "DNS and network settings"
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


%include KickstartSnippets/install-ansible.ks



%include KickstartSnippets/install-flatpaks.ks

%include KickstartSnippets/install-balena-etcher.ks

%include KickstartSnippets/customize-anaconda.ks


%include KickstartSnippets/customize-gnome-wallpaper.ks

%include KickstartSnippets/customize-grub.ks

%include KickstartSnippets/setup-vscode-extensions.ks


%include KickstartSnippets/setup-dynamic-motd.ks


%include KickstartSnippets/customize-bash-shell.ks



%include KickstartSnippets/setup-firstboot.ks

%include KickstartSnippets/setup-yad-scripts.ks

%include KickstartSnippets/install-gnome-tweaks.ks

%include KickstartSnippets/create-ansible-user.ks

%include KickstartSnippets/install-calibre.ks

%include KickstartSnippets/setup-gnome-extensions.ks

%include KickstartSnippets/install-udpcast.ks 

%include KickstartSnippets/install-ohmybash.ks

%include KickstartSnippets/set-bash-defaults.ks

%include KickstartSnippets/install-podman-bootc.ks

## Update to Latest Packages
ks_print_section "SYSTEM PACKAGE UPDATES"
ks_print_install "Latest package updates"
dnf update -y

%include KickstartSnippets/update-ansible-collections.ks

%include KickstartSnippets/install-lmstudio.ks

%include KickstartSnippets/install-logviewer.ks

%include KickstartSnippets/setup-desktop-icons.ks

%include KickstartSnippets/setup-tmux.ks

%include KickstartSnippets/install-veracrypt.ks

%include KickstartSnippets/install-mutagen.ks


%include KickstartSnippets/install-cursor.ks

%include KickstartSnippets/install-vlc.ks

%include KickstartSnippets/install-kdenlive.ks

## Put information in /etc regarding Fedora Remix Versions
date "+This version of Fedora Remix 42 was created on %B %d, %Y" > /etc/fedora_remix_release

## Enhanced completion banner
ks_separator
ks_print_success "Kickstart installation completed on $(date)"
ks_completion_banner "FEDORA REMIX KICKSTART"

ks_print_header "PROCEEDING TO ISO BUILD PHASE"
ks_print_info "${ROCKET} Initiating Live ISO creation process..."
ks_separator
%end
