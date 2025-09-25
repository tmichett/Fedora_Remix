## Enable YAD Scripts and Looks
cd /opt/FedoraRemix/
wget http://localhost/kickstart.py
wget -r -nH -np --reject-regex "index\\.html?.*" http://localhost/scripts/
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
