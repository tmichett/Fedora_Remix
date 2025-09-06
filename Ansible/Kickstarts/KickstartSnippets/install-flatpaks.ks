## Install Flatpaks
echo "Attempting to install flatpaks"

# Enable unprivileged user namespaces
sudo chmod u+s /usr/bin/bwrap

/usr/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
/usr/bin/flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
/usr/bin/flatpak install --system --noninteractive flathub io.podman_desktop.PodmanDesktop

# Enable system-wide access
flatpak override --system --filesystem=home


## Fix Flatpak SELinux
/usr/sbin/restorecon -R /var/lib/flatpak
