#!/bin/bash

# Get the Python path for ansible collections
INSTALL_PATH=$(ansible-galaxy collection list | grep ansible_collections | grep python | awk '{print $2}')

# Check if the INSTALL_PATH variable is not empty
if [ -z "$INSTALL_PATH" ]; then
    echo "Error: Unable to determine the Python path for ansible collections."
    exit 1
fi

echo "Using Python path: $INSTALL_PATH"

# List all installed collections and loop through them
for collection in $(ansible-galaxy collection list | awk '{print $1}' | tail -n +2); do
  echo "Upgrading collection: $collection"
  
  # Use ansible-galaxy to install the collection with the specified path
  ansible-galaxy collection install $collection --upgrade -p "$INSTALL_PATH"
done

