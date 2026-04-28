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
    echo "  -a, --attach             Interactive: attach to the container (podman run -it)."
    echo "                           Default is detached: build runs in background, this"
    echo "                           script streams /tmp/entrypoint.log in this terminal"
    echo "                           until the build finishes (no second window needed)."
    echo ""
    echo "If no kickstart is specified, you will be prompted to choose."
}

normalize_yes_no() {
    local value
    value=$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)
    case "$value" in
        y|yes|true|1|on)
            echo "true"
            return 0
            ;;
        n|no|false|0|off)
            echo "false"
            return 0
            ;;
    esac
    return 1
}

get_include_pxeboot_setting() {
    local setup_config="$SOURCE_DIR/Setup/config.yml"
    if [ ! -f "$setup_config" ]; then
        return 1
    fi

    local raw
    raw=$(grep '^include_pxeboot_files:' "$setup_config" | awk '{print $2}' | tr -d '"' || true)
    if [ -z "$raw" ]; then
        return 1
    fi

    normalize_yes_no "$raw"
}

write_include_pxeboot_setting() {
    local value="$1"
    local setup_config="$SOURCE_DIR/Setup/config.yml"
    if [ ! -f "$setup_config" ]; then
        return 1
    fi
    if grep -q '^include_pxeboot_files:' "$setup_config"; then
        sed -i "s/^include_pxeboot_files:.*/include_pxeboot_files: ${value}/" "$setup_config"
    else
        printf '\ninclude_pxeboot_files: %s\n' "$value" >> "$setup_config"
    fi
}

prompt_include_pxeboot() {
    local default="${1:-true}"
    local prompt_suffix="[Y/n]"
    [ "$default" = "false" ] && prompt_suffix="[y/N]"
    local input=""
    local normalized=""

    while true; do
        read -r -p "Include PXEBoot files in web assets? ${prompt_suffix}: " input
        if [ -z "$input" ]; then
            echo "$default"
            return
        fi
        normalized=$(normalize_yes_no "$input" || true)
        if [ -n "$normalized" ]; then
            echo "$normalized"
            return
        fi
        echo "Please answer yes or no."
    done
}

# Function to list available kickstarts
# Looks in the current directory (GitHub repo) for kickstart source files
list_kickstarts() {
    local source_location="$1"
    echo "Available Kickstart files:"
    echo ""
    for ks in "$source_location"/Setup/Kickstarts/FedoraRemix*.ks; do
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

# Get current working directory (source location - the GitHub repo)
CURRENT_DIR=$(pwd)
SOURCE_DIR="$CURRENT_DIR"

# Parse command line arguments
SELECTED_KICKSTART=""
# 0 = default: run detached, stream build log in this shell
ATTACH_MODE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--kickstart)
            SELECTED_KICKSTART="$2"
            shift 2
            ;;
        -a|--attach)
            ATTACH_MODE=1
            shift
            ;;
        -l|--list)
            # List kickstarts from current directory (source)
            list_kickstarts "$SOURCE_DIR"
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

# Environment override (e.g. REMIX_BUILD_ATTACH=1 ./Build_Remix.sh)
if [ "${REMIX_BUILD_ATTACH:-0}" = "1" ]; then
    ATTACH_MODE=1
fi

# Check if config.yml exists
if [ ! -f "config.yml" ]; then
    echo "Error: config.yml not found in current directory"
    echo "Please run this script from your Fedora_Remix repository directory."
    exit 1
fi

# Check if this looks like a valid Fedora Remix source directory
if [ ! -d "$SOURCE_DIR/Setup/Kickstarts" ]; then
    echo "Error: Setup/Kickstarts directory not found in current directory"
    echo "Please run this script from your Fedora_Remix repository directory."
    echo ""
    read -p "Enter alternate source directory path (or press Enter to exit): " ALT_SOURCE
    if [ -n "$ALT_SOURCE" ] && [ -d "$ALT_SOURCE/Setup/Kickstarts" ]; then
        SOURCE_DIR="$ALT_SOURCE"
    else
        echo "No valid source directory found. Exiting."
        exit 1
    fi
