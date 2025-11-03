## Install Gnome-Tweaks and Prepare Packages
cd /opt/FedoraRemixCustomize/
ansible-playbook Deploy_Gnome_Tweaks.yml --connection=local > /FedoraRemix/Deploy_Gnome_Tweaks.log
wget http://localhost/files/bashrc.append
