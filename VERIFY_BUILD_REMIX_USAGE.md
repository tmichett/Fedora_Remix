# Verify_Build_Remix.sh - Usage Guide

**Purpose:** Pre-build verification script that checks Fedora version configuration and confirms settings before starting the ISO build process.

**Created:** April 13, 2026  
**Location:** `/home/travis/Github/Fedora_Remix/Verify_Build_Remix.sh`

---

## Overview

The `Verify_Build_Remix.sh` script is a pre-flight check tool that:

1. ✅ Verifies Fedora versions match between container and remix configurations
2. ✅ Checks if the required container image exists locally
3. ✅ Displays a clear summary of the build configuration
4. ✅ Warns about potential version mismatches
5. ✅ Confirms with the user before starting the build
6. ✅ Automatically launches `Build_Remix.sh` if approved

---

## Quick Start

### Basic Usage

```bash
cd /home/travis/Github/Fedora_Remix
./Verify_Build_Remix.sh
```

That's it! The script will:
- Check your configuration
- Display a summary
- Ask for confirmation
- Start the build if you approve

---

## What It Checks

### 1. Container Configuration (`config.yml`)

Located at: `/home/travis/Github/Fedora_Remix/config.yml`

**Checks:**
- `Fedora_Version` - The Fedora version the container is built for
- `GitHub_Registry_Owner` - Used to construct the container image name
- Constructs full image name: `ghcr.io/{owner}/fedora-remix-builder:{version}`

**Example:**
```yaml
Container_Properties:
  Fedora_Version: "43"
  GitHub_Registry_Owner: "tmichett"
```

### 2. Remix Configuration (`Setup/config.yml`)

Located at: `/home/travis/Github/Fedora_Remix/Setup/config.yml`

**Checks:**
- `fedora_version` - The Fedora version to build the remix for

**Example:**
```yaml
fedora_version: 43
```

### 3. Container Image Availability

**Checks:**
- Whether the container image exists locally (using `podman image exists`)
- Shows the image creation date if available
- Warns if the image needs to be pulled from the registry

---

## Sample Output

### Successful Verification (Versions Match)

```
╔══════════════════════════════════════════════════════════════════════╗
║ 🔍 Fedora Remix Builder - Configuration Verification
╚══════════════════════════════════════════════════════════════════════╝

ℹ️ Reading configuration files...

╔══════════════════════════════════════════════════════════════════════╗
║ Configuration Summary                                                ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  Container Configuration (config.yml)                              ║
║    Fedora Version: 43                                            ║
║    Container Image: ghcr.io/tmichett/fedora-remix-builder:43
║                                                                      ║
║  Remix Configuration (Setup/config.yml)                            ║
║    Fedora Version: 43                                            ║
║    ISO Output: FedoraRemix-43.iso                                ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

✅ Versions match! Container and Remix both use Fedora 43

ℹ️ Checking for container image...
✅ Container image found locally
  Created: 2026-04-13

╔══════════════════════════════════════════════════════════════════════╗
║ Ready to Build                                                       ║
╚══════════════════════════════════════════════════════════════════════╝

Do you want to proceed with the build? [y/N]: 
```

### Version Mismatch Warning

```
╔══════════════════════════════════════════════════════════════════════╗
║ Configuration Summary                                                ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  Container Configuration (config.yml)                              ║
║    Fedora Version: 43                                            ║
║    Container Image: ghcr.io/tmichett/fedora-remix-builder:43
║                                                                      ║
║  Remix Configuration (Setup/config.yml)                            ║
║    Fedora Version: 42                                            ║
║    ISO Output: FedoraRemix-42.iso                                ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

⚠️ Version mismatch detected!

  Container is configured for Fedora 43
  Remix is configured for Fedora 42

⚠️ This may cause build issues or unexpected results.

Recommendation: Update both config files to use the same Fedora version.
```

### Container Image Not Found

```
ℹ️ Checking for container image...
⚠️ Container image not found locally: ghcr.io/tmichett/fedora-remix-builder:43

  The image will be pulled from GitHub Container Registry during build.
  This may take several minutes depending on your internet connection.

Alternative: Build the container locally:
  cd /home/travis/Github/RemixBuilder
  ./build.sh
```

---

## User Responses

### Proceeding with Build

When you type `y` or `Y`:

```
Do you want to proceed with the build? [y/N]: y

✅ Starting build process...

ℹ️ Executing: ./Build_Remix.sh

════════════════════════════════════════════════════════════════════════

[Build process starts...]
```

### Cancelling Build

When you type `n`, `N`, or press Enter:

```
Do you want to proceed with the build? [y/N]: n

ℹ️ Build cancelled by user

To build later, run:
  cd /home/travis/Github/Fedora_Remix
  ./Build_Remix.sh

To update configuration:
  Container version: edit config.yml
  Remix version: edit Setup/config.yml
```

---

## Configuration Files Explained

### Container Configuration (`config.yml`)

This file controls which **container image** will be used to build the remix.

**Location:** `/home/travis/Github/Fedora_Remix/config.yml`

**Key Settings:**
```yaml
Container_Properties:
  Fedora_Version: "43"              # Container's Fedora version
  SSH_Key_Location: "~/.ssh/github_id"
  Fedora_Remix_Location: "/home/travis/Remix_Builder"
  GitHub_Registry_Owner: "tmichett"  # Your GitHub username/org
```

**When to Update:**
- When a new Fedora version is released
- When you want to use a different container version
- When switching between container versions for testing

