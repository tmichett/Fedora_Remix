## Configure COSMIC Desktop Initial Setup - Skip wizard and set dark mode
## COSMIC uses RON (Rust Object Notation) format for configs in ~/.config/cosmic/

ks_print_configure "COSMIC Desktop Initial Setup (Skip Wizard + Dark Mode)"

# ============================================================================
# COSMIC Initial Setup - Mark as completed to skip the Welcome wizard
# The cosmic-initial-setup binary checks for this file at startup:
#   ~/.config/cosmic-initial-setup-done
# If this file exists, the wizard exits immediately.
# ============================================================================

# Create the marker file in /etc/skel for new users
mkdir -p /etc/skel/.config
touch /etc/skel/.config/cosmic-initial-setup-done

# Also create gnome-initial-setup-done in case GNOME components are present
touch /etc/skel/.config/gnome-initial-setup-done

# ============================================================================
# COSMIC Theme Mode - Set to Dark
# COSMIC stores the dark mode setting at:
#   ~/.config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark
# Each config key is a separate file containing the value in RON format
# ============================================================================

mkdir -p /etc/skel/.config/cosmic/com.system76.CosmicTheme.Mode/v1

# Set dark mode as default (true = dark mode, false = light mode)
echo 'true' > /etc/skel/.config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark

# ============================================================================
# Apply same settings for liveuser immediately (during build)
# This ensures the live ISO boots with correct settings
# ============================================================================

mkdir -p /home/liveuser/.config/cosmic/com.system76.CosmicTheme.Mode/v1

# Copy skel cosmic config to liveuser
if [ -d /etc/skel/.config/cosmic ]; then
    cp -a /etc/skel/.config/cosmic/* /home/liveuser/.config/cosmic/ 2>/dev/null || true
fi

# Create the setup done markers for liveuser
touch /home/liveuser/.config/cosmic-initial-setup-done
touch /home/liveuser/.config/gnome-initial-setup-done

ks_print_success "COSMIC initial setup skipped, dark mode enabled"
