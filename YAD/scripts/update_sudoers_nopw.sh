#!/bin/bash
USER="$(whoami)"
sudo sh -c 'echo "travis ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/travis'
