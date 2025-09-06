## Install VLC with Freeworld Plugins
echo "Installing VLC Media Player with enhanced codec support"

# Remove any conflicting VLC packages first
dnf remove -y vlc* || true

# Install VLC with freeworld plugins for better codec support
dnf install -y --allowerasing vlc vlc-plugins-freeworld

# Verify installation
if command -v vlc >/dev/null 2>&1; then
    echo "VLC Media Player installed successfully with freeworld plugins"
else
    echo "Warning: VLC installation may have failed"
fi
