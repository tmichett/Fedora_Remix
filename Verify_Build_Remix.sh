#!/bin/bash
#
# Verify_Build_Remix.sh
# Verification script for Fedora Remix Builder
# Checks Fedora versions in config files and confirms with user before building
#

set -e

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Unicode symbols
readonly CHECKMARK="✅"
readonly CROSS="❌"
readonly WARNING="⚠️"
readonly INFO="ℹ️"
readonly GEAR="⚙️"
readonly ROCKET="🚀"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored messages
print_message() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "SUCCESS")
            echo -e "${GREEN}${CHECKMARK} ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}${CROSS} ${message}${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}${WARNING} ${message}${NC}"
            ;;
        "INFO")
            echo -e "${CYAN}${INFO} ${message}${NC}"
            ;;
        "HEADER")
            echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BOLD}${CYAN}║${NC} ${WHITE}${message}${NC}"
            echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
            ;;
    esac
}

# Function to extract Fedora version from config.yml (container config)
get_container_fedora_version() {
    local config_file="$SCRIPT_DIR/config.yml"
    if [ ! -f "$config_file" ]; then
        echo "ERROR: config.yml not found"
        return 1
    fi
    
    local version=$(grep -A 5 "Container_Properties:" "$config_file" | grep "Fedora_Version:" | awk '{print $2}' | tr -d '"')
    if [ -z "$version" ]; then
        echo "ERROR: Could not extract Fedora_Version from config.yml"
        return 1
    fi
    echo "$version"
}

# Function to extract Fedora version from Setup/config.yml (remix config)
get_remix_fedora_version() {
    local config_file="$SCRIPT_DIR/Setup/config.yml"
    if [ ! -f "$config_file" ]; then
        echo "ERROR: Setup/config.yml not found"
        return 1
    fi
    
    local version=$(grep "^fedora_version:" "$config_file" | awk '{print $2}' | tr -d '"')
    if [ -z "$version" ]; then
        echo "ERROR: Could not extract fedora_version from Setup/config.yml"
        return 1
    fi
    echo "$version"
}

# Function to get GitHub registry owner
get_github_registry_owner() {
    local config_file="$SCRIPT_DIR/config.yml"
    local owner=$(grep -A 5 "Container_Properties:" "$config_file" | grep "GitHub_Registry_Owner:" | awk '{print $2}' | tr -d '"')
    if [ -z "$owner" ]; then
        echo "ERROR: Could not extract GitHub_Registry_Owner"
        return 1
    fi
    echo "$owner"
}

