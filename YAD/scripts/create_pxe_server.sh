#!/bin/bash
USER="$(whoami)"
cd /opt/PXEServer/
ansible-galaxy collection install -r collections/requirements.yml -p collections
ansible-galaxy install -r roles/requirements.yml -p roles
ansible-playbook site.yml  -k
