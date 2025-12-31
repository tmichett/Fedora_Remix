# Fedora Remix 43 - December 2025 (Q4 Release)

## 🚀 Release Highlights

This quarterly release includes major enhancements for WiFi support on PXE-booted clients, integrated PXE server tools, critical Anaconda installer fixes, comprehensive documentation, and VSCode extension management improvements.

---

## 📶 NEW: WiFi Support for PXE Boot Clients

Enables WiFi connectivity on PXE-booted systems while maintaining the wired connection for squashfs image access.

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                  PXE Boot Client                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐       ┌─────────────────┐         │
│  │  Wired (eth0)   │       │   WiFi (wlan0)  │         │
│  │  Metric: 100    │       │   Metric: 600   │         │
│  │  (Primary)      │       │   (Secondary)   │         │
│  └────────┬────────┘       └────────┬────────┘         │
│           ▼                         ▼                   │
│  ┌─────────────────┐       ┌─────────────────┐         │
│  │ PXE Server      │       │ Internet/Other  │         │
│  │ squashfs.img    │       │ Networks        │         │
│  └─────────────────┘       └─────────────────┘         │
└─────────────────────────────────────────────────────────┘
```

### Components Added

| Component | Purpose |
|-----------|---------|
| NetworkManager config | Manages WiFi with proper route metrics |
| udev rules | Auto-unblocks WiFi on detection |
| Systemd service | Initializes WiFi after boot |
| `/usr/local/bin/enable-wifi` | User-friendly helper script |
| Desktop application | GUI access for WiFi setup |

**New File:** `KickstartSnippets/enable-wifi-pxeboot.ks`

---

## 🌐 NEW: FedoraRemix PXE Server Tools Integration

Pre-installed containerized PXE server tools directly on the LiveCD.

### Available Commands

| Command | Description |
|---------|-------------|
| `sudo run-pxe-server` | Launch containerized PXE server |
| `sudo show-dhcp-clients` | Show connected DHCP clients |
| `sudo test-pxe-services` | Test PXE server services |

### Features
- ✅ Scripts downloaded from GitHub during build
- ✅ Symlinks in `/usr/local/bin/` for easy access
- ✅ Container pre-cached: `quay.io/tmichett/fedoraremixpxe:latest`
- ✅ Works offline immediately on boot

**New Files:**
- `KickstartSnippets/install-fedoraremix-pxe.ks`
- `KickstartSnippets/pull-pxe-container.ks`

---

## 🔧 FIX: Anaconda Installation Crashes (Fedora 43)

Resolves two critical issues preventing the Anaconda installer from working.

### Issue 1: Slitherer Browser Crash (SIGSEGV)

**Problem:** Qt WebEngine crashes during GPU initialization in VMs with VirtIO GPU.

**Fix:** Override Anaconda to use Firefox:
```ini
[User Interface]
webui_web_engine = firefox
```

### Issue 2: Locale-ID JavaScript Error

**Problem:** `findLocaleWithId()` returns undefined for missing locales, causing crashes.

**Fix:** Patch WebUI JavaScript to filter undefined values:
```bash
sed -i 's/\.map(\([a-z]\))\.sort(/\.map(\1).filter(e=>e).sort(/g' index.js
```

### Configuration

| Profile | Web Engine |
|---------|------------|
| Fedora (default) | `slitherer` (crashes in VMs) |
| **Fedora Remix** | `firefox` ✅ |

---

## 📚 NEW: Comprehensive Documentation

### Added Documents

| Document | Lines | Description |
|----------|-------|-------------|
| `Notes/Fedora_Remix_Quickstart.md` | 1,157 | Complete build and customization guide |
| `Notes/Fedora43_Install_Issues.md` | 421 | Anaconda issues technical documentation |
| `WiFi/Wife_Analyzis.md` | 254 | WiFi unavailability analysis for PXE boot |

### Quickstart Guide Covers
- Building without a container
- Version and title configuration
- Python scripts deep dive
- All 30+ kickstart snippets
- RemixBuilder container workflow
- Post-installation customization

---

## 🔄 NEW: Automated PDF Generation

GitHub Actions workflow to automatically convert documentation to PDF.

**File:** `.github/workflows/md2pdf.yml`

| Setting | Value |
|---------|-------|
| Trigger | Push to `main` or manual dispatch |
| Input | `Notes/Fedora_Remix_Quickstart.md` |
| Output | `Docs/` directory |
| Artifact | `documentation-pdfs` |

---

## 💻 NEW: VSCode Extension Management

### Added Scripts

| Script | Description |
|--------|-------------|
| `download_vscode_extensions.sh` | Download extensions from VS Marketplace |
| `update_vscode_kickstart.sh` | Update kickstart with new extensions |

### Updated Extensions List
Extensions are now managed via scripts for easier updates during the build process.

---

## 📦 NEW: Additional Packages

| Package | Description |
|---------|-------------|
| `procs` | Modern replacement for `ps` |
| `duf` | Disk usage/free utility |
| `httpie` | User-friendly HTTP client |
| `anaconda-webui` | Explicitly added for installer |

---

## 📋 Files Changed Summary

| Category | Files |
|----------|-------|
| **Kickstart Snippets** | `enable-wifi-pxeboot.ks`, `install-fedoraremix-pxe.ks`, `pull-pxe-container.ks` |
| **Main Kickstarts** | `FedoraRemix.ks`, `FedoraRemixPackages.ks`, `fedora-live-base.ks` |
| **Documentation** | `Fedora_Remix_Quickstart.md`, `Fedora43_Install_Issues.md`, `Wife_Analyzis.md`, `README.md` |
| **Scripts** | `download_vscode_extensions.sh`, `update_vscode_kickstart.sh` |
| **Workflows** | `md2pdf.yml` |

---

## 🛠️ Quick Fix for Existing Systems

### Anaconda Fixes
```bash
# Use Firefox for WebUI
sudo mkdir -p /etc/anaconda/conf.d
echo -e "[User Interface]\nwebui_web_engine = firefox" | sudo tee /etc/anaconda/conf.d/99-use-firefox-webui.conf

# Patch locale-id bug
cd /usr/share/cockpit/anaconda-webui/
sudo gunzip -k index.js.gz
sudo sed -i 's/\.map(\([a-z]\))\.sort(/\.map(\1).filter(e=>e).sort(/g' index.js
sudo rm index.js.gz && sudo gzip -k index.js
```

### Enable WiFi on PXE Boot
```bash
sudo enable-wifi
# Or connect directly:
nmcli device wifi connect <SSID> password <password>
```

---

## What's Changed

* FEAT: Add VSCode extension download script and update extensions by @tmichett in https://github.com/tmichett/Fedora_Remix/pull/171
* FEAT: WiFi for PXE Clients, PXE Tools Integration, Anaconda Fixes & Documentation by @tmichett in https://github.com/tmichett/Fedora_Remix/pull/172

**Full Changelog**: https://github.com/tmichett/Fedora_Remix/compare/Fedora43-Nov2025...Fedora43-2025Q4

