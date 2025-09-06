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
/usr/bin/gnome-extensions install /opt/FedoraRemixCustomize/Gnome_Shell/dingrastersoft.com.v76.shell-extension.zip
/usr/bin/gnome-extensions install /opt/FedoraRemixCustomize/Gnome_Shell/add-to-desktoptommimon.github.com.v14.shell-extension.zip

## Enable DING for All Users FC42 (4/21/2025)
echo -e "${RED}Changing GNOME Extensions... ${NC}"
cd /usr/share/gnome-shell/extensions
rm -rf ding@rastersoft.com
mkdir ding@rastersoft.com
cd /usr/share/gnome-shell/extensions/ding@rastersoft.com
unzip /opt/FedoraRemixCustomize/Files/dingrastersoft.com.v76.shell-extension.zip
chown -R root:root /usr/share/gnome-shell/extensions/ding@rastersoft.com
chmod 755 -R /usr/share/gnome-shell/extensions/ding@rastersoft.com
dconf update
