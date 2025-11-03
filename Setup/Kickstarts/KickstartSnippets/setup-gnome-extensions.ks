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

## Enabled Desktop Icons (GNOME 47 Compatible)
/usr/bin/gnome-extensions install /opt/FedoraRemixCustomize/Files/dingrastersoft.com.v80.shell-extension.zip
/usr/bin/gnome-extensions install /opt/FedoraRemixCustomize/Files/add-to-desktoptommimon.github.com.v15.shell-extension.zip

## Enable DING for All Users FC42 (4/21/2025)
ks_print_configure "GNOME Desktop Extensions (DING)"
cd /usr/share/gnome-shell/extensions
rm -rf ding@rastersoft.com
mkdir ding@rastersoft.com
cd /usr/share/gnome-shell/extensions/ding@rastersoft.com
unzip /opt/FedoraRemixCustomize/Files/dingrastersoft.com.v80.shell-extension.zip
chown -R root:root /usr/share/gnome-shell/extensions/ding@rastersoft.com
chmod 755 -R /usr/share/gnome-shell/extensions/ding@rastersoft.com
dconf update
