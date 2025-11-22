#!/bin/bash
set -e

# Script to run the Fedora Remix Builder container using Podman
# Reads SSH_Key_Location and Fedora_Remix_Location from config.yml

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

echo "Running container with:"
echo "  Image: $IMAGE_NAME"
echo "  SSH Key: $SSH_KEY_LOCATION -> ~/github_id"
echo "  Fedora Remix: $FEDORA_REMIX_LOCATION -> /livecd-creator"
echo "  Workspace: $CURRENT_DIR -> ~/workspace"

# Container name
CONTAINER_NAME="remix-builder"

# Remove existing container with the same name if it exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container: $CONTAINER_NAME"
    podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
fi

# Run the container with systemd support and loop device access
podman run --rm -it \
    --name "$CONTAINER_NAME" \
    --systemd=always \
    --privileged \
    --device-cgroup-rule='b 7:* rmw' \
    -v "$SSH_KEY_LOCATION:/root/github_id:ro" \
    -v "$FEDORA_REMIX_LOCATION:/livecd-creator:rw" \
    -v "$CURRENT_DIR:/root/workspace:rw" \
    "$IMAGE_NAME"

