#!/usr/bin/bash
echo "I am attempting to run fix and customize the Grub Bootloader"
cp -f /opt/FedoraRemix/grub /etc/default/grub
/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
rm $0
