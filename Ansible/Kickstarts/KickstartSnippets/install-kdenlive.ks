## Install KDEnlive Video Editor
echo "Installing KDEnlive video editing software"

# Install KDEnlive after VLC is properly configured to avoid plugin conflicts
dnf install -y kdenlive

# Verify installation
if command -v kdenlive >/dev/null 2>&1; then
    echo "KDEnlive installed successfully"
else
    echo "Warning: KDEnlive installation may have failed"
fi
