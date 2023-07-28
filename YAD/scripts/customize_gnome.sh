#!/bin/bash
USER="$(whoami)"
cd /opt/FedoraRemixCustomize/
ansible-playbook Deploy_Gnome_Tweaks.yml  -e "variable_user=$USER"
