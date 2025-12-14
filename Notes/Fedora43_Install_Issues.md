# Fedora 43 Remix Installation Issues

**Date:** December 14, 2025  
**Affected Version:** Fedora 43 Remix  
**Status:** Fixed

---

## Executive Summary

The Fedora 43 Remix installation was failing with multiple issues that prevented the Anaconda installer from launching properly. Two distinct problems were identified and fixed:

1. **Slitherer Browser Crash (Primary Issue):** The Slitherer browser (Qt WebEngine-based) used by Anaconda to display the WebUI crashes with a segmentation fault during GPU initialization, particularly in virtual machine environments using VirtIO GPU.

2. **Locale-ID JavaScript Error (Secondary Issue):** A bug in `anaconda-webui` where the language selection screen crashes when trying to access locale data for languages that aren't available in the system's translation files.

---

# Issue 1: Slitherer Browser Segmentation Fault

## Error Description

### Symptoms

When attempting to launch the Anaconda installer, the WebUI desktop script would crash immediately with a segmentation fault, before the installer could even display.

### Error Messages

From `journal.log`:
```
/usr/libexec/anaconda/webui-desktop: line 202: 5437 Segmentation fault (core dumped) HOME="$BROWSER_HOME" XDG_CURRENT_DESKTOP=GNOME pkexec --user $INSTALLER_USER env DISPLAY=$DISPLAY "${user_environment[@]}" "${BROWSER[@]}" http://"$WEBUI_ADDRESS""$URL_PATH"
```

```
anaconda: ui.webui: web-ui: the webui-desktop script ended abruptly!
```

### Coredump Analysis

```
Command Line: slitherer http://127.0.0.1/cockpit/@localhost/anaconda-webui/index.html
Executable: /usr/bin/slitherer
Signal: 11 (SEGV)

Stack trace of thread 5437:
#0  _ZN15QtWebEngineCore15ContentClientQt10SetGpuInfoERKN3gpu7GPUInfoE (libQt6WebEngineCore.so.6)
#1  _ZN7content25GpuDataManagerImplPrivate13UpdateGpuInfoERKN3gpu7GPUInfoERKSt8optionalIS2_E
...
```

## Root Cause

The crash occurs in `QtWebEngineCore::ContentClientQt::SetGpuInfo()` during GPU initialization. This is a known compatibility issue between:

- **Slitherer** - A Qt WebEngine-based lightweight browser used by Anaconda
- **VirtIO GPU** - The virtual GPU driver used in libvirt/QEMU/KVM virtual machines
- **Qt6 WebEngine** - The Chromium-based rendering engine

The Qt WebEngine component has difficulty initializing correctly with the VirtIO GPU driver, leading to a segmentation fault.

### Environment

The crash was observed on:
- **GPU:** Red Hat, Inc. Virtio 1.0 GPU (VirtIO)
- **VM Platform:** libvirt/QEMU/KVM
- **Slitherer Version:** 0~git20251108.d230dba-1.fc43

## Solution

### Fix: Use Firefox Instead of Slitherer

The Fedora profile defaults to using `slitherer` for the WebUI, but the Workstation profile uses `firefox`. Firefox is more stable and compatible across different graphics configurations.

**File:** `Setup/Kickstarts/FedoraRemix.ks`

Added configuration to override the web engine:

```bash
## Fix anaconda WebUI browser crash (slitherer segfaults in VMs with VirtIO GPU)
ks_print_info "Configuring anaconda to use Firefox for WebUI (fixes VM compatibility)"
mkdir -p /etc/anaconda/conf.d
cat > /etc/anaconda/conf.d/99-use-firefox-webui.conf << 'ANACONDA_CONF'
# Override web engine to use Firefox instead of slitherer
# Slitherer (Qt WebEngine) crashes with SIGSEGV in VMs due to GPU initialization issues

[User Interface]
webui_web_engine = firefox
ANACONDA_CONF
```

### Configuration Comparison

| Profile | Configuration File | Web Engine Setting |
|---------|-------------------|-------------------|
| Fedora (default) | `/etc/anaconda/profile.d/fedora.conf` | `webui_web_engine = slitherer` |
| Fedora Workstation | `/etc/anaconda/profile.d/fedora-workstation.conf` | `webui_web_engine = firefox` |
| **Fedora Remix (fixed)** | `/etc/anaconda/conf.d/99-use-firefox-webui.conf` | `webui_web_engine = firefox` |

