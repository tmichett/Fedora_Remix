#!/bin/bash
USER="$(whoami)"
cd /opt/FedoraRemixCustomize/
ansible-playbook Enable_Fingerprint_Services.yml  -e "variable_user=$USER" -k -K
