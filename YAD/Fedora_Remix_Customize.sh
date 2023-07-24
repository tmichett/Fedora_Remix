#!/bin/bash
yad --title "Fedora Remix Desktop Customization Tool" --form --columns=3 --width=540 --height=190 --text="Travis's Fedora Remix Customization Utility" --image=/var/www/html/files/boot/splash.png  \
--field="<b>Update System Packages</b>":fbtn "sudo bash '/opt/FedoraRemix/scripts/update_pkgs.sh'" \
--field="<b>Customize Stuff</b>":fbtn "konsole --noclose -e sh './scripts/arch'" \
--button=Exit:1
