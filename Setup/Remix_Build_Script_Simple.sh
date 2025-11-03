#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>
# Alternative version using tee instead of script command

## Script used to create LiveISO for the FedoraRemix based on the KS

# Function to read Fedora version from config.yml
get_fedora_version() {
    local config_file="config.yml"
    if [ -f "$config_file" ]; then
        # Extract fedora_version from YAML using grep and awk
        local version=$(grep '^fedora_version:' "$config_file" | awk '{print $2}' | tr -d '"')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "42"  # fallback default
        fi
    else
        echo "42"  # fallback default if config file not found
    fi
}

# Get version from config
FEDORA_VERSION=$(get_fedora_version)

setenforce 0

# Use tee to capture output (simpler alternative to script command)
# ISO 9660 compliant volume ID (uppercase, underscores only, no spaces/special chars)
livecd-creator --cache=/livecd-creator/package-cache -f FedoraRemix -c FedoraRemix.ks --title="FEDORA_REMIX_${FEDORA_VERSION}" 2>&1 | tee FedoraBuild-$(date +%m%d%y-%k%M).out
