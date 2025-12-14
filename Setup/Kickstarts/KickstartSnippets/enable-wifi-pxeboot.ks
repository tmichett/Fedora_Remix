## Enable WiFi for PXE Boot Clients
## This snippet configures NetworkManager to properly manage WiFi interfaces
## even when the system is booted via PXE with a wired connection
##
## The wired connection used for PXE/squashfs remains primary with lower metric
## WiFi can be enabled as an additional interface for internet access

ks_print_section "📶 CONFIGURING WIFI SUPPORT FOR PXE BOOT"
ks_print_info "Setting up NetworkManager to manage WiFi alongside PXE wired connection"

## Create NetworkManager configuration to ensure WiFi is always managed
mkdir -p /etc/NetworkManager/conf.d

cat > /etc/NetworkManager/conf.d/10-enable-wifi-pxeboot.conf << 'EOF'
# Enable WiFi management for PXE boot clients
# This ensures WiFi interfaces are managed by NetworkManager even when
# the wired interface was configured by dracut during PXE boot

[main]
# Use NetworkManager for DNS resolution
dns=default

[device]
# Ensure WiFi interfaces are always managed
wifi.scan-rand-mac-address=yes
# Match all WiFi devices and ensure they're managed
match-device=type:wifi
managed=1

[connection]
# Set higher route metric for WiFi (lower priority than wired)
# This ensures squashfs traffic stays on wired connection
wifi.route-metric=600
ethernet.route-metric=100

[keyfile]
# Don't mark any devices as unmanaged
unmanaged-devices=none
EOF

ks_print_info "Created NetworkManager WiFi configuration"

## Create udev rule to ensure WiFi interfaces are not blocked
cat > /etc/udev/rules.d/80-enable-wifi.rules << 'EOF'
# Ensure WiFi interfaces are enabled and not soft-blocked
# This rule runs when WiFi devices are detected

ACTION=="add", SUBSYSTEM=="net", ATTR{type}=="1", KERNEL=="wlan*", RUN+="/usr/sbin/rfkill unblock wifi"
ACTION=="add", SUBSYSTEM=="rfkill", ATTR{type}=="wlan", RUN+="/usr/sbin/rfkill unblock wifi"
EOF

ks_print_info "Created udev rules for WiFi enablement"

## Create a systemd service to ensure WiFi is enabled after PXE boot
cat > /etc/systemd/system/enable-wifi-pxeboot.service << 'EOF'
[Unit]
Description=Enable WiFi for PXE Boot Clients
After=NetworkManager.service
Wants=NetworkManager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '\
    # Unblock WiFi if soft-blocked \
    /usr/sbin/rfkill unblock wifi 2>/dev/null || true; \
    # Give NetworkManager time to initialize \
    sleep 2; \
    # Reload NetworkManager to pick up any WiFi devices \
    /usr/bin/nmcli general reload conf 2>/dev/null || true; \
    # Rescan for WiFi networks \
    /usr/bin/nmcli device wifi rescan 2>/dev/null || true; \
    # Log available WiFi interfaces \
    echo "WiFi interfaces available:"; \
    /usr/bin/nmcli device status | grep wifi || echo "No WiFi interfaces detected"; \
'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable enable-wifi-pxeboot.service

ks_print_info "Created and enabled WiFi enablement service"

## Create a helper script for users to manually enable WiFi
cat > /usr/local/bin/enable-wifi << 'EOF'
#!/bin/bash
# Helper script to enable WiFi on PXE-booted systems
# This script ensures WiFi is available without disrupting the wired PXE connection

echo "=== Enabling WiFi for PXE Boot Client ==="

# Check if running as root for rfkill operations
if [ "$EUID" -ne 0 ]; then
    echo "Note: Running without root privileges. Some operations may be skipped."
    SUDO="sudo"
else
    SUDO=""
fi

# Step 1: Unblock WiFi
echo "Step 1: Unblocking WiFi radio..."
$SUDO rfkill unblock wifi 2>/dev/null && echo "  ✓ WiFi unblocked" || echo "  - Already unblocked or no rfkill needed"

# Step 2: Reload NetworkManager configuration
echo "Step 2: Reloading NetworkManager configuration..."
$SUDO nmcli general reload conf 2>/dev/null && echo "  ✓ Configuration reloaded" || echo "  - Reload not needed"

# Step 3: Check for WiFi devices
echo "Step 3: Checking for WiFi devices..."
nmcli device status | grep -E "(wifi|WIFI)" || echo "  ! No WiFi devices found"

# Step 4: Scan for networks
echo "Step 4: Scanning for WiFi networks..."
nmcli device wifi rescan 2>/dev/null
sleep 2

# Step 5: List available networks
echo ""
echo "=== Available WiFi Networks ==="
nmcli device wifi list 2>/dev/null || echo "No networks found or WiFi not available"

echo ""
echo "=== Current Network Connections ==="
nmcli connection show --active

echo ""
echo "To connect to a WiFi network, use:"
echo "  nmcli device wifi connect <SSID> password <password>"
echo ""
echo "Note: Your wired PXE connection will remain active for squashfs access."
echo "      WiFi will be used as an additional connection with lower priority."
EOF

chmod +x /usr/local/bin/enable-wifi

ks_print_info "Created /usr/local/bin/enable-wifi helper script"

## Create desktop shortcut for easy WiFi enablement
mkdir -p /usr/share/applications
cat > /usr/share/applications/enable-wifi.desktop << 'EOF'
[Desktop Entry]
Name=Enable WiFi (PXE Boot)
Comment=Enable WiFi connectivity on PXE-booted systems
Exec=gnome-terminal -- /usr/local/bin/enable-wifi
Icon=network-wireless
Terminal=false
Type=Application
Categories=System;Settings;Network;
Keywords=wifi;wireless;network;pxe;
EOF

ks_print_info "Created desktop application for WiFi enablement"

## Add dracut configuration to NOT interfere with WiFi
cat >> /etc/dracut.conf.d/02-livenet.conf << 'EOF'

# WiFi support for PXE boot - ensure WiFi modules are available
# but don't try to configure WiFi during early boot
install_optional_items+=" /usr/sbin/rfkill "
# Include WiFi kernel modules in initramfs for post-boot use
add_drivers+=" cfg80211 mac80211 "
EOF

ks_print_info "Updated dracut configuration for WiFi module inclusion"

ks_print_success "WiFi support for PXE boot configured successfully"
ks_print_info "Users can run 'enable-wifi' or use the desktop app to activate WiFi"

