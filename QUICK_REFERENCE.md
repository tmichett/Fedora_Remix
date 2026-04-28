# Fedora Remix Builder - Quick Reference Card

## Configuration snapshot

```bash
cd /home/travis/Github/Fedora_Remix
./Update_Remix_Config.sh    # SSH path, remix dir, registry owner, Fedora + PXE; syncs root config.yml + Setup/config.yml (keep owner tmichett for ghcr.io/tmichett/…)
```

## Building an ISO

```bash
cd /home/travis/Github/Fedora_Remix
./Build_Remix.sh
```

**Build Time**: ~30 minutes  
**Output**: `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso` (~7.9 GB)

---

## Build Success Indicators

When build completes successfully, you'll see:

```
✅ 🚀 Live CD created successfully!
  🕐 Total Build Time:          30m 46s
  📦 Package Installation:     15m 42s
  🚀 ISO File Creation:        15m 4s
✅ 📦 Generated: FedoraRemix.iso (7.9G)

╔══════════════════════════════════════════════════════╗
║ BUILD COMPLETED SUCCESSFULLY!                       ║
╚══════════════════════════════════════════════════════╝
```

---

## Key Log Messages (Verify These)

✅ **Container starts with sudo** (Linux only):
```
⚠️  Loop device creation requires elevated privileges on Linux.
    Using sudo to run podman with proper device access...
```

✅ **Patches installed and verified**:
```
➤ Installing imgcreate Python patches...
  Python imgcreate location: /usr/lib/python3.14/site-packages/imgcreate
  Installed kickstart.py patch
  Installed fs.py patch (systemd /sys unmount fix)
  Clearing Python cache...
✅ ✓ Verified: fs.py patch active (3 locations)
```

✅ **Build completes**:
```
✅ Live CD created successfully!
```

---

## Emergency Cleanup

### Stop stuck container
```bash
sudo podman kill remix-builder
sudo podman rm -f remix-builder
```

### Full cleanup and restart
```bash
# Stop and remove container
sudo podman kill remix-builder 2>/dev/null
sudo podman rm -f remix-builder 2>/dev/null

# Start fresh build
cd /home/travis/Github/Fedora_Remix
./Build_Remix.sh
```

---

## Common Issues - Quick Fixes

### ❌ "/sys unmount" errors
**Status**: ✅ FIXED (November 2025)  
**Solution**: Update to latest scripts (includes Python version detection)  
**Details**: See [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md)

### ❌ "Could not extract … from config.yml"

```bash
cat config.yml
# Contemporary trees use Container_Properties.Fedora_Version + GitHub_Registry_Owner
# Image name defaults to: ghcr.io/{GitHub_Registry_Owner}/fedora-remix-builder:{Fedora_Version}
./Update_Remix_Config.sh   # if versions are out of sync
```

### ❌ Container stuck in "Stopping" state
```bash
# Find container ID
sudo podman ps -a | grep remix

# Force kill process
sudo podman inspect <container-id> --format '{{.State.Pid}}'
sudo kill -9 <PID>
sudo podman rm -f <container-id>
```

---

## Customization Files

Edit before building:

| File | Purpose |
|------|---------|
| `Setup/Kickstarts/FedoraRemix.ks` | Main configuration |
| `Setup/Kickstarts/FedoraRemixPackages.ks` | Package list |
| `Setup/Kickstarts/FedoraRemixRepos.ks` | Repositories |
| `Files/` | Custom themes/configs |

---

## Verification Commands

### Check container Python version
```bash
sudo podman exec remix-builder python3 --version
```

### Verify patches installed
```bash
sudo podman exec remix-builder grep -c "Ignore unmount errors for /sys" \
  /usr/lib/python3.14/site-packages/imgcreate/fs.py
# Should return: 3
```

### Check build progress
```bash
# Follow container logs
sudo podman logs -f remix-builder

# Or view inside container
sudo podman exec -it remix-builder bash
journalctl -u remix-builder.service -f
```

---

## File Locations

### On Host System
- **Config**: `/home/travis/Github/Fedora_Remix/config.yml`
- **Build Script**: `/home/travis/Github/Fedora_Remix/Build_Remix.sh`
- **Setup Files**: `/home/travis/Github/Fedora_Remix/Setup/`
- **Output ISO**: `/home/travis/Remix_Builder/FedoraRemix/FedoraRemix.iso`
- **Build Logs**: `/home/travis/Remix_Builder/FedoraRemix/FedoraBuild-*.log`

### Inside Container
- **Workspace**: `/root/workspace` (mounted from host current dir)
- **Build Dir**: `/livecd-creator/FedoraRemix/`
- **Web Root**: `/var/www/html/` (patch files)
- **Python Patches**: `/usr/lib/python3.XX/site-packages/imgcreate/`

---

## Build Performance

| Stage | Time | Notes |
|-------|------|-------|
| Container start | ~5s | Including systemd init |
| Preparation | ~30s | Web files, kickstart setup |
| Package install | ~15m | Varies by network speed |
| Post-scripts | ~1m | Customization scripts |
| ISO creation | ~15m | Squashfs compression |
| **Total** | **~30m** | On modern hardware |

---

## Exit Container

After build completes:

```bash
# Inside container shell
exit
# or
poweroff
```

Container auto-removes with `--rm` flag.

---

## Getting Help

1. **Check build log**: `FedoraBuild-*.log` in output directory
2. **Review systemd logs**: Inside container `journalctl -u remix-builder.service`
3. **Read documentation**: 
   - [LINUX_BUILD_FIX.md](LINUX_BUILD_FIX.md) - Detailed troubleshooting
   - [README_Scripts_Usage.md](README_Scripts_Usage.md) - Script docs
   - [README.md](README.md) - Project overview

---

**Last Updated**: November 22, 2025  
**Working Configuration**: Python 3.14, Fedora 43, Podman with sudo

