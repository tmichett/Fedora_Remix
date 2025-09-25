## Customize Anaconda Installer
ks_print_section "ANACONDA INSTALLER CUSTOMIZATION"

ks_print_configure "Anaconda installer branding and themes"

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

## Use this in a script to fix after upgrade for desktop logo
cd /usr/share/fedora-logos/
rm fedora*.svg
wget http://localhost/files/logos/fedora_logo.svg
wget http://localhost/files/logos/fedora_logo_darkbackground.svg
wget http://localhost/files/logos/fedora_lightbackground.svg 
wget http://localhost/files/logos/fedora_darkbackground.svg
## END Use this in a script to fix after upgrade for desktop logo END ##
