## Customize BASH Prompts and Shell 
mkdir -p /opt/bash
mkdir -p /opt/FedoraRemixCustomize
cd /opt/bash
wget http://localhost/files/bashrc.append -O /opt/bash/bashrc.append

# Copy bashrc.append to where set-bash-defaults.ks expects it
cp /opt/bash/bashrc.append /opt/FedoraRemixCustomize/bashrc.append

## Install Gitprompt
git clone https://github.com/tmichett/bash-git-prompt.git /opt/bash-git-prompt --depth=1
