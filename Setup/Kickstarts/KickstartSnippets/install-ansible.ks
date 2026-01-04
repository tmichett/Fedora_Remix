## Setup and Install Ansible and Ansible Navigator - Optimized Version
# Use formatting functions if available, fallback to simple echo
if type ks_print_section >/dev/null 2>&1; then
    ks_print_section "ANSIBLE DEVELOPMENT TOOLS INSTALLATION"
    ks_print_step 1 3 "Installing Ansible core components"
    ks_print_install "ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools gdown"
else
    echo "* =============================================================================="
    echo "* ANSIBLE DEVELOPMENT TOOLS INSTALLATION"
    echo "* =============================================================================="
    echo "[1/3] Installing Ansible core components"
    echo "[INST] Installing ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools gdown..."
fi

# Install Ansible tools with optimized flags for faster installation
/usr/bin/pip install --no-cache-dir --disable-pip-version-check \
    ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools \
    gdown \
    --no-warn-script-location --root-user-action=ignore

# Verify installation with appropriate formatting
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 2 3 "Verifying Ansible installation"
    if command -v ansible >/dev/null 2>&1; then
        local ansible_version=$(ansible --version | head -n1 | cut -d' ' -f3- 2>/dev/null || echo "unknown")
        ks_print_success "Ansible installed successfully (${ansible_version})"
    else
        ks_print_error "Ansible installation verification failed"
    fi
    ks_print_step 3 3 "Ansible installation completed"
    ks_completion_banner "ANSIBLE TOOLS"
else
    echo "[2/3] Verifying Ansible installation"
    if command -v ansible >/dev/null 2>&1; then
        local ansible_version=$(ansible --version | head -n1 | cut -d' ' -f3- 2>/dev/null || echo "unknown")
        echo "[OK] Ansible installed successfully (${ansible_version})"
    else
        echo "[ERROR] Ansible installation verification failed"
    fi
    echo "[3/3] Ansible installation completed"
    echo ""
    echo "[DONE][DONE][DONE] ANSIBLE TOOLS installation completed successfully! [DONE][DONE][DONE]"
    echo ""
fi