### Manual Fix for Existing Live Systems

If you have an existing live system experiencing this issue, you can apply the fix manually:

```bash
sudo mkdir -p /etc/anaconda/conf.d
sudo tee /etc/anaconda/conf.d/99-use-firefox-webui.conf << 'EOF'
[User Interface]
webui_web_engine = firefox
EOF
```

Then restart the installer.

---

# Issue 2: Anaconda WebUI Locale-ID JavaScript Crash

**Note:** This issue may only manifest after Issue 1 (Slitherer crash) is resolved by switching to Firefox.

## Error Description

### Symptoms

When the Anaconda installer successfully launches with Firefox, it would then fail on the language selection screen with a JavaScript error:

```
TypeError: Cannot read properties of undefined (reading 'locale-id')
```

A secondary error would also appear:
```
Unable to create PID file
Anaconda is unable to create /run/user/0/anaconda.pid because the file already exists.
```

The second error was a side effect of the initial crash - when Anaconda crashes and is restarted, the PID file from the previous instance still exists.

### Error Location

The error occurred in the Anaconda WebUI's language selection screen (`InstallationLanguage.jsx`), specifically in the `findLocaleWithId()` function.

### Log Evidence

From `journal.log`:
```
anaconda-webui[4819]: anaconda-screen-language: Locale with code ar_EG.UTF-8 not found.
anaconda-webui[4826]: anaconda-screen-language: Locale with code fr_FR.UTF-8 not found.
anaconda-webui[4827]: anaconda-screen-language: Locale with code de_DE.UTF-8 not found.
anaconda-webui[4828]: anaconda-screen-language: Locale with code ja_JP.UTF-8 not found.
anaconda-webui[4829]: anaconda-screen-language: Locale with code zh_CN.UTF-8 not found.
anaconda-webui[4835]: anaconda-screen-language: Locale with code ru_RU.UTF-8 not found.
anaconda-webui[4839]: anaconda-screen-language: Locale with code es_ES.UTF-8 not found.
```

From `anaconda-webui.log`:
```
2025-12-14T14:20:12.444Z [ERROR] ComponentDidCatch: ErrorBoundary caught an error: TypeError: Cannot read properties of undefined (reading 'locale-id') [object Object]
```

---

## Root Cause Analysis

### The Bug in anaconda-webui

The Anaconda WebUI has a bug in how it handles the "Suggested Languages" list on the language selection screen.

#### Data Flow

1. **langtable.list_common_locales()** returns a hardcoded list of "common" locale codes:
   - `ar_EG.UTF-8` (Arabic - Egypt)
   - `en_US.UTF-8` (English - US)
   - `en_GB.UTF-8` (English - UK)
   - `fr_FR.UTF-8` (French - France)
   - `de_DE.UTF-8` (German - Germany)
   - `ja_JP.UTF-8` (Japanese - Japan)
   - `zh_CN.UTF-8` (Chinese - China)
   - `ru_RU.UTF-8` (Russian - Russia)
   - `es_ES.UTF-8` (Spanish - Spain)

2. **get_available_translations()** scans for `anaconda.mo` translation files in `/usr/share/locale/*/LC_MESSAGES/` and builds a list of available languages.

3. **get_language_locales()** uses langtable to get available locales for each language.

4. The WebUI builds a `languages` dictionary from these available translations and their locales.

5. The WebUI's **findLocaleWithId()** function tries to look up each common locale in the `languages` dictionary.

#### The Problem

```javascript
const findLocaleWithId = (localeCode) => {
    for (const languageId in languages) {
        const languageItem = languages[languageId];
        for (const locale of languageItem.locales) {
            if (getLocaleId(locale) === localeCode) {
                return locale;
            }
        }
    }
    error(`Locale with code ${localeCode} not found.`);
    // BUG: Returns undefined implicitly
};

const suggestedItems = commonLocales
    .map(findLocaleWithId)      // Returns undefined for missing locales
    .sort((a, b) => { ... })    // Sort continues with undefined values
    .map(locale => createMenuItem(locale, "option-common"));  // CRASH HERE!
```

When `findLocaleWithId()` doesn't find a locale, it returns `undefined`. The code then tries to access `locale["locale-id"]` on this `undefined` value, causing the crash.

#### Why Locales Were Missing

The locales were "not found" because the `languages` dictionary was built from `get_available_translations()`, which requires:
1. An `anaconda.mo` translation file for the language
2. The locale data to be available via langtable

