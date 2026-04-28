#!/bin/bash
#
# Update_Remix_Config.sh — Interactive update of Fedora version and PXE boot options
# in config.yml (container) and Setup/config.yml (remix / web prepare).
#

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONTAINER_CONFIG="$SCRIPT_DIR/config.yml"
readonly SETUP_CONFIG="$SCRIPT_DIR/Setup/config.yml"

show_usage() {
    echo "Usage: $0 [-h|--help]"
    echo ""
    echo "Prompts for Fedora release number and whether to include PXE boot files,"
    echo "then updates:"
    echo "  - config.yml              → Container_Properties.Fedora_Version"
    echo "  - Setup/config.yml        → fedora_version, include_pxeboot_files"
}

get_container_fedora_version() {
    if [ ! -f "$CONTAINER_CONFIG" ]; then
        return 1
    fi
    grep -A 20 "Container_Properties:" "$CONTAINER_CONFIG" | grep "Fedora_Version:" | awk '{print $2}' | tr -d '"'
}

get_setup_fedora_version() {
    if [ ! -f "$SETUP_CONFIG" ]; then
        return 1
    fi
    grep "^fedora_version:" "$SETUP_CONFIG" | awk '{print $2}' | tr -d '"'
}

get_include_pxeboot_setting() {
    local raw
    raw=$(grep '^include_pxeboot_files:' "$SETUP_CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
    if [ -z "$raw" ]; then
        echo ""
        return 1
    fi
    case "$(echo "$raw" | tr '[:upper:]' '[:lower:]')" in
        true|yes) echo "true" ;;
        false|no) echo "false" ;;
        *) echo "" ; return 1 ;;
    esac
}

normalize_yes_no_input() {
    local value
    value=$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)
    case "$value" in
        y|yes|true|1|on) echo "true" ;;
        n|no|false|0|off) echo "false" ;;
        *) return 1 ;;
    esac
}

validate_fedora_version() {
    local v="$1"
    if [[ ! "$v" =~ ^[0-9]+$ ]]; then
        echo "Error: Fedora version must be a positive integer (got: '$v')" >&2
        return 1
    fi
    if [ "$v" -lt 30 ] || [ "$v" -gt 99 ]; then
        echo "Error: Fedora version must be between 30 and 99 (got: $v)" >&2
        return 1
    fi
    return 0
}

write_container_fedora_version() {
    local v="$1"
    if ! grep -q '^[[:space:]]*Fedora_Version:' "$CONTAINER_CONFIG"; then
        echo "Error: No Fedora_Version: line found in $CONTAINER_CONFIG" >&2
        return 1
    fi
    sed -i "s/^\([[:space:]]*Fedora_Version:[[:space:]]*\).*/\1\"${v}\"/" "$CONTAINER_CONFIG"
}

write_setup_fedora_version() {
    local v="$1"
    if ! grep -q '^fedora_version:' "$SETUP_CONFIG"; then
        echo "Error: No fedora_version: line found in $SETUP_CONFIG" >&2
        return 1
    fi
    sed -i "s/^fedora_version:.*/fedora_version: ${v}/" "$SETUP_CONFIG"
}

write_setup_include_pxeboot() {
    local value="$1"
    if grep -q '^include_pxeboot_files:' "$SETUP_CONFIG"; then
        sed -i "s/^include_pxeboot_files:.*/include_pxeboot_files: ${value}/" "$SETUP_CONFIG"
    else
        printf '\ninclude_pxeboot_files: %s\n' "$value" >> "$SETUP_CONFIG"
    fi
}

prompt_fedora_version() {
    local default="$1"
    local input=""
    while true; do
        read -r -p "Fedora version [${default}]: " input
        if [ -z "$input" ]; then
            echo "$default"
            return
        fi
        if validate_fedora_version "$input"; then
            echo "$input"
            return
        fi
    done
}

prompt_pxe_boot() {
    local default_bool="$1"
    local prompt_suffix="[y/N]"
    [ "$default_bool" = "true" ] && prompt_suffix="[Y/n]"

    local input normalized
    while true; do
        read -r -p "Include PXE boot files in web assets? ${prompt_suffix} " input
        if [ -z "$input" ]; then
            echo "$default_bool"
            return
        fi
        normalized=$(normalize_yes_no_input "$input") || true
        if [ -n "$normalized" ]; then
            echo "$normalized"
            return
        fi
        echo "Please answer yes or no."
    done
}

main() {
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
    esac

    if [ ! -f "$CONTAINER_CONFIG" ]; then
        echo "Error: $CONTAINER_CONFIG not found." >&2
        exit 1
    fi
    if [ ! -f "$SETUP_CONFIG" ]; then
        echo "Error: $SETUP_CONFIG not found." >&2
        exit 1
    fi

    local cv sv default_ver pxe_default
    cv=$(get_container_fedora_version || true)
    sv=$(get_setup_fedora_version || true)

    if [ -n "$sv" ]; then
        default_ver="$sv"
    elif [ -n "$cv" ]; then
        default_ver="$cv"
    else
        echo "Error: Could not read fedora_version from configs." >&2
        exit 1
    fi

    if [ -n "$cv" ] && [ -n "$sv" ] && [ "$cv" != "$sv" ]; then
        echo "Note: config.yml has Fedora_Version ${cv}, Setup/config.yml has fedora_version ${sv}."
        echo "      This update will set both to the same value."
        echo ""
    fi

    pxe_default="false"
    if pxe_raw=$(get_include_pxeboot_setting); then
        if [ "$pxe_raw" = "true" ]; then
            pxe_default="true"
        fi
    fi

    echo "Update remix configuration (container + Setup)."
    echo ""

    local target_ver pxe_bool
    target_ver=$(prompt_fedora_version "$default_ver")
    pxe_bool=$(prompt_pxe_boot "$pxe_default")

    write_container_fedora_version "$target_ver"
    write_setup_fedora_version "$target_ver"
    write_setup_include_pxeboot "$pxe_bool"

    echo ""
    echo "Updated:"
    echo "  $CONTAINER_CONFIG  → Fedora_Version \"${target_ver}\""
    echo "  $SETUP_CONFIG      → fedora_version: ${target_ver}, include_pxeboot_files: ${pxe_bool}"
}

main "$@"
