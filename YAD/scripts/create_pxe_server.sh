#!/bin/bash
USER="$(whoami)"
cd /opt/PXEServer/
ansible-playbook Setup_PXE_Server.yml  -k
