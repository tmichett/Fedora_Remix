#!/bin/bash
set -e

# Script to run the Fedora Remix Builder container using Podman
# Reads SSH_Key_Location and Fedora_Remix_Location from config.yml
# Supports building different Remix variants (FedoraRemix, FedoraRemixCosmic, etc.)

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -k, --kickstart <name>   Specify kickstart to build (without .ks extension)"
    echo "                           Examples: FedoraRemix, FedoraRemixCosmic"
    echo "  -l, --list               List available kickstart files"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "If no kickstart is specified, you will be prompted to choose."
}

# Function to list available kickstarts
list_kickstarts() {
    local remix_location="$1"
    echo "Available Kickstart files:"
    echo ""
    for ks in "$remix_location"/Setup/Kickstarts/FedoraRemix*.ks; do
        if [ -f "$ks" ]; then
            basename "$ks" .ks
        fi
    done
}

# Color definitions for menu
readonly MENU_CYAN='\033[0;36m'
readonly MENU_GREEN='\033[0;32m'
readonly MENU_YELLOW='\033[1;33m'
readonly MENU_WHITE='\033[1;37m'
readonly MENU_NC='\033[0m'

# Function to show interactive menu
show_menu() {
    local remix_location="$1"
    local kickstarts=()
    local i=1
    
    # First, add FedoraRemix as the default (first in list)
    if [ -f "$remix_location/Setup/Kickstarts/FedoraRemix.ks" ]; then
        kickstarts+=("FedoraRemix")
    fi
    
    # Then add other kickstarts (excluding Packages, Repos, and the default)
    for ks in "$remix_location"/Setup/Kickstarts/FedoraRemix*.ks; do
        if [ -f "$ks" ]; then
            local name=$(basename "$ks" .ks)
            # Skip Packages and Repos snippets, and skip FedoraRemix (already added)
            if [[ "$name" != *"Packages"* ]] && [[ "$name" != *"Repos"* ]] && [ "$name" != "FedoraRemix" ]; then
                kickstarts+=("$name")
            fi
        fi
    done
    
    # Box is 56 visual columns wide
    echo ""
    echo -e "${MENU_CYAN}╔══════════════════════════════════════════════════════╗${MENU_NC}"
    echo -e "${MENU_CYAN}║${MENU_NC} ${MENU_WHITE}🚀  Fedora Remix Builder - Kickstart Selection${MENU_NC}       ${MENU_CYAN}║${MENU_NC}"
    echo -e "${MENU_CYAN}╠══════════════════════════════════════════════════════╣${MENU_NC}"
    
    for name in "${kickstarts[@]}"; do
        if [ "$name" = "FedoraRemix" ]; then
            # Inner: 2 + 2 + 1 + name + padding + 9 + 1 = 54, so padding = 39 - name_len
            echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}$i)${MENU_NC} ${MENU_WHITE}$name${MENU_NC}$(printf '%*s' $((39 - ${#name})) '')${MENU_YELLOW}[DEFAULT]${MENU_NC} ${MENU_CYAN}║${MENU_NC}"
        else
            # Inner: 2 + 2 + 1 + name + padding = 54, so padding = 49 - name_len
            echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}$i)${MENU_NC} $name$(printf '%*s' $((49 - ${#name})) '')${MENU_CYAN}║${MENU_NC}"
        fi
        ((i++))
    done
    
    echo -e "${MENU_CYAN}╚══════════════════════════════════════════════════════╝${MENU_NC}"
    echo ""
    
    while true; do
        read -p "Select kickstart to build (1-${#kickstarts[@]}) [Enter=default]: " choice
        # If user just presses Enter, use default (FedoraRemix)
        if [ -z "$choice" ]; then
            SELECTED_KICKSTART="FedoraRemix"
            echo "Using default: FedoraRemix"
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#kickstarts[@]}" ]; then
            SELECTED_KICKSTART="${kickstarts[$((choice-1))]}"
            break
        else
            echo "Invalid selection. Please enter a number between 1 and ${#kickstarts[@]}, or press Enter for default"
        fi
    done
}

# Parse command line arguments
SELECTED_KICKSTART=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--kickstart)
            SELECTED_KICKSTART="$2"
            shift 2
            ;;
        -l|--list)
            # We need to parse config first to get the remix location
            if [ ! -f "config.yml" ]; then
                echo "Error: config.yml not found in current directory"
                exit 1
            fi
            FEDORA_REMIX_LOCATION=$(grep -A 10 "Container_Properties:" config.yml | grep "Fedora_Remix_Location:" | awk '{print $2}' | tr -d '"')
            FEDORA_REMIX_LOCATION="${FEDORA_REMIX_LOCATION/#\~/$HOME}"
            list_kickstarts "$FEDORA_REMIX_LOCATION"
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if config.yml exists
if [ ! -f "config.yml" ]; then
    echo "Error: config.yml not found in current directory"
    exit 1
fi

# Extract values from config.yml
SSH_KEY_LOCATION=$(grep -A 10 "Container_Properties:" config.yml | grep "SSH_Key_Location:" | awk '{print $2}' | tr -d '"')
FEDORA_REMIX_LOCATION=$(grep -A 10 "Container_Properties:" config.yml | grep "Fedora_Remix_Location:" | awk '{print $2}' | tr -d '"')
IMAGE_NAME=$(grep -A 10 "Container_Properties:" config.yml | grep "Image_Name:" | awk '{print $2}' | tr -d '"')

if [ -z "$SSH_KEY_LOCATION" ] || [ -z "$FEDORA_REMIX_LOCATION" ] || [ -z "$IMAGE_NAME" ]; then
    echo "Error: Could not extract SSH_Key_Location, Fedora_Remix_Location, or Image_Name from config.yml"
    exit 1
fi

# Expand ~ in paths
SSH_KEY_LOCATION="${SSH_KEY_LOCATION/#\~/$HOME}"
FEDORA_REMIX_LOCATION="${FEDORA_REMIX_LOCATION/#\~/$HOME}"

# Get current working directory
CURRENT_DIR=$(pwd)

# Check if SSH key exists
if [ ! -f "$SSH_KEY_LOCATION" ]; then
    echo "Warning: SSH key not found at $SSH_KEY_LOCATION"
    echo "Container will still run, but SSH operations may fail"
fi

# Check if Fedora Remix location exists
if [ ! -d "$FEDORA_REMIX_LOCATION" ]; then
    echo "Error: Fedora Remix location does not exist: $FEDORA_REMIX_LOCATION"
    exit 1
fi

# If no kickstart specified, show interactive menu
if [ -z "$SELECTED_KICKSTART" ]; then
    show_menu "$FEDORA_REMIX_LOCATION"
fi

# Validate that the selected kickstart exists
if [ ! -f "$FEDORA_REMIX_LOCATION/Setup/Kickstarts/${SELECTED_KICKSTART}.ks" ]; then
    echo "Error: Kickstart file not found: ${SELECTED_KICKSTART}.ks"
    echo "Available kickstarts:"
    list_kickstarts "$FEDORA_REMIX_LOCATION"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              🚀 Fedora Remix Builder Configuration            ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
printf "║  %-60s ║\n" "Image: $IMAGE_NAME"
printf "║  %-60s ║\n" "Kickstart: ${SELECTED_KICKSTART}.ks"
printf "║  %-60s ║\n" "Output ISO: ${SELECTED_KICKSTART}.iso"
printf "║  %-60s ║\n" "SSH Key: $SSH_KEY_LOCATION"
printf "║  %-60s ║\n" "Fedora Remix: $FEDORA_REMIX_LOCATION"
printf "║  %-60s ║\n" "Workspace: $CURRENT_DIR"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Container name
CONTAINER_NAME="remix-builder"

# Remove existing container with the same name if it exists
# Check with both regular podman and sudo podman since containers might have been created with either
if podman ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: $CONTAINER_NAME"
    podman kill "$CONTAINER_NAME" 2>/dev/null || true
    sleep 1
    podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
fi
if sudo podman ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container (sudo): $CONTAINER_NAME"
    sudo podman kill "$CONTAINER_NAME" 2>/dev/null || true
    sleep 2
    sudo podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
    sleep 1
fi

# Detect if we need to use sudo for podman (required for loop device access on Linux)
PODMAN_CMD="podman"
EXTRA_ARGS=()

if [ "$(id -u)" -ne 0 ]; then
    # Not running as root
    # Check if we're on Linux (macOS podman works differently)
    if [ "$(uname -s)" = "Linux" ]; then
        echo "⚠️  Loop device creation requires elevated privileges on Linux."
        echo "    Using sudo to run podman with proper device access..."
        echo ""
        PODMAN_CMD="sudo podman"
        EXTRA_ARGS=("--device-cgroup-rule=b 7:* rmw")
    else
        # macOS or other - rootless should work
        EXTRA_ARGS=("--device" "/dev/loop-control")
        for i in {0..7}; do
            if [ -e "/dev/loop$i" ]; then
                EXTRA_ARGS+=("--device" "/dev/loop$i")
            fi
        done
    fi
else
    # Running as root
    EXTRA_ARGS=("--device-cgroup-rule=b 7:* rmw")
fi

# Run the container with systemd support and loop device access
# Note: --security-opt label=disable helps with SELinux-related mount warnings
# --replace will automatically replace any existing container with the same name
# The /sys unmount issue is now handled gracefully by Enhanced_Remix_Build_Script.sh
# Pass the selected kickstart as an environment variable
$PODMAN_CMD run --rm -it \
    --replace \
    --name "$CONTAINER_NAME" \
    --systemd=always \
    --privileged \
    "${EXTRA_ARGS[@]}" \
    --security-opt label=disable \
    -e "REMIX_KICKSTART=$SELECTED_KICKSTART" \
    -v "$SSH_KEY_LOCATION:/root/github_id:ro" \
    -v "$FEDORA_REMIX_LOCATION:/livecd-creator:rw" \
    -v "$CURRENT_DIR:/root/workspace:rw" \
    "$IMAGE_NAME"

