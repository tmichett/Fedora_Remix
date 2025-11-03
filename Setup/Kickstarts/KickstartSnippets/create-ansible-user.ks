## Create Ansible-User with Password and Add to Sudoers
/usr/sbin/groupadd -g 700 ansible-user
/usr/sbin/useradd -u 700 -g 700 -c "Ansible User" ansible-user
echo "ansiblepass" | passwd ansible-user --stdin
sudo sh -c 'echo "Defaults:ansible-user !requiretty"  > /etc/sudoers.d/ansible-user'
echo "ansible-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ansible-user
