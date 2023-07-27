#!/bin/bash
mkdir -p ~/.local/share/gnome-shell/extensions/ding@rastersoft.com
cd ~/.local/share/gnome-shell/extensions/ding@rastersoft.com
pwd
unzip -q /opt/FedoraRemix/files/dingrastersoft.com.v57.shell-extension.zip -d ~/.local/share/gnome-shell/extensions/ding@rastersoft.com
gnome-extensions enable ding@rastersoft.com
