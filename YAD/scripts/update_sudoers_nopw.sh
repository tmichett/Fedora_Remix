#!/bin/bash
export USERNAME="$(whoami)"
echo "You are $USERNAME and adding to Sudoers file"
sudo sh -c 'echo "Defaults:$USERNAME !requiretty"  >> /etc/sudoers.d/$USERNAME'
sudo sh -c 'echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME'