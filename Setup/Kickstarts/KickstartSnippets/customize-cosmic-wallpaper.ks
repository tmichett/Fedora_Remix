## Customize COSMIC Desktop Wallpaper for Fedora Remix
## COSMIC stores background config in ~/.config/cosmic/com.system76.CosmicBackground/v1/
## Each config key is stored as a separate file in that directory

ks_print_configure "COSMIC Desktop Wallpaper"

# Create wallpaper directories
mkdir -p /usr/share/backgrounds/fedora-remix

# Download Fedora Remix wallpapers
cd /usr/share/backgrounds/fedora-remix

# Primary wallpaper - the Fedora Remix penguin wallpaper
if ! wget -q http://localhost/files/Wallpaper.png -O fedora-remix-default.png; then
    ks_print_warning "Failed to download Wallpaper.png"
fi

# Set proper permissions
chmod 644 /usr/share/backgrounds/fedora-remix/*.png 2>/dev/null || true

# ============================================================================
# Create COSMIC background configuration for all users via /etc/skel
# COSMIC uses RON (Rust Object Notation) format for configuration
# Each config key is stored as a separate file:
#   ~/.config/cosmic/com.system76.CosmicBackground/v1/all
#   ~/.config/cosmic/com.system76.CosmicBackground/v1/same-on-all
# ============================================================================

mkdir -p /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1

# Create the "all" entry - this is the wallpaper config for all outputs
# The format is RON (Rust Object Notation)
cat > /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1/all << 'EOF'
(
    output: "all",
    source: Path("/usr/share/backgrounds/fedora-remix/fedora-remix-default.png"),
    filter_by_theme: false,
    rotation_frequency: 3600,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)
EOF

# Set "same-on-all" to true so all monitors use the same wallpaper
echo 'true' > /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1/same-on-all

# ============================================================================
# Set up for liveuser - critical for live system
# ============================================================================

mkdir -p /home/liveuser/.config/cosmic/com.system76.CosmicBackground/v1
cp -a /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1/* \
      /home/liveuser/.config/cosmic/com.system76.CosmicBackground/v1/ 2>/dev/null || true

# Ensure proper ownership will be set (liveuser may not exist yet during build)
# The fedora-remix-live script will handle final ownership

# ============================================================================
# Create a GNOME backgrounds XML file for the backgrounds selector (optional)
# This makes the Fedora Remix wallpapers appear in background pickers
# ============================================================================

mkdir -p /usr/share/gnome-background-properties
cat > /usr/share/gnome-background-properties/fedora-remix-cosmic.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>Fedora Remix Default</name>
    <filename>/usr/share/backgrounds/fedora-remix/fedora-remix-default.png</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
</wallpapers>
EOF

ks_print_success "COSMIC wallpaper configured with Fedora Remix branding"
