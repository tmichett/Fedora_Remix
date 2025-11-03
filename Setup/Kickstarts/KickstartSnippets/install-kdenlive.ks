## Install KDEnlive Video Editor
ks_print_section "KDENLIVE VIDEO EDITOR INSTALLATION"

ks_print_step 1 3 "Installing KDEnlive video editing suite"
ks_print_info "Installing after VLC configuration to prevent plugin conflicts"
ks_print_install "kdenlive (Professional Video Editor)"
dnf install -y kdenlive

ks_print_step 2 3 "Verifying KDEnlive installation"
if command -v kdenlive >/dev/null 2>&1; then
    ks_print_success "KDEnlive video editor installed successfully"
    ks_print_info "Professional video editing capabilities now available"
else
    ks_print_error "KDEnlive installation verification failed"
fi

ks_print_step 3 3 "KDEnlive installation completed"
ks_completion_banner "KDENLIVE VIDEO EDITOR"
