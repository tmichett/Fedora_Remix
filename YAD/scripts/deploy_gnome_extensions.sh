#!/bin/bash
USER="$(whoami)"
cd /opt/FedoraRemixCustomize/
ansible-playbook Deploy_Gnome_Extensions.yml