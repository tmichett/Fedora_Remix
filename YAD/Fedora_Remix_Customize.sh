#!/bin/bash
yad --title "Fedora Remix Desktop Customization Tool" --form --columns=3 --width=540 --height=190 --text="Travis's Fedora Remix Customization Utility" --image=/opt/FedoraRemix/logos/splash.png  \
--field="<b>Update System Packages</b>":fbtn "gnome-terminal -t 'Update System Packages' -- sh -c 'sudo /opt/FedoraRemix/scripts/update_pkgs.sh'" \
--field="<b>Create Root SSH Key and Prepare Ansible</b>":fbtn "gnome-terminal -t 'Create SSH Key and Prepare Ansible' -- sh -c 'sudo /opt/FedoraRemix/scripts/create_ssh_key.sh'" \
--field="<b>Create User SSH Key and Prepare Ansible</b>":fbtn "gnome-terminal -t 'Create SSH Key and Prepare Ansible' -- sh -c '/opt/FedoraRemix/scripts/create_ssh_key.sh'" \
--field="<b>Create Sudoers File for Current User - No Password</b>":fbtn "gnome-terminal -t 'Create Sudoers File for Current User - No Password' -- sh -c 'sudo /opt/FedoraRemix/scripts/update_sudoers_nopw.sh'" \
--field="<b>Customize Gnome for Current User</b>":fbtn "gnome-terminal -t 'Customize Gnome for Current User' -- sh -c 'sudo /opt/FedoraRemix/scripts/customize_gnome.sh'" \
--button=Exit:1