### Remix Configuration (`Setup/config.yml`)

This file controls which **Fedora version** the ISO will be built for.

**Location:** `/home/travis/Github/Fedora_Remix/Setup/config.yml`

**Key Settings:**
```yaml
fedora_version: 43  # Fedora version for the remix ISO
web_root: "/var/www/html"
```

**When to Update:**
- When building a remix for a different Fedora version
- When testing different Fedora releases

---

## Best Practices

### 1. Keep Versions in Sync

**Recommended:** Always keep both versions the same.

```yaml
# config.yml
Fedora_Version: "43"

# Setup/config.yml
fedora_version: 43
```

**Why:** The container is built with specific packages and tools for a particular Fedora version. Using mismatched versions may cause:
- Package dependency conflicts
- Build failures
- Unexpected behavior in the resulting ISO

### 2. Check Before Building

**Always run the verification script before building:**

```bash
./Verify_Build_Remix.sh
```

Instead of directly running:

```bash
./Build_Remix.sh  # Skip this, use Verify_Build_Remix.sh instead
```

### 3. Update Both Files Together

When updating to a new Fedora version, keep **`Fedora_Version`** and **`fedora_version`** (and **PXE**, if you care) aligned.

**Recommended (from the Fedora_Remix repo root):**
```bash
./Update_Remix_Config.sh
```
This updates **`Container_Properties`** in root `config.yml` (`SSH_Key_Location`, `Fedora_Remix_Location`, `GitHub_Registry_Owner`, `Fedora_Version`) and `Setup/config.yml` (`fedora_version`, `include_pxeboot_files`) together. If you pull **`ghcr.io/tmichett/fedora-remix-builder`**, leave **`GitHub_Registry_Owner`** as **`tmichett`**. See [Quickstart_Container.md](Quickstart_Container.md) or [Quickstart_Physical.md](Quickstart_Physical.md).

**Manual alternative:**
1. Update `config.yml` (`Fedora_Version`)
2. Update `Setup/config.yml` (`fedora_version`, `include_pxeboot_files` as needed)

**Then verify:**
```bash
./Verify_Build_Remix.sh
```

---

## Troubleshooting

### Script Not Executable

**Error:**
```
bash: ./Verify_Build_Remix.sh: Permission denied
```

**Solution:**
```bash
chmod +x Verify_Build_Remix.sh
```

### Config File Not Found

**Error:**
```
❌ Failed to read container Fedora version from config.yml
```

**Solution:**
- Ensure you're running the script from the correct directory
- Check that `config.yml` exists in the current directory
- Check that `Setup/config.yml` exists

```bash
cd /home/travis/Github/Fedora_Remix
ls -la config.yml Setup/config.yml
```

### Container Image Not Found

**Warning:**
```
⚠️ Container image not found locally
```

**Solutions:**

**Option 1:** Let it pull automatically (slower)
- Just proceed with the build
- The image will be pulled from GitHub Container Registry
- This may take 5-15 minutes depending on your connection

**Option 2:** Build the container locally (faster for subsequent builds)
```bash
cd /home/travis/Github/RemixBuilder
./build.sh
```

**Option 3:** Pull the image manually
```bash
podman pull ghcr.io/tmichett/fedora-remix-builder:43
# or with sudo if needed
sudo podman pull ghcr.io/tmichett/fedora-remix-builder:43
```

---

## Advanced Usage

### Running Without Confirmation

If you want to skip the confirmation prompt (for automation):

```bash
# Pipe 'y' to the script
echo "y" | ./Verify_Build_Remix.sh
```

**Note:** This is not recommended for manual builds as you lose the opportunity to review the configuration.

### Checking Configuration Only

To see the configuration without building:

```bash
# Press 'n' when prompted
./Verify_Build_Remix.sh
# Type: n
```

The script will display all configuration details and exit without building.

---

## Integration with Build Process

### Recommended Workflow

```bash
# 1. Navigate to project directory
cd /home/travis/Github/Fedora_Remix

# 2. Run verification (this will also start the build if approved)
./Verify_Build_Remix.sh

# 3. Review the configuration summary
# 4. Type 'y' to proceed or 'n' to cancel
```

### Old Workflow (Not Recommended)

```bash
# Don't do this anymore:
cd /home/travis/Github/Fedora_Remix
./Build_Remix.sh  # No verification!
```

---

## What Happens After Confirmation

When you confirm the build:

1. ✅ Script displays: "Starting build process..."
2. ✅ Executes `./Build_Remix.sh` automatically
3. ✅ Build process begins with your confirmed configuration
4. ✅ All build output is displayed in real-time

The verification script essentially becomes your new entry point for building remixes.

---

## Related Documentation

- **Build Process:** See `README.md` for overall build documentation
- **Linux Fixes:** See `LINUX_BUILD_FIX.md` for known issues and fixes
- **SELinux Fix:** See `SELINUX_RELABEL_FIX.md` for the latest SELinux relabeling fix
- **Container Build:** See `/home/travis/Github/RemixBuilder/README.md` for container documentation

---

## Changelog

- **2026-04-13:** Initial version created
  - Fedora version verification
  - Container image checking
  - User confirmation workflow
  - Automatic build launching

---

## Support

If you encounter issues with the verification script:

1. Check that both config files exist and are readable
2. Verify you're in the correct directory
3. Ensure the script is executable (`chmod +x Verify_Build_Remix.sh`)
4. Check the error messages for specific guidance

For build issues after verification, see the main build documentation and troubleshooting guides.