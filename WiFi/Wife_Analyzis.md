# WiFi Unavailability Analysis for PXE Boot Clients

## Overview

When booting the Fedora Remix LiveUSB via PXE, WiFi configuration is not available to clients even though the live image includes all necessary WiFi packages and firmware. This document explains the technical reasons behind this limitation.

## The Core Issue: Network Interface Ownership During Live Boot

When you boot a LiveUSB image via PXE, **the network interface used for PXE boot becomes "owned" by the initramfs/dracut network stack**, which persists into the running system.

---

## Reason 1: PXE Boot Requires Network Before the Full OS Loads

The UEFI GRUB configuration specifies:

```
linuxefi vmlinuz root=live:http://192.168.0.254/livecd/squashfs.img ro rd.live.image rd.luks=0 rd.dm=0
initrdefi initrd.img
```

The `root=live:http://...` parameter means:

- Dracut must initialize networking **before** the root filesystem is available
- The `network-legacy` dracut module brings up the wired interface early in boot
- This connection must remain active throughout the entire session to access the squashfs image over HTTP

---

## Reason 2: NetworkManager Sees the Interface as "Externally Configured"

The dracut configuration in the kickstart includes:

```bash
cat > /etc/dracut.conf.d/02-livenet.conf << 'EOF'
# Ensure livenet and related modules are included for live boot
add_dracutmodules+=" livenet network-legacy dmsquash-live url-lib "
install_items+=" /usr/bin/curl /usr/bin/wget /usr/bin/getopt "
# Force include networking tools and dependencies
install_optional_items+=" /usr/bin/ping /usr/bin/dig /lib*/libnss_dns.so.* "
EOF
```

The `network-legacy` module configures the Ethernet interface before NetworkManager starts. When NetworkManager initializes, it sees:

- An already-configured, active network connection
- A connection that was established "outside" of its control
- NetworkManager typically marks such interfaces as `unmanaged` or doesn't try to modify them

---

## Reason 3: WiFi Cannot Be Initialized During Early Boot

WiFi requires:

1. **Full kernel modules and firmware loaded** - This happens after the live image is mounted
2. **User interaction for WPA/WPA2 authentication** - No mechanism exists during early boot
3. **The wireless regulatory database** - Not available in initramfs

During PXE boot, none of these are available when networking is needed. The system **must** use the wired interface that DHCP/TFTP provided.

---

## Reason 4: The Live Image May Lose Connectivity If Network Changes

Since `squashfs.img` is served over HTTP from the PXE server:

```
option routers 192.168.0.254;
option subnet-mask 255.255.255.0;
option domain-name-servers 192.168.0.254;
next-server 192.168.0.254;
```

If you switch to WiFi:

- The wired connection drops
- Any pending reads from the HTTP-hosted squashfs may fail
- The overlay filesystem could become unstable or unresponsive

---

## Summary Table

| Aspect | Why WiFi Is Blocked |
|--------|-------------------|
| **Boot Timing** | Networking must work before full OS/firmware loads |
| **Interface Ownership** | Dracut claims the wired interface; NetworkManager sees it as unmanaged |
| **Authentication** | WiFi needs WPA credentials; PXE has no mechanism for this |
| **Live Image Dependency** | squashfs is served over HTTP via the wired connection |

---

## WiFi Packages Included in the Image

Despite WiFi not working during PXE boot, the following packages ARE included in the Fedora Remix image:

```
## For Wifi and Networking
@hardware-support
NetworkManager-wifi 
iwl*
usbutils
inxi
pciutils
wireguard-tools

## Other Wifi Packages
atheros-firmware
b43-fwcutter
b43-openfwwf
brcmfmac-firmware
iwlegacy-firmware
iwlwifi-dvm-firmware
iwlwifi-mvm-firmware
libertas-firmware
mt7xxx-firmware
nxpwireless-firmware
realtek-firmware
tiwilink-firmware
atmel-firmware
zd1211-firmware
```

These packages work correctly when:
- Booting from a physical USB drive
- Installing to local storage
- Using the live image without network boot dependency

---

## Solution Implemented: WiFi Alongside Wired PXE Connection