If either of these is missing or not loading correctly in the live environment, the locale lookup fails.

---

## Solution

A multi-layered fix was implemented to address both the root cause and provide a workaround for the upstream bug.

### Fix 1: Simplified Locale Package Configuration

**File:** `Setup/Kickstarts/fedora-live-base.ks`

**Before:**
```
glibc-all-langpacks
glibc-langpack-en
glibc-langpack-de
glibc-langpack-fr
glibc-langpack-es
glibc-langpack-ja
glibc-langpack-zh
glibc-langpack-ru
glibc-langpack-ar
```

**After:**
```
# anaconda needs the locales available to run for different locales
# glibc-all-langpacks provides ALL locale data including ar_EG, fr_FR, etc.
# required by langtable.list_common_locales() used by anaconda-webui
glibc-all-langpacks
```

**Rationale:** The individual `glibc-langpack-*` packages were redundant when `glibc-all-langpacks` is installed. The `glibc-all-langpacks` package provides the complete `/usr/lib/locale/locale-archive` file containing ALL locale data. Having both could cause conflicts or confusion during package resolution.

### Fix 2: Runtime Locale Verification

**File:** `Setup/Kickstarts/FedoraRemix.ks`

Added verification to ensure locale data is available:

```bash
## Verify locale data is available for anaconda installer
ks_print_info "Verifying locale data availability"
if [ -f /usr/lib/locale/locale-archive ] || [ -f /usr/lib/locale/locale-archive.real ]; then
    ks_print_success "Locale archive found - all locales should be available"
else
    ks_print_warning "Locale archive not found - rebuilding..."
    if [ -x /usr/sbin/build-locale-archive ]; then
        /usr/sbin/build-locale-archive
    fi
fi
```

**Rationale:** This provides a safety check and fallback in case the locale archive is missing or corrupted.

### Fix 3: Anaconda-WebUI JavaScript Patch

**File:** `Setup/Kickstarts/FedoraRemix.ks`

Added a runtime patch to fix the upstream bug:

```bash
## Patch anaconda-webui to fix locale-id crash (upstream bug workaround)
ks_print_info "Applying anaconda-webui locale-id crash fix"
WEBUI_JS="/usr/share/cockpit/anaconda-webui/index.js.gz"
if [ -f "$WEBUI_JS" ]; then
    # Decompress
    gunzip -k "$WEBUI_JS" 2>/dev/null || true
    WEBUI_JS_PLAIN="${WEBUI_JS%.gz}"
    if [ -f "$WEBUI_JS_PLAIN" ]; then
        # Patch: add .filter(e=>e) after .map(X) where X is the findLocaleWithId function
        # The minified variable name changes between builds (could be r, t, etc.)
        # Use a regex that matches any single letter variable
        sed -i 's/\.map(\([a-z]\))\.sort(/\.map(\1).filter(e=>e).sort(/g' "$WEBUI_JS_PLAIN" 2>/dev/null || true
        # Re-compress
        gzip -f "$WEBUI_JS_PLAIN"
        ks_print_success "anaconda-webui patched successfully"
    fi
fi
```

**What the patch does:**

| Original Code (minified) | Patched Code |
|--------------------------|--------------|
| `.map(r).sort(...)` | `.map(r).filter(e=>e).sort(...)` |
| `.map(t).sort(...)` | `.map(t).filter(e=>e).sort(...)` |

The `.filter(e=>e)` removes any `undefined` or `null` values from the array before the sort operation, preventing the downstream crash.

**Important:** The regex pattern `\([a-z]\)` matches any single lowercase letter variable name, because the JavaScript minifier can use different variable names (`r`, `t`, `s`, etc.) in different builds. The `\1` back-reference ensures the same variable name is preserved in the replacement.

**Rationale:** Since we cannot modify the upstream anaconda-webui package directly, this patch modifies the bundled JavaScript during the ISO build process to add the missing null check.

---

## Files Modified

| File | Changes |
|------|---------|
| `Setup/Kickstarts/fedora-live-base.ks` | Simplified locale packages to only `glibc-all-langpacks` |
| `Setup/Kickstarts/FedoraRemix.ks` | Added: Firefox override config, locale verification, and anaconda-webui JavaScript patch |

### Summary of All Fixes in FedoraRemix.ks

