#!/bin/bash
#
# Build_Remix_Physical.sh
# Native (non-container) Fedora Remix build: update Setup/config.yml, run
# prepare scripts, then livecd-creator via Enhanced_Remix_Build_Script.sh
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
readonly NC='\033[0m'

readonly CHECKMARK="✅"
readonly CROSS="❌"
readonly WARNING="⚠️"
readonly INFO="ℹ️"
readonly ROCKET="🚀"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SETUP_DIR="$SCRIPT_DIR/Setup"
readonly SETUP_CONFIG="$SETUP_DIR/config.yml"
readonly LIVECD_WORKDIR="/livecd-creator/FedoraRemix"
readonly PREPARE_BUILD="$SETUP_DIR/Prepare_Fedora_Remix_Build.py"
readonly PREPARE_WEB="$SETUP_DIR/Prepare_Web_Files.py"
readonly ENHANCED_SCRIPT="$SETUP_DIR/Enhanced_Remix_Build_Script.sh"

SELECTED_KICKSTART=""

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

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Interactive native build: sets fedora_version in Setup/config.yml,"
    echo "runs Prepare_Fedora_Remix_Build.py and Prepare_Web_Files.py, then"
    echo "Enhanced_Remix_Build_Script.sh under ${LIVECD_WORKDIR}."
    echo ""
    echo "Options:"
    echo "  -v, --version <n>     Fedora release number (e.g. 43). If omitted, you are prompted."
    echo "  -k, --kickstart <name> Kickstart base name without .ks (e.g. FedoraRemixCosmic)"
    echo "  -l, --list            List available kickstart files"
    echo "  -h, --help            Show this help"
    echo ""
    echo "Must be run on the machine where /livecd-creator will be used; prepare"
    echo "and build steps require root (sudo)."
}

list_kickstarts() {
    local base="$1"
    echo "Available kickstart base names:"
    echo ""
    for ks in "$base"/Setup/Kickstarts/FedoraRemix*.ks; do
        if [ -f "$ks" ]; then
            basename "$ks" .ks
        fi
    done
}

show_kickstart_menu() {
    local remix_location="$1"
    local kickstarts=()
    local i=1

    if [ -f "$remix_location/Setup/Kickstarts/FedoraRemix.ks" ]; then
        kickstarts+=("FedoraRemix")
    fi

    for ks in "$remix_location"/Setup/Kickstarts/FedoraRemix*.ks; do
        if [ -f "$ks" ]; then
            local name
            name=$(basename "$ks" .ks)
            if [[ "$name" != *"Packages"* ]] && [[ "$name" != *"Repos"* ]] && [ "$name" != "FedoraRemix" ]; then
                kickstarts+=("$name")
            fi
        fi
    done

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}${ROCKET}  Fedora Remix — Kickstart Selection (physical)${NC}     ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"

    for name in "${kickstarts[@]}"; do
        if [ "$name" = "FedoraRemix" ]; then
            echo -e "${CYAN}║${NC}  ${GREEN}$i)${NC} ${WHITE}$name${NC}$(printf '%*s' $((39 - ${#name})) '')${YELLOW}[DEFAULT]${NC} ${CYAN}║${NC}"
        else
            echo -e "${CYAN}║${NC}  ${GREEN}$i)${NC} $name$(printf '%*s' $((49 - ${#name})) '')${CYAN}║${NC}"
        fi
        ((i++)) || true
    done

    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        read -r -p "Select kickstart (1-${#kickstarts[@]}) [Enter=default]: " choice
        if [ -z "$choice" ]; then
            SELECTED_KICKSTART="FedoraRemix"
            echo "Using default: FedoraRemix"
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#kickstarts[@]}" ]; then
            SELECTED_KICKSTART="${kickstarts[$((choice - 1))]}"
            break
        else
            echo "Invalid selection. Enter 1-${#kickstarts[@]} or press Enter for default."
        fi
    done
}

get_remix_fedora_version() {
    if [ ! -f "$SETUP_CONFIG" ]; then
        echo "ERROR: Setup/config.yml not found"
        return 1
    fi
    local version
    version=$(grep "^fedora_version:" "$SETUP_CONFIG" | awk '{print $2}' | tr -d '"')
    if [ -z "$version" ]; then
        echo "ERROR: Could not extract fedora_version from Setup/config.yml"
        return 1
    fi
    echo "$version"
}

validate_fedora_version() {
    local v="$1"
    if [[ ! "$v" =~ ^[0-9]+$ ]]; then
        print_message "ERROR" "Fedora version must be a positive integer (got: '$v')"
        return 1
    fi
    if [ "$v" -lt 30 ] || [ "$v" -gt 99 ]; then
        print_message "ERROR" "Fedora version must be between 30 and 99 (got: $v)"
        return 1
    fi
    return 0
}

write_setup_fedora_version() {
    local v="$1"
    if ! grep -q '^fedora_version:' "$SETUP_CONFIG"; then
        print_message "ERROR" "No fedora_version: line found in $SETUP_CONFIG"
        return 1
    fi
    sed -i "s/^fedora_version:.*/fedora_version: ${v}/" "$SETUP_CONFIG"
}

