## Install Fedora Remix Lab Environment
## Downloads lab scripts and VM management tools to /opt/FedoraRemixLab
## Creates symlinks in /usr/local/bin for easy access

# Use formatting functions if available, fallback to simple echo
if type ks_print_section >/dev/null 2>&1; then
    ks_print_section "🧪 FEDORA REMIX LAB ENVIRONMENT"
    ks_print_step 1 5 "Creating Fedora Remix Lab directory"
else
    echo "* =============================================================================="
    echo "* FEDORA REMIX LAB ENVIRONMENT"
    echo "* =============================================================================="
    echo "[1/5] Creating Fedora Remix Lab directory"
fi

# Create the lab directory
mkdir -p /opt/FedoraRemixLab

# Download lab files from GitHub
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 2 5 "Downloading Fedora Remix Lab files from GitHub"
else
    echo "[2/5] Downloading Fedora Remix Lab files from GitHub"
fi

GITHUB_RAW="https://raw.githubusercontent.com/tmichett/Fedora_Remix_Lab/main"

# List of files to download
LAB_FILES=(
    "create-lab-vms.sh"
    "start-lab-vms.sh"
    "reset-lab.sh"
    "lab-status.sh"
    "manage-hosts.sh"
    "download-image.sh"
    "inventory"
    "README.md"
)

# Download each file
for file in "${LAB_FILES[@]}"; do
    echo "  Downloading: ${file}"
    curl -sL -o "/opt/FedoraRemixLab/${file}" "${GITHUB_RAW}/${file}" || \
    wget -q -O "/opt/FedoraRemixLab/${file}" "${GITHUB_RAW}/${file}" || \
    echo "  WARNING: Failed to download ${file}"
done

# Make scripts executable
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 3 5 "Setting permissions and creating symlinks"
else
    echo "[3/5] Setting permissions and creating symlinks"
fi

chmod +x /opt/FedoraRemixLab/*.sh 2>/dev/null || true

# Create symlinks in /usr/local/bin for easy access
SCRIPT_FILES=(
    "create-lab-vms.sh"
    "start-lab-vms.sh"
    "reset-lab.sh"
    "lab-status.sh"
    "manage-hosts.sh"
    "download-image.sh"
)

for script in "${SCRIPT_FILES[@]}"; do
    # Remove .sh extension for the symlink name and add lab- prefix
    link_name="lab-${script%.sh}"
    if [ -f "/opt/FedoraRemixLab/${script}" ]; then
        ln -sf "/opt/FedoraRemixLab/${script}" "/usr/local/bin/${link_name}"
        echo "  Created symlink: ${link_name} -> /opt/FedoraRemixLab/${script}"
    fi
done

# Also create symlinks with original names for convenience
for script in "${SCRIPT_FILES[@]}"; do
    if [ -f "/opt/FedoraRemixLab/${script}" ]; then
        ln -sf "/opt/FedoraRemixLab/${script}" "/usr/local/bin/${script}"
    fi
done

# Download the base QCOW2 image to libvirt images directory
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 4 5 "Downloading Fedora Lab base image (this may take a while)"
else
    echo "[4/5] Downloading Fedora Lab base image (this may take a while)"
fi

LIBVIRT_IMAGES="/var/lib/libvirt/images"
mkdir -p "${LIBVIRT_IMAGES}"

# Check if gdown is available
if command -v gdown >/dev/null 2>&1; then
    echo "  Using gdown to download Fedora43Lab.qcow2..."
    echo "  Destination: ${LIBVIRT_IMAGES}/Fedora43Lab.qcow2"
    cd "${LIBVIRT_IMAGES}"
    # Google Drive file ID for Fedora43Lab.qcow2
    if gdown "1aMNna4AhHaRvQoEEK5XL8rGINnSEgTIN" -O "Fedora43Lab.qcow2"; then
        chown qemu:qemu "${LIBVIRT_IMAGES}/Fedora43Lab.qcow2"
        chmod 644 "${LIBVIRT_IMAGES}/Fedora43Lab.qcow2"
        echo "  Base image downloaded successfully"
    else
        echo "  WARNING: Failed to download base image. Run 'sudo lab-download-image' later."
    fi
else
    echo "  WARNING: gdown not available. Run 'sudo lab-download-image' after boot to download the base image."
fi

# Verify installation
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 5 5 "Verifying Fedora Remix Lab installation"
else
    echo "[5/5] Verifying Fedora Remix Lab installation"
fi

echo ""
echo "  Fedora Remix Lab installed to: /opt/FedoraRemixLab"
echo ""
echo "  Available commands:"
echo "    lab-create-lab-vms    - Create lab VMs"
echo "    lab-start-lab-vms     - Start lab VMs"
echo "    lab-reset-lab         - Reset lab environment"
echo "    lab-status            - Show lab status"
echo "    lab-manage-hosts      - Manage /etc/hosts entries"
echo "    lab-download-image    - Download base QCOW2 image"
echo ""

if [ -f "${LIBVIRT_IMAGES}/Fedora43Lab.qcow2" ]; then
    IMAGE_SIZE=$(du -h ${LIBVIRT_IMAGES}/Fedora43Lab.qcow2 | cut -f1)
    if type ks_print_success >/dev/null 2>&1; then
        ks_print_success "Fedora Remix Lab installed successfully (base image: ${IMAGE_SIZE})"
    else
        echo "[OK] Fedora Remix Lab installed successfully (base image: ${IMAGE_SIZE})"
    fi
else
    if type ks_print_warning >/dev/null 2>&1; then
        ks_print_warning "Fedora Remix Lab installed (base image not downloaded - run 'sudo lab-download-image' later)"
    else
        echo "[WARN] Fedora Remix Lab installed (base image not downloaded - run 'sudo lab-download-image' later)"
    fi
fi

if type ks_completion_banner >/dev/null 2>&1; then
    ks_completion_banner "FEDORA REMIX LAB"
else
    echo ""
    echo "[DONE][DONE][DONE] FEDORA REMIX LAB installation completed! [DONE][DONE][DONE]"
    echo ""
fi

