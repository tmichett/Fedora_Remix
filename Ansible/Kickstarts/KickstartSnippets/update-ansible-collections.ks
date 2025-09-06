## Update Ansible Collections

# Get the Python path for ansible collections
INSTALL_PATH=$(ansible-galaxy collection list | grep ansible_collections | grep python | awk '{print $2}')

# Check if the INSTALL_PATH variable is not empty
if [ -z "$INSTALL_PATH" ]; then
    echo "Error: Unable to determine the Python path for ansible collections."
    exit 1
fi

ks_print_success "Python path: $INSTALL_PATH"

# List all installed collections and loop through them
ks_print_info "Scanning installed Ansible collections..."
for collection in $(ansible-galaxy collection list | awk '{print $1}' | tail -n +2); do
  ks_print_install "Upgrading collection: $collection"
  
## Use ansible-galaxy to install the collection with the specified path ##
  ansible-galaxy collection install $collection --upgrade -p "$INSTALL_PATH"
  done

## Update System Collections for Ansible Posix and others
ks_print_section "ANSIBLE SYSTEM COLLECTIONS UPDATE"
ks_print_install "ansible.posix community.general containers.podman fedora.linux_system_roles"
ansible-galaxy collection install --upgrade ansible.posix community.general containers.podman fedora.linux_system_roles  -p /usr/share/ansible/collections/ansible_collections
