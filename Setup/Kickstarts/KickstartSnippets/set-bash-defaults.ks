## Set BASHRC Defaults
## Add OhMyBash and customizations to /etc/bashrc (for login shells)
echo "$(cat /opt/FedoraRemixCustomize/bashrc.append)" >> /etc/bashrc

## Also add to /etc/skel/.bashrc for new users with non-login shells (like COSMIC Terminal)
## COSMIC Terminal launches interactive non-login shells which only source ~/.bashrc
echo "" >> /etc/skel/.bashrc
echo "# OhMyBash and Fedora Remix customizations" >> /etc/skel/.bashrc
echo "$(cat /opt/FedoraRemixCustomize/bashrc.append)" >> /etc/skel/.bashrc

## Update liveuser's .bashrc directly since their home directory already exists
if [ -d /home/liveuser ]; then
    echo "" >> /home/liveuser/.bashrc
    echo "# OhMyBash and Fedora Remix customizations" >> /home/liveuser/.bashrc
    echo "$(cat /opt/FedoraRemixCustomize/bashrc.append)" >> /home/liveuser/.bashrc
    chown liveuser:liveuser /home/liveuser/.bashrc
fi
