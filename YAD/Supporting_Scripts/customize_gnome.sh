#!/bin/bash
USER="$(whoami)"
cd /opt/FedoraRemix/Ansible_Playbooks/
ansible-playbook Deploy_Gnome_Tweaks.yml  -e "variable_user=$USER"
