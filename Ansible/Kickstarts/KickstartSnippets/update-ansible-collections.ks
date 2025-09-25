## Update Ansible Collections - Optimized Version

ks_print_section "ANSIBLE COLLECTIONS VERIFICATION"

# Check if ansible-galaxy is available first
if ! command -v ansible-galaxy >/dev/null 2>&1; then
    ks_print_warning "ansible-galaxy command not found, collections provided via RPM packages only"
    ks_print_info "Core collections available via system packages:"
    ks_print_info "  - ansible.posix (from ansible-collection-ansible-posix RPM)"
    ks_print_info "  - community.general (from ansible-collection-community-general RPM)"
    ks_print_info "  - containers.podman (from ansible-collection-containers-podman RPM)"
    ks_print_success "Ansible collections setup completed via system packages"
    exit 0
fi

ks_print_info "ansible-galaxy available, checking for additional collection needs"

# Use Python-based path discovery for better reliability
INSTALL_PATH=$(python3 -c "import site; print(site.getsitepackages()[0] + '/ansible_collections')" 2>/dev/null || echo "/usr/local/lib/python*/site-packages/ansible_collections")

# Verify path exists or create it
if [ ! -d "$INSTALL_PATH" ]; then
    ks_print_warning "User collections path not found, will use system path only"
    INSTALL_PATH=""
fi

if [ -n "$INSTALL_PATH" ]; then
    ks_print_info "User collections path: $INSTALL_PATH"
fi

## Check if collections are already installed via RPM
ks_print_section "ANSIBLE SYSTEM COLLECTIONS VERIFICATION"

# Check for system-installed collections
SYSTEM_COLLECTIONS_PATH="/usr/share/ansible/collections/ansible_collections"
if [ -d "$SYSTEM_COLLECTIONS_PATH" ]; then
    ks_print_success "System collections already installed via RPM packages"
    ks_print_info "Available system collections:"
    if [ -d "$SYSTEM_COLLECTIONS_PATH/ansible" ]; then
        ks_print_info "  ✓ ansible.posix (system package)"
    fi
    if [ -d "$SYSTEM_COLLECTIONS_PATH/community" ]; then
        ks_print_info "  ✓ community.general (system package)"
    fi
    if [ -d "$SYSTEM_COLLECTIONS_PATH/containers" ]; then
        ks_print_info "  ✓ containers.podman (system package)"
    fi
    if [ -d "$SYSTEM_COLLECTIONS_PATH/fedora" ]; then
        ks_print_info "  ✓ fedora.linux_system_roles (system package)"
    fi
else
    ks_print_warning "System collections path not found, installing via ansible-galaxy"
    # Install all required collections in a single operation to reduce network overhead
    ansible-galaxy collection install --upgrade \
        ansible.posix \
        community.general \
        containers.podman \
        fedora.linux_system_roles \
        -p /usr/share/ansible/collections/ansible_collections
fi

# Only update user collections if path exists and has collections
if [ -n "$INSTALL_PATH" ] && [ -d "$INSTALL_PATH" ] && [ "$(ls -A "$INSTALL_PATH" 2>/dev/null)" ]; then
    ks_print_info "Updating user-installed collections in batch"
    
    # Get list of installed collections (more efficient than individual upgrades)
    COLLECTIONS=$(ansible-galaxy collection list 2>/dev/null | grep -v "^#" | awk 'NR>1 {print $1}' | grep -v "^$" | head -20)
    
    if [ -n "$COLLECTIONS" ]; then
        ks_print_install "Batch updating user collections"
        # Update in smaller batches to avoid command line length limits
        echo "$COLLECTIONS" | xargs -r -n 5 ansible-galaxy collection install --upgrade -p "$INSTALL_PATH"
    else
        ks_print_info "No user collections found to update"
    fi
else
    ks_print_info "No user collections directory found or empty, skipping user collection updates"
fi

ks_print_success "Ansible collections update completed"