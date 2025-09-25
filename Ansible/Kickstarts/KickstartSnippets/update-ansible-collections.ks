## Update Ansible Collections - Optimized Version

ks_print_section "ANSIBLE COLLECTIONS UPDATE"

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

## Install/Update Core System Collections in batch for better performance
ks_print_section "ANSIBLE SYSTEM COLLECTIONS UPDATE"
ks_print_install "Installing/updating core system collections"

# Install all required collections in a single operation to reduce network overhead
ansible-galaxy collection install --upgrade \
    ansible.posix \
    community.general \
    containers.podman \
    fedora.linux_system_roles \
    -p /usr/share/ansible/collections/ansible_collections

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