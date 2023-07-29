#!/bin/bash
USER="$(whoami)"
cd /opt/FedoraRemixCustomize/
ansible-playbook Enable_Gnome_Extensions.yml -k -K