The Fedora Remix now includes a solution that enables WiFi as an **additional** network interface while keeping the wired PXE connection active for squashfs access.

### What Was Added

A new kickstart snippet (`enable-wifi-pxeboot.ks`) has been created that:

1. **NetworkManager Configuration** (`/etc/NetworkManager/conf.d/10-enable-wifi-pxeboot.conf`):
   - Forces NetworkManager to manage all WiFi interfaces
   - Sets WiFi route metric to 600 (higher = lower priority)
   - Sets Ethernet route metric to 100 (lower = higher priority)
   - Ensures the wired connection remains primary for squashfs traffic

2. **udev Rules** (`/etc/udev/rules.d/80-enable-wifi.rules`):
   - Automatically unblocks WiFi when devices are detected
   - Prevents soft-blocking of wireless interfaces

3. **Systemd Service** (`enable-wifi-pxeboot.service`):
   - Runs after NetworkManager starts
   - Unblocks WiFi and triggers a network scan
   - Ensures WiFi is available after PXE boot completes

4. **Helper Script** (`/usr/local/bin/enable-wifi`):
   - User-friendly command to enable and configure WiFi
   - Shows available networks and connection status
   - Provides instructions for connecting

5. **Desktop Application**:
   - GUI shortcut for users to easily enable WiFi

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    PXE Boot Client                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐         ┌─────────────────┐           │
│  │  Wired (eth0)   │         │   WiFi (wlan0)  │           │
│  │  Metric: 100    │         │   Metric: 600   │           │
│  │  (Primary)      │         │   (Secondary)   │           │
│  └────────┬────────┘         └────────┬────────┘           │
│           │                           │                     │
│           ▼                           ▼                     │
│  ┌─────────────────┐         ┌─────────────────┐           │
│  │ PXE Server      │         │ Internet/       │           │
│  │ squashfs.img    │         │ Other Networks  │           │
│  │ 192.168.0.254   │         │                 │           │
│  └─────────────────┘         └─────────────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- **Wired connection**: Remains active and handles all squashfs/live image traffic
- **WiFi connection**: Available for internet access, other network resources
- **Routing**: Automatic based on metrics - wired preferred for local traffic

### Using WiFi After PXE Boot

1. **Automatic**: WiFi should be available automatically after boot
2. **Manual**: Run `enable-wifi` in a terminal, or use the "Enable WiFi (PXE Boot)" application
3. **Connect**: Use `nmcli device wifi connect <SSID> password <password>`

---

## Additional Workarounds

### 1. Use Local Boot After Initial Download (`rd.live.ram`)

Add `rd.live.ram` to the kernel boot parameters to copy the entire squashfs image to RAM:

```
linuxefi vmlinuz root=live:http://192.168.0.254/livecd/squashfs.img ro rd.live.image rd.live.ram rd.luks=0 rd.dm=0
```

**Pros:**
- HTTP connection becomes unnecessary after boot completes
- NetworkManager may be able to manage other interfaces
- Faster system performance (RAM vs network)

**Cons:**
- Requires sufficient RAM to hold the entire image
- Longer initial boot time while downloading to RAM

### 2. Configure NetworkManager to Manage All Devices

Create a custom configuration to force NetworkManager to manage WiFi devices:

```bash
# /etc/NetworkManager/conf.d/10-manage-wifi.conf
[device]
wifi.scan-rand-mac-address=yes

[keyfile]
unmanaged-devices=none
```

### 3. Use a Two-Stage Boot Process

1. PXE boot with wired connection
2. After system is fully loaded, manually configure WiFi
3. Disconnect wired connection

**Note:** This may cause system instability if the squashfs is still being accessed over HTTP.

### 4. Bridge or Bond Connections

Configure the system to use WiFi as a secondary/backup connection rather than primary, maintaining the wired connection for squashfs access.

---

## References

- Dracut documentation: https://man7.org/linux/man-pages/man7/dracut.cmdline.7.html
- NetworkManager device management: https://networkmanager.dev/docs/api/latest/
- Fedora Live Image documentation: https://docs.fedoraproject.org/en-US/quick-docs/creating-and-using-a-live-installation-image/

---

*Document created: December 2025*
*Related to: Fedora Remix PXE Boot Configuration*

