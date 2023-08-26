#!/bin/bash
yad --title "Fedora Remix Desktop Customization Tool" --form --columns=3 --width=540 --height=190 --text="Travis's Fedora Remix Customization Utility" --image=/opt/FedoraRemix/logos/splash.png  \
--field="<b>1 - Update System Packages (reboot when completed)</b>":fbtn "gnome-terminal -t 'Update System Packages' -- sh -c 'sudo /opt/FedoraRemix/scripts/update_pkgs.sh'" \
--field="<b>2 -Create Root Password and Allow SSH</b>":fbtn "gnome-terminal -t 'Enabling Root User' -- sh -c 'sudo /opt/FedoraRemix/scripts/ssh_allow_root.sh'" \
--field="<b>3 - Create Root SSH Key and Prepare Ansible</b>":fbtn "gnome-terminal -t 'Create SSH Key and Prepare Ansible' -- sh -c 'sudo /opt/FedoraRemix/scripts/create_ssh_key.sh'" \
--field="<b>4 - Create User SSH Key and Prepare Ansible</b>":fbtn "gnome-terminal -t 'Create SSH Key and Prepare Ansible' -- sh -c '/opt/FedoraRemix/scripts/create_ssh_key.sh'" \
--field="<b>5 - Create Sudoers File for Current User - No Password</b>":fbtn "gnome-terminal -t 'Create Sudoers File for Current User - No Password' -- sh -c 'sudo /opt/FedoraRemix/scripts/update_sudoers_nopw.sh'" \
--field="<b>6 - Customize Gnome for Current User</b>":fbtn "gnome-terminal -t 'Customize Gnome for Current User' -- sh -c '/opt/FedoraRemix/scripts/customize_gnome.sh'" \
--field="<b>7 - Customize Gnome for Root User</b>":fbtn "gnome-terminal -t 'Customize Gnome for Root User' -- sh -c 'sudo /opt/FedoraRemix/scripts/customize_gnome.sh'" \
--field="<b>8 - Customize Grub Bootloaderr</b>":fbtn "gnome-terminal -t 'Customizing Grub' -- sh -c 'sudo /opt/FedoraRemix/scripts/customize_grub.sh'" \
--field="<b>9 - Install Gnome Shell Extensions (will reboot when completed)</b>":fbtn "gnome-terminal -t 'Installing Shell Exentsions' -- sh -c '/opt/FedoraRemix/scripts/deploy_gnome_extensions.sh'" \
--field="<b>10 - Enable Gnome Shell Extensions for Desktop</b>":fbtn "gnome-terminal -t 'Enabling Desktop Icon Extensions' -- sh -c '/opt/FedoraRemix/scripts/enable_gnome_extensions.sh'" \
--field="<b>11 -Remove Fedora Remix Utilities from Automatic Startup</b>":fbtn "gnome-terminal -t 'Removing Automatic Tool Startup' -- sh -c 'sudo /opt/FedoraRemix/scripts/remove_yad_from_startup.sh'" \
--field="<b>12 -Set Ansible User Password</b>":fbtn "gnome-terminal -t 'Ansible User Password Setting' -- sh -c 'sudo /opt/FedoraRemix/scripts/ansible-user_passwd.sh'" \
--field="<b>13 -Create PXEBoot Server</b>":fbtn "gnome-terminal -t 'Creating PXEBoot Server' -- sh -c 'sudo /opt/FedoraRemix/scripts/create_pxe_server.sh'" \
--button=Exit:1
