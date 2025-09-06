## Install VLC with Freeworld Plugins
ks_print_section "VLC MEDIA PLAYER INSTALLATION"

ks_print_step 1 4 "Removing any conflicting VLC packages"
ks_print_info "Cleaning up potential package conflicts..."
dnf remove -y vlc* || true

ks_print_step 2 4 "Installing VLC with enhanced codec support"
ks_print_install "vlc vlc-plugins-freeworld (RPM Fusion)"
dnf install -y --allowerasing vlc vlc-plugins-freeworld

ks_print_step 3 4 "Verifying VLC installation"
if command -v vlc >/dev/null 2>&1; then
    local vlc_version=$(vlc --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
    ks_print_success "VLC Media Player installed successfully (v${vlc_version:-unknown})"
    ks_print_info "Enhanced codec support enabled via RPM Fusion freeworld plugins"
else
    ks_print_error "VLC installation verification failed"
fi

ks_print_step 4 4 "VLC installation completed"
ks_completion_banner "VLC MEDIA PLAYER"
