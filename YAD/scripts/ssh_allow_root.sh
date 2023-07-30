#!/usr/bin/bash
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config 
systemctl restart sshd
passwd
