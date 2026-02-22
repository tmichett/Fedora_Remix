# SELinux Permission Fix - February 22, 2026

## Problem
Container failed to start with error:
```
/entrypoint.sh: line 42: /tmp/remix_kickstart.txt: Permission denied
[FAILED] Failed to start remix-builder.service - Run Remix Builder Entrypoint.
```

## Root Cause
- `Build_Remix.sh` was bind-mounting a host temp file to `/tmp/remix_kickstart.txt`
- SELinux (in Enforcing mode) blocked write operations to the bind-mounted file
- The entrypoint.sh script tried to write to this read-only-from-SELinux-perspective file

## Solution Applied

### 1. Fedora_Remix Repository
**File:** `Build_Remix.sh` (lines 261-279)

**Changes:**
- ✅ Removed temporary file creation (`KICKSTART_FILE=$(mktemp)`)
- ✅ Removed file bind mount (`-v "$KICKSTART_FILE:/tmp/remix_kickstart.txt:rw"`)
- ✅ Now relies solely on environment variable (`-e "REMIX_KICKSTART=$SELECTED_KICKSTART"`)

### 2. RemixBuilder Repository  
**File:** `entrypoint.sh` (line 46-48)

**Changes:**
- ✅ Added graceful error handling for file write operations
- ✅ Falls back to environment variable if file write fails
- ✅ Container creates file in its own tmpfs (no SELinux issues)

**Before:**
```bash
echo "$REMIX_KICKSTART" > /tmp/remix_kickstart.txt
```

**After:**
```bash
echo "$REMIX_KICKSTART" > /tmp/remix_kickstart.txt 2>/dev/null || {
    echo "Warning: Could not write to /tmp/remix_kickstart.txt (using env var only)"
}
```

### 3. Container Rebuild
- Container rebuilt with updated entrypoint.sh
- Tagged as `ghcr.io/tmichett/fedora-remix-builder:43`
- Ready for deployment

## Testing
✅ Container now starts successfully on SELinux enforcing systems  
✅ Kickstart selection works via environment variable  
✅ No permission denied errors

## Deployment
To use the fix on other systems:

**Option 1:** Copy updated `Build_Remix.sh` (works with old containers)
```bash
# The updated Build_Remix.sh avoids the bind mount entirely
```

**Option 2:** Rebuild and push the container (recommended)
```bash
cd /home/travis/Github/RemixBuilder
./build.sh
./push.sh  # Push to GitHub Container Registry
```

**Option 3:** Pull updated container on target systems
```bash
# Container will auto-pull when running Build_Remix.sh
podman pull ghcr.io/tmichett/fedora-remix-builder:43
```

## Related Documentation
- [CHANGELOG.md](../CHANGELOG.md) - Full change history
- [LINUX_BUILD_FIX.md](../LINUX_BUILD_FIX.md) - Complete fix documentation
- [RemixBuilder/CHANGELOG.md](../../RemixBuilder/CHANGELOG.md) - Container changes

## Files Modified
```
Fedora_Remix/
  ├── Build_Remix.sh (lines 261-279)
  ├── CHANGELOG.md (new)
  ├── LINUX_BUILD_FIX.md (updated header)
  └── README.md (added changelog reference)

RemixBuilder/
  ├── entrypoint.sh (line 46-48)
  ├── CHANGELOG.md (new)
  ├── README.md (updated troubleshooting)
  └── Container rebuilt (2026-02-22)
```

## Date
**Fixed:** February 22, 2026  
**By:** AI Assistant (Cursor)  
**Tested:** Local Fedora 43 system with SELinux enforcing