fi

# Extract values from config.yml
SSH_KEY_LOCATION=$(grep -A 10 "Container_Properties:" config.yml | grep "SSH_Key_Location:" | awk '{print $2}' | tr -d '"')
FEDORA_REMIX_LOCATION=$(grep -A 10 "Container_Properties:" config.yml | grep "Fedora_Remix_Location:" | awk '{print $2}' | tr -d '"')
FEDORA_VERSION=$(grep -A 10 "Container_Properties:" config.yml | grep "Fedora_Version:" | awk '{print $2}' | tr -d '"')
GITHUB_REGISTRY_OWNER=$(grep -A 10 "Container_Properties:" config.yml | grep "GitHub_Registry_Owner:" | awk '{print $2}' | tr -d '"')

if [ -z "$SSH_KEY_LOCATION" ] || [ -z "$FEDORA_REMIX_LOCATION" ] || [ -z "$FEDORA_VERSION" ] || [ -z "$GITHUB_REGISTRY_OWNER" ]; then
    echo "Error: Could not extract required values from config.yml"
    echo "Required: SSH_Key_Location, Fedora_Remix_Location, Fedora_Version, GitHub_Registry_Owner"
    exit 1
fi

# Construct Image_Name dynamically from GitHub_Registry_Owner and Fedora_Version
IMAGE_NAME="ghcr.io/${GITHUB_REGISTRY_OWNER}/fedora-remix-builder:${FEDORA_VERSION}"

# Expand ~ in paths
SSH_KEY_LOCATION="${SSH_KEY_LOCATION/#\~/$HOME}"
FEDORA_REMIX_LOCATION="${FEDORA_REMIX_LOCATION/#\~/$HOME}"

# Check if SSH key exists
if [ ! -f "$SSH_KEY_LOCATION" ]; then
    echo "Warning: SSH key not found at $SSH_KEY_LOCATION"
    echo "Container will still run, but SSH operations may fail"
fi

# Check if output location exists, create if not
if [ ! -d "$FEDORA_REMIX_LOCATION" ]; then
    echo "Output directory does not exist: $FEDORA_REMIX_LOCATION"
    read -p "Create it? (y/n): " CREATE_DIR
    if [ "$CREATE_DIR" = "y" ] || [ "$CREATE_DIR" = "Y" ]; then
        mkdir -p "$FEDORA_REMIX_LOCATION"
        echo "Created directory: $FEDORA_REMIX_LOCATION"
    else
        echo "Cannot continue without output directory. Exiting."
        exit 1
    fi
fi

# If no kickstart specified, show interactive menu (from SOURCE directory)
if [ -z "$SELECTED_KICKSTART" ]; then
    show_menu "$SOURCE_DIR"
fi

INCLUDE_PXEBOOT=""
if [ -n "${REMIX_INCLUDE_PXEBOOT:-}" ]; then
    INCLUDE_PXEBOOT=$(normalize_yes_no "$REMIX_INCLUDE_PXEBOOT" || true)
    if [ -z "$INCLUDE_PXEBOOT" ]; then
        echo "Error: Invalid REMIX_INCLUDE_PXEBOOT value: $REMIX_INCLUDE_PXEBOOT (use true/false)"
        exit 1
    fi
else
    INCLUDE_PXEBOOT=$(get_include_pxeboot_setting || true)
    if [ -z "$INCLUDE_PXEBOOT" ]; then
        INCLUDE_PXEBOOT=$(prompt_include_pxeboot "true")
    fi
fi

write_include_pxeboot_setting "$INCLUDE_PXEBOOT" || true

# Validate that the selected kickstart exists (in SOURCE directory)
if [ ! -f "$SOURCE_DIR/Setup/Kickstarts/${SELECTED_KICKSTART}.ks" ]; then
    echo "Error: Kickstart file not found: ${SELECTED_KICKSTART}.ks"
    echo "Available kickstarts:"
    list_kickstarts "$SOURCE_DIR"
    exit 1
