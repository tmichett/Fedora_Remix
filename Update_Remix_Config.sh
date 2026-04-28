#!/bin/bash
#
# Update_Remix_Config.sh — Interactive update of Fedora version, PXE options, and container
# properties in config.yml plus Setup/config.yml remix settings.
#

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONTAINER_CONFIG="$SCRIPT_DIR/config.yml"
readonly SETUP_CONFIG="$SCRIPT_DIR/Setup/config.yml"

show_usage() {
    echo "Usage: $0 [-h|--help]"
    echo ""
    echo "Interactively updates:"
    echo "  - config.yml              → Fedora_Version, SSH_Key_Location, Fedora_Remix_Location,"
    echo "                              GitHub_Registry_Owner (under Container_Properties)"
    echo "  - Setup/config.yml        → fedora_version, include_pxeboot_files"
    echo ""
    echo "Press Enter at any prompt to keep the current file value shown in [brackets]."
}

# Rewrite one Container_Properties scalar line (YAML double-quoted value). Uses Python so
# paths and registry names are substituted safely without sed delimiter issues.
_yaml_set_container_field() {
    local key="$1" value="$2"
    python3 - "$CONTAINER_CONFIG" "$key" "$value" <<'PY'
import pathlib, re, sys

path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]


def dq(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


text = path.read_text(encoding="utf-8")
pat = rf"(^[\t ]*){re.escape(key)}:[^\n]*"

def repl(m: re.Match) -> str:
    indent = m.group(1)
    return indent + key + ": " + dq(value)


after, count = re.subn(pat, repl, text, count=1, flags=re.MULTILINE)
if count != 1:
    sys.stderr.write(f"Error: Expected exactly one '{key}' under Container_Properties in {path}\n")
    sys.exit(1)
path.write_text(after, encoding="utf-8")
PY
}

get_container_field() {
    local key="$1"
    if [ ! -f "$CONTAINER_CONFIG" ]; then
        return 1
    fi
    grep -A 30 "Container_Properties:" "$CONTAINER_CONFIG" | grep "^[[:space:]]*${key}:" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"'
}

get_container_fedora_version() {
    get_container_field Fedora_Version || true
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
    _yaml_set_container_field Fedora_Version "$1"
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

prompt_with_default() {
    local label="$1" default="$2"
    local input=""
    while true; do
        read -r -p "${label} [${default}]: " input
        if [ -z "$input" ]; then
            echo "$default"
            return
        fi
        echo "$input"
        return
    done
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

    local ssh_def remix_def owner_def cv sv default_ver pxe_default
    ssh_def=$(get_container_field SSH_Key_Location || true)
    remix_def=$(get_container_field Fedora_Remix_Location || true)
    owner_def=$(get_container_field GitHub_Registry_Owner || true)

    if [ -z "$ssh_def" ]; then
        ssh_def='~/.ssh/github_id'
    fi
    if [ -z "$remix_def" ]; then
        remix_def="/home/travis/Remix_Builder"
    fi
    if [ -z "$owner_def" ]; then
        owner_def="tmichett"
    fi

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
        echo "      Fedora version prompts below set both to the same value."
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

    echo "Container properties (saved in config.yml)."
    echo ""
    local ssh_val remix_val owner_val target_ver pxe_bool
    ssh_val=$(prompt_with_default "SSH_Key_Location (git/SSH mount for the builder)" "$ssh_def")
    remix_val=$(prompt_with_default "Fedora_Remix_Location (host path for ISO/workspace bind)" "$remix_def")
    echo ""
    echo "If you use the publisher images from ghcr.io/tmichett/fedora-remix-builder,"
    echo "leave GitHub_Registry_Owner as tmichett so pulls match the published registry."
    echo ""
    owner_val=$(prompt_with_default "GitHub_Registry_Owner (GHCR namespace for the builder image)" "$owner_def")
    echo ""

    target_ver=$(prompt_fedora_version "$default_ver")
    pxe_bool=$(prompt_pxe_boot "$pxe_default")

    _yaml_set_container_field SSH_Key_Location "$ssh_val"
    _yaml_set_container_field Fedora_Remix_Location "$remix_val"
    _yaml_set_container_field GitHub_Registry_Owner "$owner_val"
    write_container_fedora_version "$target_ver"
    write_setup_fedora_version "$target_ver"
    write_setup_include_pxeboot "$pxe_bool"

    echo ""
    echo "Updated:"
    echo "  $CONTAINER_CONFIG"
    echo "    → Fedora_Version \"${target_ver}\""
    echo "    → SSH_Key_Location \"${ssh_val}\""
    echo "    → Fedora_Remix_Location \"${remix_val}\""
    echo "    → GitHub_Registry_Owner \"${owner_val}\""
    echo "  $SETUP_CONFIG → fedora_version: ${target_ver}, include_pxeboot_files: ${pxe_bool}"
}

main "$@"