require_file() {
    local path="$1"
    local label="$2"
    if [ ! -f "$path" ]; then
        print_message "ERROR" "$label not found: $path"
        exit 1
    fi
}

check_prerequisites() {
    print_message "INFO" "Checking repository layout and scripts..."

    if [ ! -d "$SETUP_DIR/Kickstarts" ]; then
        print_message "ERROR" "Setup/Kickstarts not found under $SCRIPT_DIR"
        exit 1
    fi

    require_file "$SETUP_CONFIG" "Setup/config.yml"
    require_file "$PREPARE_BUILD" "Prepare_Fedora_Remix_Build.py"
    require_file "$PREPARE_WEB" "Prepare_Web_Files.py"
    require_file "$ENHANCED_SCRIPT" "Enhanced_Remix_Build_Script.sh"

    if [ ! -x "$ENHANCED_SCRIPT" ]; then
        print_message "WARNING" "Enhanced_Remix_Build_Script.sh is not executable; chmod +x"
        chmod +x "$ENHANCED_SCRIPT"
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        print_message "ERROR" "sudo is required for prepare and build steps"
        exit 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        print_message "ERROR" "python3 is required to run prepare scripts"
        exit 1
    fi

    print_message "SUCCESS" "Prerequisites OK"
}

parse_args() {
    FEDORA_VERSION_ARG=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                FEDORA_VERSION_ARG="$2"
                shift 2
                ;;
            -k|--kickstart)
                SELECTED_KICKSTART="$2"
                shift 2
                ;;
            -l|--list)
                list_kickstarts "$SCRIPT_DIR"
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_message "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

prompt_fedora_version() {
    local current="$1"
    local input=""

    echo ""
    read -r -p "$(echo -e "${BOLD}${WHITE}Fedora remix release to build [${current}]: ${NC}")" input
    if [ -z "$input" ]; then
        echo "$current"
        return
    fi
    echo "$input"
}

main() {
    parse_args "$@"

    echo ""
    print_message "HEADER" "${ROCKET} Fedora Remix — Physical (native) build"
    echo ""

    check_prerequisites

    local current_version
    current_version=$(get_remix_fedora_version) || exit 1

    local target_version
    if [ -n "$FEDORA_VERSION_ARG" ]; then
        target_version="$FEDORA_VERSION_ARG"
        validate_fedora_version "$target_version" || exit 1
    else
        print_message "INFO" "Current fedora_version in Setup/config.yml: ${WHITE}${current_version}${NC}"
        target_version=$(prompt_fedora_version "$current_version")
        validate_fedora_version "$target_version" || exit 1
    fi

    if [ -z "$SELECTED_KICKSTART" ]; then
        show_kickstart_menu "$SCRIPT_DIR"
    fi

    if [ ! -f "$SETUP_DIR/Kickstarts/${SELECTED_KICKSTART}.ks" ]; then
        print_message "ERROR" "Kickstart not found: Setup/Kickstarts/${SELECTED_KICKSTART}.ks"
        list_kickstarts "$SCRIPT_DIR"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC} ${WHITE}Build summary (physical)${NC}                                             ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Setup/config.yml${NC}  fedora_version → ${WHITE}${target_version}${NC}                          ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Kickstart${NC}         ${WHITE}${SELECTED_KICKSTART}.ks${NC}                                  ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Work directory${NC}    ${WHITE}${LIVECD_WORKDIR}${NC}                              ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    read -r -p "$(echo -e "${BOLD}${WHITE}Proceed with config update, prepare scripts, and build? [y/N]: ${NC}")" -n 1 -r
    echo ""
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "INFO" "Cancelled."
        exit 0
    fi

    write_setup_fedora_version "$target_version"
    print_message "SUCCESS" "Updated $SETUP_CONFIG (fedora_version: $target_version)"

    print_message "INFO" "Running Prepare_Fedora_Remix_Build.py (sudo python3, cwd: Setup)..."
    (cd "$SETUP_DIR" && sudo python3 ./Prepare_Fedora_Remix_Build.py)

    print_message "INFO" "Running Prepare_Web_Files.py (sudo python3, cwd: Setup)..."
    (cd "$SETUP_DIR" && sudo python3 ./Prepare_Web_Files.py)

    if [ ! -d "$LIVECD_WORKDIR" ]; then
        print_message "ERROR" "Expected directory missing after prepare: $LIVECD_WORKDIR"
        exit 1
    fi

    if [ ! -f "$LIVECD_WORKDIR/Enhanced_Remix_Build_Script.sh" ]; then
        print_message "ERROR" "Enhanced_Remix_Build_Script.sh not found under $LIVECD_WORKDIR"
        exit 1
    fi

    print_message "INFO" "Starting livecd build in $LIVECD_WORKDIR (REMIX_KICKSTART=${SELECTED_KICKSTART})..."
    echo ""
    (cd "$LIVECD_WORKDIR" && sudo env REMIX_KICKSTART="$SELECTED_KICKSTART" ./Enhanced_Remix_Build_Script.sh)
    local build_rc=$?

    echo ""
    if [ "$build_rc" -eq 0 ]; then
        print_message "SUCCESS" "Build finished successfully (exit $build_rc)."
    else
        print_message "ERROR" "Build failed with exit code $build_rc"
    fi
    exit "$build_rc"
}

main "$@"