fi

echo ""
echo -e "${MENU_CYAN}╔═══════════════════════════════════════════════════════════════════╗${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}           ${MENU_WHITE}🚀 Fedora Remix Builder Configuration${MENU_NC}              ${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}╠═══════════════════════════════════════════════════════════════════╣${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}Kickstart:${MENU_NC}    ${MENU_WHITE}${SELECTED_KICKSTART}.ks${MENU_NC}$(printf '%*s' $((40 - ${#SELECTED_KICKSTART})) '')${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}Output ISO:${MENU_NC}   ${MENU_YELLOW}${SELECTED_KICKSTART}.iso${MENU_NC}$(printf '%*s' $((39 - ${#SELECTED_KICKSTART})) '')${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}╠═══════════════════════════════════════════════════════════════════╣${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}Source:${MENU_NC}       $SOURCE_DIR$(printf '%*s' $((40 - ${#SOURCE_DIR})) '')${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}Output Dir:${MENU_NC}   $FEDORA_REMIX_LOCATION$(printf '%*s' $((40 - ${#FEDORA_REMIX_LOCATION})) '')${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}Container:${MENU_NC}    $IMAGE_NAME$(printf '%*s' $((40 - ${#IMAGE_NAME})) '')${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}║${MENU_NC}  ${MENU_GREEN}PXEBoot:${MENU_NC}      $INCLUDE_PXEBOOT$(printf '%*s' $((40 - ${#INCLUDE_PXEBOOT})) '')${MENU_CYAN}║${MENU_NC}"
echo -e "${MENU_CYAN}╚═══════════════════════════════════════════════════════════════════╝${MENU_NC}"
echo ""
echo -e "${MENU_WHITE}ISO will be created at:${MENU_NC} ${MENU_YELLOW}$FEDORA_REMIX_LOCATION/FedoraRemix/${SELECTED_KICKSTART}.iso${MENU_NC}"
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

# :z relabels bind mounts for SELinux (shared); omit on non-Linux hosts (e.g. macOS Podman VM)
VOL_Z=""
if [ "$(uname -s)" = "Linux" ]; then
    VOL_Z=",z"
fi

# After `podman run -d`, stream /tmp/entrypoint.log in the foreground (same terminal).
# Stops when /tmp/entrypoint-status exists (or legacy /tmp/entrypoint-completed) or
# remix-builder.service fails, or a max wait is exceeded.
stream_remix_entrypoint_log() {
    local name=$1
    local cap=${2:-21600}
    local waited=0
    # Wait for container and log to appear
    while [ "$waited" -lt 300 ]; do
        if $PODMAN_CMD ps -q -f "name=^${name}$" 2>/dev/null | grep -q .; then
            if $PODMAN_CMD exec "$name" test -f /tmp/entrypoint.log 2>/dev/null; then
                break
            fi
        else
            if ! $PODMAN_CMD ps -a -q -f "name=^${name}$" 2>/dev/null | grep -q .; then
                echo "Error: container ${name} is not running (exited before entrypoint log was created)."
                return 1
            fi
        fi
        sleep 1
        waited=$((waited + 1))
    done
    if [ "$waited" -ge 300 ]; then
        echo "Error: timed out waiting for /tmp/entrypoint.log in ${name}."
        return 1
    fi
    echo "Streaming build log from ${name}:/tmp/entrypoint.log (Ctrl-C stops follow only; container keeps running)..."
    set +e
    $PODMAN_CMD exec -i "$name" bash -s "$cap" <<'REMIX_STREAM'
set +e
max_s=$1
tail -n 200 -F /tmp/entrypoint.log 2>/dev/null &
TAILPID=$!
i=0
while [ "$i" -lt "$max_s" ]; do
    if [ -f /tmp/entrypoint-status ]; then break; fi
    if [ -f /tmp/entrypoint-completed ]; then break; fi
    if systemctl is-failed --quiet remix-builder.service 2>/dev/null; then break; fi
    if ! kill -0 $TAILPID 2>/dev/null; then break; fi
    i=$((i + 1))
    sleep 1
done
# Drain last lines
sleep 2
kill $TAILPID 2>/dev/null
wait $TAILPID 2>/dev/null
exit 0
REMIX_STREAM
    set -e
    local s
    s=$($PODMAN_CMD exec "$name" cat /tmp/entrypoint-status 2>/dev/null | tr -d '\r' || true)
    if [ "$s" = "ok" ]; then
        echo ""
        echo "Build entrypoint completed successfully (status: ok)."
        return 0
    fi
    if echo "$s" | grep -q '^failed:'; then
        echo ""
        echo "Build entrypoint failed (${s})."
        return 1
    fi
    if $PODMAN_CMD exec "$name" test -f /tmp/entrypoint-completed; then
        echo ""
        echo "Build entrypoint completed (entrypoint-completed; older image without entrypoint-status)."
        return 0
    fi
    echo "Could not determine final build status. Check: $PODMAN_CMD exec -it $name cat /tmp/entrypoint.log"
    return 1
}