1. **Firefox WebUI Configuration** - Creates `/etc/anaconda/conf.d/99-use-firefox-webui.conf` to use Firefox instead of Slitherer
2. **Locale Verification** - Checks that `/usr/lib/locale/locale-archive` exists and rebuilds if missing
3. **JavaScript Patch** - Patches the WebUI to filter out undefined locales

---

## Verification Steps

After rebuilding the ISO with these fixes:

1. **Build Verification**
   - [ ] ISO builds successfully without errors
   - [ ] No warnings about locale packages during build

2. **Runtime Verification**
   - [ ] Live boot completes without issues
   - [ ] Anaconda installer opens without JavaScript errors
   - [ ] Language selection screen displays correctly
   - [ ] All suggested languages appear in the list
   - [ ] Selecting different languages works correctly

3. **Installation Verification**
   - [ ] Installation completes successfully
   - [ ] Installed system boots correctly
   - [ ] Locale settings are applied correctly

---

## Technical Details

### Relevant Packages

| Package | Purpose |
|---------|---------|
| `glibc-all-langpacks` | Provides `/usr/lib/locale/locale-archive` with all locale data |
| `anaconda-core` | Provides `/usr/share/locale/*/LC_MESSAGES/anaconda.mo` translation files |
| `anaconda-webui` | Provides `/usr/share/cockpit/anaconda-webui/index.js.gz` (the WebUI) |
| `langtable` / `python3-langtable` | Provides locale/language metadata used by Anaconda |

### Key File Paths

| Path | Description |
|------|-------------|
| `/usr/lib/locale/locale-archive` | Compiled locale data archive |
| `/usr/share/locale/*/LC_MESSAGES/anaconda.mo` | Anaconda translation files |
| `/usr/share/cockpit/anaconda-webui/index.js.gz` | Anaconda WebUI JavaScript bundle |
| `/usr/lib/python3.*/site-packages/langtable/` | Langtable locale metadata |

### Upstream References

- **anaconda-webui repository:** https://github.com/rhinstaller/anaconda-webui
- **Similar fix for keyboard layouts:** Commit `82438d43f738277046f6a32fc3bb5c51c1976d3a` (Dec 3, 2025)
- **Affected file:** `src/components/localization/InstallationLanguage.jsx`

---

## Lessons Learned

1. **Hardcoded lists are fragile:** The `langtable.list_common_locales()` function returns a hardcoded list that may not match the available translations in a minimal or customized installation.

2. **Null checks are essential:** The upstream code should have filtered out undefined values or handled the case where a locale isn't found gracefully.

3. **Multiple data sources must be synchronized:** The common locales list, available translations, and locale data must all be consistent for the installer to work correctly.

4. **Package redundancy can cause issues:** Having both `glibc-all-langpacks` and individual `glibc-langpack-*` packages can lead to unexpected behavior.

---

## Future Considerations

1. **Report upstream bug:** Consider filing a bug report with the anaconda-webui project to add proper null handling in the `findLocaleWithId()` function.

2. **Monitor updates:** Watch for anaconda-webui updates that may include a fix for this issue, at which point the JavaScript patch can be removed.

3. **Test with minimal configurations:** Future remix builds should be tested with minimal locale configurations to catch similar issues early.

---

## Appendix: Full Error Trace

```
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4819]: anaconda-screen-language: Locale with code ar_EG.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4826]: anaconda-screen-language: Locale with code fr_FR.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4827]: anaconda-screen-language: Locale with code de_DE.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4828]: anaconda-screen-language: Locale with code ja_JP.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4829]: anaconda-screen-language: Locale with code zh_CN.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4835]: anaconda-screen-language: Locale with code ru_RU.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4839]: anaconda-screen-language: Locale with code es_ES.UTF-8 not found.
Dec 14 09:20:12 localhost-fedoraremix-live slitherer[4627]: TypeError: Cannot read properties of undefined (reading 'locale-id')
Dec 14 09:20:12 localhost-fedoraremix-live slitherer[4627]: ComponentDidCatch: ErrorBoundary caught an error:,TypeError: Cannot read properties of undefined (reading 'locale-id'),[object Object]
Dec 14 09:20:12 localhost-fedoraremix-live anaconda-webui[4850]: ComponentDidCatch: ErrorBoundary caught an error: TypeError: Cannot read properties of undefined (reading 'locale-id') [object Object]
```

---

*Document created: December 14, 2025*  
*Author: Travis Michette / AI Assistant*

