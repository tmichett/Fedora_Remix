## Install VLC with Freeworld Plugins
# Use formatting functions if available, fallback to simple echo
if type ks_print_section >/dev/null 2>&1; then
    ks_print_section "VLC MEDIA PLAYER INSTALLATION"
    ks_print_step 1 4 "Removing any conflicting VLC packages"
    ks_print_info "Cleaning up potential package conflicts..."
else
    echo "* =============================================================================="
    echo "* VLC MEDIA PLAYER INSTALLATION"
    echo "* =============================================================================="
    echo "[1/4] Removing any conflicting VLC packages"
    echo "i Cleaning up potential package conflicts..."
fi
dnf remove -y vlc* || true

# Continue with appropriate formatting
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 2 4 "Installing VLC with enhanced codec support"
    ks_print_install "vlc vlc-plugins-freeworld (RPM Fusion)"
else
    echo "[2/4] Installing VLC with enhanced codec support"
    echo "[INST] Installing vlc vlc-plugins-freeworld (RPM Fusion)..."
fi

dnf install -y --allowerasing vlc vlc-plugins-freeworld

# Verification with appropriate formatting
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 3 4 "Verifying VLC installation"
    if command -v vlc >/dev/null 2>&1; then
        local vlc_version=$(vlc --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 2>/dev/null || echo "unknown")
        ks_print_success "VLC Media Player installed successfully (v${vlc_version})"
        ks_print_info "Enhanced codec support enabled via RPM Fusion freeworld plugins"
    else
        ks_print_error "VLC installation verification failed"
    fi
    ks_print_step 4 4 "VLC installation completed"
    ks_completion_banner "VLC MEDIA PLAYER"
else
    echo "[3/4] Verifying VLC installation"
    if command -v vlc >/dev/null 2>&1; then
        local vlc_version=$(vlc --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 2>/dev/null || echo "unknown")
        echo "[OK] VLC Media Player installed successfully (v${vlc_version})"
        echo "i Enhanced codec support enabled via RPM Fusion freeworld plugins"
    else
        echo "[ERROR] VLC installation verification failed"
    fi
    echo "[4/4] VLC installation completed"
    echo ""
    echo "[DONE][DONE][DONE] VLC MEDIA PLAYER installation completed successfully! [DONE][DONE][DONE]"
    echo ""
fi
