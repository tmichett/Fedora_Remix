#!/bin/bash
#
# Deploy VSCode Extensions Script
# Installs all VSCode extensions from the FedoraRemix VSCode directory
# Automatically finds the latest version of each extension
#

VSCODE_DIR="/opt/FedoraRemix/VSCode"

# Function to find and install an extension by its base name
install_extension() {
    local extension_pattern="$1"
    local extension_file
    
    # Find the extension file matching the pattern (get the newest if multiple exist)
    extension_file=$(ls -t "${VSCODE_DIR}/${extension_pattern}"*.vsix 2>/dev/null | head -1)
    
    if [[ -n "$extension_file" && -f "$extension_file" ]]; then
        echo "Installing: $(basename "$extension_file")"
        code --install-extension "$extension_file"
    else
        echo "Warning: Extension not found matching pattern: ${extension_pattern}*.vsix"
    fi
}

echo "=========================================="
echo "  Deploying VSCode Extensions"
echo "=========================================="
echo ""

# Code Quality & Formatting
install_extension "aaron-bond.better-comments-"
install_extension "esbenp.prettier-vscode-"
install_extension "ChrisChinchilla.vale-vscode-"

# Code Screenshots & Sharing
install_extension "adpyke.codesnap-"
install_extension "pnp.polacode-"

# Git & Collaboration
install_extension "eamodio.gitlens-"
install_extension "MS-vsliveshare.vsliveshare-"

# AsciiDoc
install_extension "asciidoctor.asciidoctor-vscode-"
install_extension "flobilosaurus.vscode-asciidoc-slides-"

# Language Support
install_extension "peterjonsson.kickstart-language-support-"
install_extension "ms-python.python-"
install_extension "redhat.ansible-"
install_extension "redhat.vscode-xml-"
install_extension "redhat.vscode-yaml-"

# Productivity
install_extension "Gruntfuggly.todo-tree-"
install_extension "Codeium.codeium-"

echo ""
echo "=========================================="
echo "  Extension deployment complete!"
echo "=========================================="
