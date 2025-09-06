## Install Cursor
wget -O  /opt/FedoraRemixApps/Cursor.AppImage https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/linux/x64/Cursor-0.50.5-x86_64.AppImage
chmod +x /opt/FedoraRemixApps/Cursor.AppImage
cd /usr/share/icons 
wget http://localhost/files/logos/Cursor.svg
cd /usr/share/applications
wget http://localhost/files/Cursor.desktop
