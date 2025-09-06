## Setup and Install Ansible and Ansible Navigator
ks_print_section "ANSIBLE DEVELOPMENT TOOLS INSTALLATION"

ks_print_step 1 3 "Installing Ansible core components"
ks_print_install "ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools"
/usr/bin/pip install ansible-core ansible-navigator ansible-builder ansible ansible-dev-tools --no-warn-script-location --root-user-action=ignore

ks_print_step 2 3 "Verifying Ansible installation"
if command -v ansible >/dev/null 2>&1; then
    local ansible_version=$(ansible --version | head -n1 | cut -d' ' -f3-)
    ks_print_success "Ansible installed successfully (${ansible_version})"
else
    ks_print_error "Ansible installation verification failed"
fi

ks_print_step 3 3 "Ansible installation completed"
ks_completion_banner "ANSIBLE TOOLS"
