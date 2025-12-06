#!/bin/bash
#
# Download VSCode Extensions Script
# Downloads VSCode extensions (.vsix files) from the Visual Studio Marketplace
#
# Usage: ./download_vscode_extensions.sh [output_directory]
#
# If no output directory is specified, extensions are saved to ../files/VSCode/
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default output directory
OUTPUT_DIR="${1:-${SCRIPT_DIR}/../files/VSCode}"

# Extensions to download (format: publisher.extension-name)
EXTENSIONS=(
    # Code Quality & Formatting
    "aaron-bond.better-comments"
    "esbenp.prettier-vscode"
    "ChrisChinchilla.vale-vscode"
    
    # Code Screenshots & Sharing
    "adpyke.codesnap"
    "pnp.polacode"
    
    # Git & Collaboration
    "eamodio.gitlens"
    "MS-vsliveshare.vsliveshare"
    
    # AsciiDoc
    "asciidoctor.asciidoctor-vscode"
    "flobilosaurus.vscode-asciidoc-slides"
    
    # Language Support
    "peterjonsson.kickstart-language-support"
    "ms-python.python"
    "redhat.ansible"
    "redhat.vscode-xml"
    "redhat.vscode-yaml"
    
    # Productivity
    "Gruntfuggly.todo-tree"
    "Codeium.codeium"
)

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to download a VSCode extension from the marketplace
download_extension() {
    local extension_id="$1"
    local publisher="${extension_id%%.*}"
    local extension_name="${extension_id#*.}"
    
    print_info "Downloading: ${extension_id}"
    
    # VS Code Marketplace download URL (official API)
    local download_url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${extension_name}/latest/vspackage"
    
    # Temporary files for download
    local temp_gz=$(mktemp)
    local temp_vsix=$(mktemp)
    
    # Download the extension with proper headers
    local http_code
    http_code=$(curl -sL -w "%{http_code}" -o "${temp_gz}" \
        -H "Accept: application/octet-stream" \
        "${download_url}")
    
    if [[ "$http_code" == "200" ]] && [[ -s "${temp_gz}" ]]; then
        # Check if file is gzip compressed (marketplace returns gzip)
        local file_type
        file_type=$(file -b "${temp_gz}" 2>/dev/null || echo "")
        
        if [[ "$file_type" == *"gzip"* ]]; then
            # Decompress the gzip file
            gunzip -c "${temp_gz}" > "${temp_vsix}" 2>/dev/null
            rm -f "${temp_gz}"
        else
            # Not gzip, use as-is
            mv "${temp_gz}" "${temp_vsix}"
        fi
        
        # Get the version from the VSIX (which is a zip file)
        local version=""
        
        if command -v unzip &> /dev/null; then
            # Try to get version from package.json
            version=$(unzip -p "${temp_vsix}" "extension/package.json" 2>/dev/null | \
                      sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 || echo "")
            
            # Fallback: try extension.vsixmanifest
            if [[ -z "$version" ]]; then
                version=$(unzip -p "${temp_vsix}" "extension.vsixmanifest" 2>/dev/null | \
                          sed -n 's/.*Version="\([^"]*\)".*/\1/p' | head -1 || echo "")
            fi
        fi
        
        # If still no version, use "latest"
        if [[ -z "$version" ]]; then
            version="latest"
        fi
        
        # Final filename
        local filename="${publisher}.${extension_name}-${version}.vsix"
        local output_path="${OUTPUT_DIR}/${filename}"
        
        # Move to output directory
        mv "${temp_vsix}" "${output_path}"
        
        print_success "Downloaded: ${filename}"
        return 0
    else
        rm -f "${temp_gz}" "${temp_vsix}"
        print_error "Failed to download: ${extension_id} (HTTP ${http_code})"
        return 1
    fi
}

# Main script
main() {
    echo ""
    echo "=========================================="
    echo "  VSCode Extension Downloader"
    echo "=========================================="
    echo ""
    
    # Create output directory if it doesn't exist
    mkdir -p "${OUTPUT_DIR}"
    print_info "Output directory: ${OUTPUT_DIR}"
    echo ""
    
    # Check for required tools
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v unzip &> /dev/null; then
        print_warning "unzip not found - version detection may not work"
    fi
    
    # Download each extension
    local success_count=0
    local fail_count=0
    
    for extension in "${EXTENSIONS[@]}"; do
        if download_extension "${extension}"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "  Download Summary"
    echo "=========================================="
    print_success "Successfully downloaded: ${success_count}"
    if [[ $fail_count -gt 0 ]]; then
        print_error "Failed downloads: ${fail_count}"
    fi
    echo ""
    
    # List downloaded files
    print_info "Files in output directory:"
    ls -la "${OUTPUT_DIR}"/*.vsix 2>/dev/null || print_warning "No .vsix files found"
}

# Run main function
main "$@"

