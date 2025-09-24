## Install Flatpaks
ks_print_section "FLATPAK CONFIGURATION & INSTALLATION"

ks_print_step 1 6 "Enabling unprivileged user namespaces"
ks_print_configure "User namespace permissions for Flatpak"
sudo chmod u+s /usr/bin/bwrap

ks_print_step 2 6 "Adding Flathub repository (system-wide)"
ks_print_configure "Flathub repository - system scope"
/usr/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

ks_print_step 3 6 "Adding Flathub repository (user-level)"
ks_print_configure "Flathub repository - user scope"
/usr/bin/flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

ks_print_step 4 6 "Installing Podman Desktop via Flatpak"
ks_print_install "io.podman_desktop.PodmanDesktop"
/usr/bin/flatpak install --system --noninteractive flathub io.podman_desktop.PodmanDesktop

ks_print_step 5 6 "Configuring system-wide file access"
ks_print_configure "Flatpak filesystem permissions"
flatpak override --system --filesystem=home

ks_print_step 6 6 "Fixing SELinux contexts for Flatpak"
ks_print_configure "SELinux security contexts"
/usr/sbin/restorecon -R /var/lib/flatpak

ks_completion_banner "FLATPAK ECOSYSTEM"
