#!/usr/bin/bash
#
# Demo script to show the enhanced formatting capabilities
# Run this to see the new formatting in action
#

# Source the formatting functions
source Setup/Kickstarts/KickstartSnippets/format-functions.ks

echo "Testing Enhanced Kickstart Formatting..."
echo ""

# Demo header
ks_print_header "FEDORA REMIX FORMATTING DEMO"

# Demo section
ks_print_section "INSTALLATION PROGRESS EXAMPLE"

# Demo steps with progress
ks_print_step 1 5 "Initializing system components"
sleep 1
ks_print_step 2 5 "Downloading packages"
ks_print_download "example-package-1.2.3.rpm"
sleep 1
ks_print_step 3 5 "Installing applications"
ks_print_install "VLC Media Player"
sleep 1
ks_print_step 4 5 "Configuring services"
ks_print_configure "Network settings"
sleep 1
ks_print_step 5 5 "Finalizing setup"
ks_print_success "All components installed successfully"

# Demo separator
ks_separator

# Demo different message types
ks_print_info "This is an informational message"
ks_print_success "This indicates successful completion"
ks_print_warning "This is a warning message"
ks_print_error "This would be an error message"

# Demo completion banner
ks_completion_banner "DEMO INSTALLATION"

echo ""
echo "Enhanced formatting demo completed!"
