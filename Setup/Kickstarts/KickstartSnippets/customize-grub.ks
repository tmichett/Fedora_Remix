## Customize Grub Boot Menu

echo "Attempting to customize GRUB"

/usr/bin/mkdir /boot/grub2/images
cd /etc/default
wget  http://localhost/files/boot/grub
cp /usr/share/plymouth/themes/tm-fedora-remix/watermark.* /boot/grub2/images
mkdir /opt/FedoraRemix
cd /opt/FedoraRemix/ 
wget http://localhost/files/boot/grub
/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
