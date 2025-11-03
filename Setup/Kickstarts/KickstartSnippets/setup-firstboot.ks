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
