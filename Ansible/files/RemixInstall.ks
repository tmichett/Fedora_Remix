#version=DEVEL
# System language
lang en_US.UTF-8

# Keyboard layouts
keyboard us

# System timezone
timezone America/New_York --isUtc

# Root password (plaintext or hashed)
rootpw --plaintext redhat

# User creation
user --name=travis --password=redhat --plaintext --groups=wheel --gecos="Travis Michette"

# Use network for time sync
network --bootproto=dhcp --device=eth0 --onboot=on --hostname=fedora-live-install

# Install instead of live boot
liveinst --noeject

# Don't ask questions
reboot

# Clear the disk and create default layout
autopart --type=plain --fstype=ext4

# System bootloader configuration
bootloader --location=mbr

# Use graphical install
graphical