# Run the container with systemd support and loop device access
# Do NOT use --security-opt label=disable: with host SELinux enforcing, Podman needs
# proper labels on bind mounts so setfiles inside livecd-creator can relabel the chroot.
# Volume suffix :z relabels content for shared container access (see LINUX_BUILD_FIX.md).
# --replace will automatically replace any existing container with the same name
# The /sys unmount issue is now handled gracefully by Enhanced_Remix_Build_Script.sh
# Pass the selected kickstart as an environment variable
# SOURCE_DIR is mounted as workspace (contains kickstarts, scripts, etc.)
# FEDORA_REMIX_LOCATION is mounted as output directory for ISO creation

RUN_ARGS=("--replace" "--name" "$CONTAINER_NAME" "--systemd=always" "--privileged" "${EXTRA_ARGS[@]}"
  "-e" "REMIX_KICKSTART=$SELECTED_KICKSTART"
  "-e" "REMIX_INCLUDE_PXEBOOT=$INCLUDE_PXEBOOT"
  "-v" "$SSH_KEY_LOCATION:/root/github_id:ro${VOL_Z}" "-v" "$FEDORA_REMIX_LOCATION:/livecd-creator:rw${VOL_Z}" "-v" "$SOURCE_DIR:/root/workspace:rw${VOL_Z}" "$IMAGE_NAME")

if [ "$ATTACH_MODE" = "1" ]; then
    echo "Interactive attach: build output is not auto-streamed; use tail/journal in another shell if needed."
    $PODMAN_CMD run --rm -it "${RUN_ARGS[@]}"
else
    echo "Container runs detached; this terminal will follow /tmp/entrypoint.log until the build step finishes."
    if ! $PODMAN_CMD run -d --rm "${RUN_ARGS[@]}"; then
        echo "Error: failed to start builder container"
        exit 1
    fi
    if ! stream_remix_entrypoint_log "$CONTAINER_NAME" 21600; then
        echo "The container may still be running: $PODMAN_CMD ps -a -f name=$CONTAINER_NAME"
        exit 1
    fi
    echo "Container is still running for shell inspection. Example:  $PODMAN_CMD exec -it $CONTAINER_NAME bash"
    echo "When finished, stop it with:  $PODMAN_CMD stop $CONTAINER_NAME"
fi

# Fix ownership of output files back to the invoking user.
# When sudo podman is used on Linux, the container runs as root and all files
# written to the mounted output volume are owned by root.  Restore ownership
# to the original user so they can work with the ISO without sudo.
if [ "$(uname -s)" = "Linux" ] && [ "$PODMAN_CMD" = "sudo podman" ] && [ -n "$USER" ] && [ "$USER" != "root" ]; then
    echo ""
    echo "Restoring ownership of output files to ${USER}..."
    sudo chown -R "${USER}:$(id -gn "${USER}")" "$FEDORA_REMIX_LOCATION/" 2>/dev/null || true
    echo "Done — ISO and logs now owned by ${USER}."
fi

