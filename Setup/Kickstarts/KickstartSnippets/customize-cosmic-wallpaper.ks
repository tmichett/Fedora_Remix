## Customize COSMIC Desktop Wallpaper for Fedora Remix
## COSMIC stores background config in ~/.config/cosmic/com.system76.CosmicBackground/

ks_print_configure "COSMIC Desktop Wallpaper"

# Create wallpaper directories
mkdir -p /usr/share/backgrounds/fedora-remix
mkdir -p /usr/share/backgrounds/cosmic/fedora-remix

# Download Fedora Remix wallpapers
cd /usr/share/backgrounds/fedora-remix
wget -q http://localhost/files/f38-01-day.png -O fedora-remix-day.png
wget -q http://localhost/files/f38-01-night.png -O fedora-remix-night.png
wget -q http://localhost/files/Wallpaper.png -O fedora-remix-default.png 2>/dev/null || cp fedora-remix-day.png fedora-remix-default.png

# Copy to COSMIC backgrounds directory as well
cp -a /usr/share/backgrounds/fedora-remix/* /usr/share/backgrounds/cosmic/fedora-remix/

# Set proper permissions
chmod 644 /usr/share/backgrounds/fedora-remix/*.png
chmod 644 /usr/share/backgrounds/cosmic/fedora-remix/*.png 2>/dev/null || true

# Create COSMIC background configuration for all users via /etc/skel
# COSMIC uses RON (Rust Object Notation) format for configuration
mkdir -p /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1

# Create the background configuration (single wallpaper for all outputs)
cat > /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1/all << 'EOF'
(
    output: All,
    source: Path("/usr/share/backgrounds/fedora-remix/fedora-remix-day.png"),
    filter_by_theme: false,
    rotation_frequency: 300,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)
EOF

# Create dark mode wallpaper configuration
cat > /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1/all_dark << 'EOF'
(
    output: All,
    source: Path("/usr/share/backgrounds/fedora-remix/fedora-remix-night.png"),
    filter_by_theme: false,
    rotation_frequency: 300,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)
EOF

# Also set up for liveuser if the home directory will be created
mkdir -p /home/liveuser/.config/cosmic/com.system76.CosmicBackground/v1
cp /etc/skel/.config/cosmic/com.system76.CosmicBackground/v1/* /home/liveuser/.config/cosmic/com.system76.CosmicBackground/v1/ 2>/dev/null || true

# Create a COSMIC backgrounds XML file for the backgrounds selector (optional)
# This makes the Fedora Remix wallpapers appear in COSMIC's background picker
mkdir -p /usr/share/gnome-background-properties
cat > /usr/share/gnome-background-properties/fedora-remix-cosmic.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>Fedora Remix (Day)</name>
    <filename>/usr/share/backgrounds/fedora-remix/fedora-remix-day.png</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Fedora Remix (Night)</name>
    <filename>/usr/share/backgrounds/fedora-remix/fedora-remix-night.png</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
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

ks_print_success "COSMIC wallpaper configured"

