## Install FedoraRemix PXE Server Tools
## Downloads specific scripts from FedoraRemixPXE repository to /opt/FedoraRemixPXETools
## Repository: https://github.com/tmichett/FedoraRemixPXE

# Use formatting functions if available, fallback to simple echo
if type ks_print_section >/dev/null 2>&1; then
    ks_print_section "🌐 FEDORA REMIX PXE TOOLS INSTALLATION"
    ks_print_step 1 4 "Creating directory structure"
else
    echo "* =============================================================================="
    echo "* FEDORA REMIX PXE TOOLS INSTALLATION"
    echo "* =============================================================================="
    echo "[1/4] Creating directory structure"
fi

# Create target directory
mkdir -p /opt/FedoraRemixPXETools

# Download specific scripts from GitHub
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 2 4 "Downloading PXE tools from GitHub"
    ks_print_download "run-pxe-server.py"
else
    echo "[2/4] Downloading PXE tools from GitHub"
    echo "[DOWNLOAD] run-pxe-server.py..."
fi

# Download run-pxe-server.py
curl -fsSL -o /opt/FedoraRemixPXETools/run-pxe-server.py \
    "https://raw.githubusercontent.com/tmichett/FedoraRemixPXE/main/run-pxe-server.py"

if type ks_print_download >/dev/null 2>&1; then
    ks_print_download "show-dhcp-clients.sh"
else
    echo "[DOWNLOAD] show-dhcp-clients.sh..."
fi

# Download show-dhcp-clients.sh
curl -fsSL -o /opt/FedoraRemixPXETools/show-dhcp-clients.sh \
    "https://raw.githubusercontent.com/tmichett/FedoraRemixPXE/main/show-dhcp-clients.sh"

if type ks_print_download >/dev/null 2>&1; then
    ks_print_download "test-services.sh"
else
    echo "[DOWNLOAD] test-services.sh..."
fi

# Download test-services.sh
curl -fsSL -o /opt/FedoraRemixPXETools/test-services.sh \
    "https://raw.githubusercontent.com/tmichett/FedoraRemixPXE/main/test-services.sh"

# Verify downloads
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 3 4 "Verifying downloads and setting permissions"
else
    echo "[3/4] Verifying downloads and setting permissions"
fi

# Check if files were downloaded successfully
DOWNLOAD_SUCCESS=true
for script in run-pxe-server.py show-dhcp-clients.sh test-services.sh; do
    if [ -f "/opt/FedoraRemixPXETools/$script" ] && [ -s "/opt/FedoraRemixPXETools/$script" ]; then
        if type ks_print_success >/dev/null 2>&1; then
            ks_print_success "$script downloaded successfully"
        else
            echo "[OK] $script downloaded successfully"
        fi
    else
        if type ks_print_error >/dev/null 2>&1; then
            ks_print_error "Failed to download $script"
        else
            echo "[ERROR] Failed to download $script"
        fi
        DOWNLOAD_SUCCESS=false
    fi
done

# Make scripts executable
chmod +x /opt/FedoraRemixPXETools/*.sh 2>/dev/null || true
chmod +x /opt/FedoraRemixPXETools/*.py 2>/dev/null || true

# Create symlinks in /usr/local/bin for easy access
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 4 4 "Creating convenience symlinks in /usr/local/bin"
else
    echo "[4/4] Creating convenience symlinks in /usr/local/bin"
fi

# Create symlinks
ln -sf /opt/FedoraRemixPXETools/run-pxe-server.py /usr/local/bin/run-pxe-server 2>/dev/null || true
ln -sf /opt/FedoraRemixPXETools/show-dhcp-clients.sh /usr/local/bin/show-dhcp-clients 2>/dev/null || true
ln -sf /opt/FedoraRemixPXETools/test-services.sh /usr/local/bin/test-pxe-services 2>/dev/null || true

if type ks_print_info >/dev/null 2>&1; then
    ks_print_info "Symlinks created:"
    ks_print_info "  run-pxe-server      -> /opt/FedoraRemixPXETools/run-pxe-server.py"
    ks_print_info "  show-dhcp-clients   -> /opt/FedoraRemixPXETools/show-dhcp-clients.sh"
    ks_print_info "  test-pxe-services   -> /opt/FedoraRemixPXETools/test-services.sh"
else
    echo "[INFO] Symlinks created:"
    echo "  run-pxe-server      -> /opt/FedoraRemixPXETools/run-pxe-server.py"
    echo "  show-dhcp-clients   -> /opt/FedoraRemixPXETools/show-dhcp-clients.sh"
    echo "  test-pxe-services   -> /opt/FedoraRemixPXETools/test-services.sh"
fi

# Display completion message
if type ks_completion_banner >/dev/null 2>&1; then
    ks_completion_banner "FEDORA REMIX PXE TOOLS"
    ks_print_info "PXE Tools installed to: /opt/FedoraRemixPXETools"
    ks_print_info ""
    ks_print_info "Available commands:"
    ks_print_info "  sudo run-pxe-server       - Launch containerized PXE server"
    ks_print_info "  sudo show-dhcp-clients    - Show connected DHCP clients"
    ks_print_info "  sudo test-pxe-services    - Test PXE server services"
else
    echo ""
    echo "[DONE][DONE][DONE] FEDORA REMIX PXE TOOLS installation completed! [DONE][DONE][DONE]"
    echo ""
    echo "[INFO] PXE Tools installed to: /opt/FedoraRemixPXETools"
    echo ""
    echo "[INFO] Available commands:"
    echo "  sudo run-pxe-server       - Launch containerized PXE server"
    echo "  sudo show-dhcp-clients    - Show connected DHCP clients"
    echo "  sudo test-pxe-services    - Test PXE server services"
    echo ""
fi