# Function to check if container image exists locally
check_container_image() {
    local image_name="$1"
    if podman image exists "$image_name" 2>/dev/null; then
        return 0
    elif sudo podman image exists "$image_name" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get container image creation date
get_image_creation_date() {
    local image_name="$1"
    local date=""
    
    # Try regular podman first
    date=$(podman image inspect "$image_name" 2>/dev/null | grep -m 1 '"Created":' | awk -F'"' '{print $4}' | cut -d'T' -f1)
    
    # If that fails, try sudo podman
    if [ -z "$date" ]; then
        date=$(sudo podman image inspect "$image_name" 2>/dev/null | grep -m 1 '"Created":' | awk -F'"' '{print $4}' | cut -d'T' -f1)
    fi
    
    echo "$date"
}

# Main verification function
main() {
    echo ""
    print_message "HEADER" "🔍 Fedora Remix Builder - Configuration Verification"
    echo ""
    
    # Get versions
    print_message "INFO" "Reading configuration files..."
    echo ""
    
    CONTAINER_VERSION=$(get_container_fedora_version)
    if [ $? -ne 0 ]; then
        print_message "ERROR" "Failed to read container Fedora version from config.yml"
        exit 1
    fi
    
    REMIX_VERSION=$(get_remix_fedora_version)
    if [ $? -ne 0 ]; then
        print_message "ERROR" "Failed to read remix Fedora version from Setup/config.yml"
        exit 1
    fi
    
    GITHUB_OWNER=$(get_github_registry_owner)
    if [ $? -ne 0 ]; then
        print_message "ERROR" "Failed to read GitHub registry owner from config.yml"
        exit 1
    fi
    
    # Construct image name
    IMAGE_NAME="ghcr.io/${GITHUB_OWNER}/fedora-remix-builder:${CONTAINER_VERSION}"
    
    # Display configuration
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC} ${WHITE}Configuration Summary${NC}                                                ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Container Configuration${NC} (config.yml)                              ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    Fedora Version: ${WHITE}${CONTAINER_VERSION}${NC}                                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    Container Image: ${WHITE}${IMAGE_NAME}${NC}"
    printf "${BOLD}${CYAN}║${NC}\n"
    echo -e "${BOLD}${CYAN}║${NC}                                                                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Remix Configuration${NC} (Setup/config.yml)                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    Fedora Version: ${WHITE}${REMIX_VERSION}${NC}                                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    ISO Output: ${WHITE}FedoraRemix-${REMIX_VERSION}.iso${NC}                                ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check version compatibility
    if [ "$CONTAINER_VERSION" != "$REMIX_VERSION" ]; then
        print_message "WARNING" "Version mismatch detected!"
        echo ""
        echo -e "  ${YELLOW}Container is configured for Fedora ${CONTAINER_VERSION}${NC}"
        echo -e "  ${YELLOW}Remix is configured for Fedora ${REMIX_VERSION}${NC}"
        echo ""
        print_message "WARNING" "This may cause build issues or unexpected results."
        echo ""
        echo -e "${BOLD}Recommendation:${NC} Update both config files to use the same Fedora version."
        echo ""
    else
        print_message "SUCCESS" "Versions match! Container and Remix both use Fedora ${CONTAINER_VERSION}"
        echo ""
    fi
    
    # Check if container image exists
    print_message "INFO" "Checking for container image..."
    if check_container_image "$IMAGE_NAME"; then
        IMAGE_DATE=$(get_image_creation_date "$IMAGE_NAME")
        print_message "SUCCESS" "Container image found locally"
        if [ -n "$IMAGE_DATE" ]; then
            echo -e "  ${CYAN}Created: ${IMAGE_DATE}${NC}"
        fi
        echo ""
    else
        print_message "WARNING" "Container image not found locally: ${IMAGE_NAME}"
        echo ""
        echo -e "  ${YELLOW}The image will be pulled from GitHub Container Registry during build.${NC}"
        echo -e "  ${YELLOW}This may take several minutes depending on your internet connection.${NC}"
        echo ""
        echo -e "${BOLD}Alternative:${NC} Build the container locally:"
        echo -e "  ${CYAN}cd /home/travis/Github/RemixBuilder${NC}"
        echo -e "  ${CYAN}./build.sh${NC}"
        echo ""
    fi
    
    # Check for Build_Remix.sh
    if [ ! -f "$SCRIPT_DIR/Build_Remix.sh" ]; then
        print_message "ERROR" "Build_Remix.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    if [ ! -x "$SCRIPT_DIR/Build_Remix.sh" ]; then
        print_message "WARNING" "Build_Remix.sh is not executable"
        echo -e "  ${YELLOW}Making it executable...${NC}"
        chmod +x "$SCRIPT_DIR/Build_Remix.sh"
        print_message "SUCCESS" "Build_Remix.sh is now executable"
        echo ""
    fi
    
    # Ask for confirmation
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC} ${WHITE}Ready to Build${NC}                                                       ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "$(echo -e ${BOLD}${WHITE}Do you want to proceed with the build? [y/N]: ${NC})" -n 1 -r
    echo ""
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "SUCCESS" "Starting build process..."
        echo ""
        print_message "INFO" "Executing: ./Build_Remix.sh"
        echo ""
        echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Execute the build script
        exec "$SCRIPT_DIR/Build_Remix.sh"
    else
        print_message "INFO" "Build cancelled by user"
        echo ""
        echo -e "${BOLD}To build later, run:${NC}"
        echo -e "  ${CYAN}cd $SCRIPT_DIR${NC}"
        echo -e "  ${CYAN}./Build_Remix.sh${NC}"
        echo ""
        echo -e "${BOLD}To update configuration:${NC}"
        echo -e "  ${CYAN}Container version: edit config.yml${NC}"
        echo -e "  ${CYAN}Remix version: edit Setup/config.yml${NC}"
        echo ""
        exit 0
    fi
}

# Run main function
main "$@"

# Made with Bob
