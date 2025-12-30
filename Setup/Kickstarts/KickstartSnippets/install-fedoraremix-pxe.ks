## Install FedoraRemix PXE Server Tools
## Clones the FedoraRemixPXE repository to /opt/FedoraRemixPXE
## Repository: https://github.com/tmichett/FedoraRemixPXE

# Use formatting functions if available, fallback to simple echo
if type ks_print_section >/dev/null 2>&1; then
    ks_print_section "🌐 FEDORA REMIX PXE SERVER INSTALLATION"
    ks_print_step 1 4 "Cloning FedoraRemixPXE repository from GitHub"
    ks_print_download "https://github.com/tmichett/FedoraRemixPXE"
else
    echo "* =============================================================================="
    echo "* FEDORA REMIX PXE SERVER INSTALLATION"
    echo "* =============================================================================="
    echo "[1/4] Cloning FedoraRemixPXE repository from GitHub"
    echo "[DOWNLOAD] https://github.com/tmichett/FedoraRemixPXE..."
fi

# Create target directory if it doesn't exist
mkdir -p /opt

# Clone the FedoraRemixPXE repository
if [ -d /opt/FedoraRemixPXE ]; then
    # Directory exists, update it instead
    if type ks_print_info >/dev/null 2>&1; then
        ks_print_info "FedoraRemixPXE directory exists, updating..."
    else
        echo "[INFO] FedoraRemixPXE directory exists, updating..."
    fi
    cd /opt/FedoraRemixPXE
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    # Fresh clone
    git clone https://github.com/tmichett/FedoraRemixPXE.git /opt/FedoraRemixPXE
fi

# Verify clone was successful
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 2 4 "Verifying installation"
else
    echo "[2/4] Verifying installation"
fi

if [ -d /opt/FedoraRemixPXE ] && [ -f /opt/FedoraRemixPXE/run-pxe-server.py ]; then
    if type ks_print_success >/dev/null 2>&1; then
        ks_print_success "FedoraRemixPXE repository cloned successfully"
    else
        echo "[OK] FedoraRemixPXE repository cloned successfully"
    fi
else
    if type ks_print_error >/dev/null 2>&1; then
        ks_print_error "FedoraRemixPXE clone failed"
    else
        echo "[ERROR] FedoraRemixPXE clone failed"
    fi
fi

# Set permissions and make scripts executable
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 3 4 "Setting permissions and making scripts executable"
else
    echo "[3/4] Setting permissions and making scripts executable"
fi

cd /opt/FedoraRemixPXE
chmod +x *.sh 2>/dev/null || true
chmod +x *.py 2>/dev/null || true

# Create data directories for PXE server
mkdir -p /opt/FedoraRemixPXE/data/tftpboot
mkdir -p /opt/FedoraRemixPXE/data/http
mkdir -p /opt/FedoraRemixPXE/data/iso

# Create symlink in /usr/local/bin for easy access
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 4 4 "Creating convenience symlinks"
else
    echo "[4/4] Creating convenience symlinks"
fi

ln -sf /opt/FedoraRemixPXE/run-pxe-server.py /usr/local/bin/run-pxe-server 2>/dev/null || true
ln -sf /opt/FedoraRemixPXE/pxe-server.sh /usr/local/bin/pxe-server 2>/dev/null || true

# Display completion message
if type ks_completion_banner >/dev/null 2>&1; then
    ks_completion_banner "FEDORA REMIX PXE SERVER"
    ks_print_info "PXE Server tools installed to: /opt/FedoraRemixPXE"
    ks_print_info "Quick start: sudo run-pxe-server"
else
    echo ""
    echo "[DONE][DONE][DONE] FEDORA REMIX PXE SERVER installation completed! [DONE][DONE][DONE]"
    echo ""
    echo "[INFO] PXE Server tools installed to: /opt/FedoraRemixPXE"
    echo "[INFO] Quick start: sudo run-pxe-server"
    echo ""
fi

