#!/usr/bin/bash
#
# Enhanced Fedora Remix Build Script
# Travis Michette <tmichett@redhat.com>
#
# Features:
# - Colored output with Unicode symbols
# - Progress indicators
# - Enhanced logging
# - Stage separation
# - Build status tracking

# Enable UTF-8 for Unicode support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Unicode symbols
readonly CHECKMARK="✅"
readonly CROSS="❌"  
readonly ARROW="➤"
readonly GEAR="⚙️"
readonly ROCKET="🚀"
readonly PACKAGE="📦"
readonly WRENCH="🔧"
readonly CLOCK="🕐"
readonly TARGET="🎯"
readonly STAR="⭐"

# Build configuration
readonly BUILD_DATE=$(date +%m%d%y-%H%M)

# Debug: Show environment variable value
echo "DEBUG: REMIX_KICKSTART environment variable = '${REMIX_KICKSTART}'"

# Support for multiple kickstart variants via REMIX_KICKSTART environment variable
# Also check fallback file (for systemd mode where env vars may not propagate)
if [ -z "$REMIX_KICKSTART" ] && [ -f /tmp/remix_kickstart.txt ]; then
    REMIX_KICKSTART=$(cat /tmp/remix_kickstart.txt)
    echo "DEBUG: Read REMIX_KICKSTART from fallback file: ${REMIX_KICKSTART}"
fi

# Defaults to FedoraRemix if not specified
if [ -n "$REMIX_KICKSTART" ]; then
    readonly BUILD_NAME="$REMIX_KICKSTART"
    readonly KS_FILE="${REMIX_KICKSTART}.ks"
    echo "DEBUG: Using kickstart: BUILD_NAME=$BUILD_NAME, KS_FILE=$KS_FILE"
else
    readonly BUILD_NAME="FedoraRemix"
    readonly KS_FILE="FedoraRemix.ks"
    echo "DEBUG: Using default kickstart: BUILD_NAME=$BUILD_NAME, KS_FILE=$KS_FILE"
fi

readonly BUILD_LOG="${BUILD_NAME}-Build-${BUILD_DATE}.log"
readonly CACHE_DIR="/livecd-creator/package-cache"

# Function to read Fedora version from config.yml
get_fedora_version() {
    local config_file="config.yml"
    if [ -f "$config_file" ]; then
        # Extract fedora_version from YAML using grep and awk
        local version=$(grep '^fedora_version:' "$config_file" | awk '{print $2}' | tr -d '"')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "42"  # fallback default
        fi
    else
        echo "42"  # fallback default if config file not found
    fi
}

# Set build title with dynamic version (ISO 9660 compliant)
readonly FEDORA_VERSION=$(get_fedora_version)
# Create ISO-9660 compliant title (uppercase, underscores, max 32 chars)
# For variants like FedoraRemixCosmic, extract the variant name
if [ "$BUILD_NAME" = "FedoraRemix" ]; then
    readonly BUILD_TITLE="FEDORA_REMIX_${FEDORA_VERSION}"
else
    # Extract variant suffix (e.g., "Cosmic" from "FedoraRemixCosmic")
    VARIANT_SUFFIX=$(echo "$BUILD_NAME" | sed 's/FedoraRemix//')
    VARIANT_UPPER=$(echo "$VARIANT_SUFFIX" | tr '[:lower:]' '[:upper:]')
    readonly BUILD_TITLE="FEDORA_${VARIANT_UPPER}_${FEDORA_VERSION}"
fi

# Function to print formatted messages with logging
print_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local output=""
    
    case "$level" in
        "INFO")
            output="${BLUE}${ARROW}${NC} ${BOLD}[${timestamp}]${NC} ${message}"
            ;;
        "SUCCESS") 
            output="${GREEN}${CHECKMARK}${NC} ${BOLD}[${timestamp}]${NC} ${GREEN}${message}${NC}"
            ;;
        "WARNING")
            output="${YELLOW}⚠️${NC} ${BOLD}[${timestamp}]${NC} ${YELLOW}${message}${NC}"
            ;;
        "ERROR")
            output="${RED}${CROSS}${NC} ${BOLD}[${timestamp}]${NC} ${RED}${message}${NC}"
            ;;
        "STAGE")
            output="\n${PURPLE}${STAR}═══════════════════════════════════════════════════════════════════════${NC}\n${PURPLE}${STAR}${NC} ${BOLD}${WHITE}$message${NC}\n${PURPLE}${STAR}═══════════════════════════════════════════════════════════════════════${NC}\n"
            ;;
        "HEADER")
            output="\n${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}\n${CYAN}║${NC} ${BOLD}${WHITE}$message${NC}${CYAN}║${NC}\n${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}\n"
            ;;
    esac
    
    # Display with colors to terminal
    echo -e "$output"
    
    # Also log to file with colors stripped for readability
    if [ -n "$BUILD_LOG" ]; then
        echo -e "$output" | sed -r 's/\x1B\[[0-9;]*[mK]//g' >> "$BUILD_LOG"
    fi
}

# Function to show progress spinner
show_spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(((i+1) % 10))
        printf "\r${BLUE}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    printf "\r${GREEN}${CHECKMARK}${NC} ${message}\n"
}

# Function to check prerequisites
check_prerequisites() {
    print_message "STAGE" "Checking Build Prerequisites"
    
    local missing_tools=()
    
    # Check for required tools
    for tool in livecd-creator setenforce dnf; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_message "ERROR" "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_message "ERROR" "This script must be run as root"
        exit 1
    fi
    
    # Check if kickstart file exists
    if [ ! -f "$KS_FILE" ]; then
        print_message "ERROR" "Kickstart file '$KS_FILE' not found"
        exit 1
    fi
    
    print_message "SUCCESS" "All prerequisites satisfied"
}

# Function to prepare build environment
prepare_environment() {
    print_message "STAGE" "Preparing Build Environment"
    
    print_message "INFO" "${GEAR} Setting SELinux to permissive mode..."
    setenforce 0
    
    print_message "INFO" "${WRENCH} Installing imgcreate Python patches..."
    
    # Detect Python site-packages location dynamically
    PYTHON_IMGCREATE_PATH=$(python3 -c "import imgcreate; import os; print(os.path.dirname(imgcreate.__file__))" 2>/dev/null)
    if [ -z "$PYTHON_IMGCREATE_PATH" ]; then
        print_message "ERROR" "Could not find imgcreate module location!"
        exit 1
    fi
    print_message "INFO" "  Python imgcreate location: $PYTHON_IMGCREATE_PATH"
    
    # Install patched kickstart.py (if available)
    if [ -f "/var/www/html/kickstart.py" ]; then
        cp /var/www/html/kickstart.py "$PYTHON_IMGCREATE_PATH/kickstart.py" 2>/dev/null || true
        print_message "INFO" "  Installed kickstart.py patch"
    fi
    
    # Install patched fs.py (fixes /sys unmount issue in systemd containers)
    if [ -f "/var/www/html/fs.py" ]; then
        cp /var/www/html/fs.py "$PYTHON_IMGCREATE_PATH/fs.py" 2>/dev/null || true
        print_message "INFO" "  Installed fs.py patch (systemd /sys unmount fix)"
    fi
    
    # Clear Python bytecode cache to force reimport of patched modules
    print_message "INFO" "  Clearing Python cache..."
    rm -rf "$PYTHON_IMGCREATE_PATH/__pycache__"/*.pyc 2>/dev/null || true
    rm -f "$PYTHON_IMGCREATE_PATH"/*.pyc 2>/dev/null || true
    
    # Verify patches are installed
    if grep -q "Ignore unmount errors for /sys" "$PYTHON_IMGCREATE_PATH/fs.py" 2>/dev/null; then
        patch_count=$(grep -c "Ignore unmount errors for /sys" "$PYTHON_IMGCREATE_PATH/fs.py")
        print_message "SUCCESS" "  ✓ Verified: fs.py patch active ($patch_count locations)"
    else
        print_message "ERROR" "  ✗ WARNING: fs.py patch NOT found in installed location!"
        print_message "ERROR" "  Expected location: $PYTHON_IMGCREATE_PATH/fs.py"
        exit 1
    fi
    
    print_message "INFO" "${PACKAGE} Creating cache directory..."
    mkdir -p "$CACHE_DIR"
    
    print_message "INFO" "${WRENCH} Checking disk space..."
    local available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 10 ]; then
        print_message "WARNING" "Low disk space: ${available_space}GB available (recommended: 10GB+)"
    else
        print_message "SUCCESS" "Sufficient disk space: ${available_space}GB available"
    fi
}

# Function to display build information
show_build_info() {
    print_message "HEADER" "FEDORA REMIX BUILD INFORMATION"
    
    echo -e "${BOLD}Build Configuration:${NC}"
    echo -e "  ${ARROW} Build Name: ${GREEN}$BUILD_NAME${NC}"
    echo -e "  ${ARROW} Kickstart File: ${GREEN}$KS_FILE${NC}"
    echo -e "  ${ARROW} Build Title: ${GREEN}$BUILD_TITLE${NC}"
    echo -e "  ${ARROW} Cache Directory: ${GREEN}$CACHE_DIR${NC}"
    echo -e "  ${ARROW} Log File: ${GREEN}$BUILD_LOG${NC}"
    echo -e "  ${ARROW} Build Date: ${GREEN}$BUILD_DATE${NC}"
    echo ""
    
    echo -e "${BOLD}System Information:${NC}"
    echo -e "  ${ARROW} OS: ${GREEN}$(cat /etc/fedora-release 2>/dev/null || echo "Unknown")${NC}"
    echo -e "  ${ARROW} Kernel: ${GREEN}$(uname -r)${NC}"
    echo -e "  ${ARROW} Architecture: ${GREEN}$(uname -m)${NC}"
    echo -e "  ${ARROW} Memory: ${GREEN}$(free -h | awk 'NR==2{print $2}')${NC}"
    echo ""
}

# Function to run the build with enhanced output
run_build() {
    print_message "STAGE" "Starting Live CD Creation Process"
    
    local build_cmd="livecd-creator --cache=$CACHE_DIR -f $BUILD_NAME -c $KS_FILE --title=\"$BUILD_TITLE\""
    
    print_message "INFO" "${ROCKET} Launching build process..."
    print_message "INFO" "${TARGET} Command: $build_cmd"
    
    # Add build command section to log
    {
        echo ""
        echo "=============================================================="
        echo "BUILD COMMAND EXECUTION:"
        echo "=============================================================="
        echo ""
    } >> "$BUILD_LOG"
    
    # Enhanced logging approach: capture both stdout and stderr with real-time display
    print_message "INFO" "${GEAR} Starting livecd-creator with full output capture..."
    
    # Clean any existing timestamp file from previous builds
    rm -f /tmp/iso_creation_start_time.txt
    
    # Save original stdout and stderr file descriptors
    exec 3>&1 4>&2
    
    # Use exec to redirect all subsequent output to both terminal and log
    exec > >(tee -a "$BUILD_LOG") 2>&1
    
    # Run the build command directly with proper argument handling
    livecd-creator --cache="$CACHE_DIR" -f "$BUILD_NAME" -c "$KS_FILE" --title="$BUILD_TITLE"
    local build_exit_code=$?
    
    # Restore normal output (use saved file descriptors instead of /dev/tty)
    exec 1>&3 2>&4
    exec 3>&- 4>&-
    
    # Calculate actual ISO creation time from log file
    # The kickstart outputs a timestamp right before ISO creation starts
    # Look for the timestamp in the log (appears as "+ echo 1234567890" in bash debug output)
    if [ -f "$BUILD_LOG" ]; then
        # Extract the epoch timestamp from log - look for "+ echo [timestamp]" after "Preparing to build final ISO image"
        local iso_start_time=$(grep -A 10 "Preparing to build final ISO image" "$BUILD_LOG" | grep '+ echo [0-9]' | grep -o '[0-9]\{10\}' | head -1)
        
        if [ -n "$iso_start_time" ]; then
            local iso_end_time=$(date +%s)
            ISO_BUILD_TIME=$((iso_end_time - iso_start_time))
        else
            # Fallback if timestamp not found in log
            ISO_BUILD_TIME=0
        fi
    else
        # Fallback if log file not accessible
        ISO_BUILD_TIME=0
    fi
    
    return $build_exit_code
}

# Function to format time duration into human-readable format
format_duration() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$((total_seconds % 60))
    
    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${seconds}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# Function to show build results
show_build_results() {
    local exit_code=$1
    local total_duration=$2
    local iso_duration=$3
    
    print_message "STAGE" "Build Results"
    
    if [ $exit_code -eq 0 ]; then
        print_message "SUCCESS" "${ROCKET} Live CD created successfully!"
        
        # Display timing information
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC} ${BOLD}${WHITE}Build Timing Summary${NC}                                                ${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        local total_formatted=$(format_duration $total_duration)
        
        # Only show detailed breakdown if we have valid ISO timing
        if [ $iso_duration -gt 0 ]; then
            local iso_formatted=$(format_duration $iso_duration)
            local package_install_duration=$((total_duration - iso_duration))
            local package_install_formatted=$(format_duration $package_install_duration)
            
            echo -e "  ${CLOCK} ${BOLD}Total Build Time:${NC}          ${GREEN}${total_formatted}${NC} (${total_duration} seconds)"
            echo -e "  ${PACKAGE} ${BOLD}Package Installation:${NC}     ${CYAN}${package_install_formatted}${NC} (${package_install_duration} seconds)"
            echo -e "  ${ROCKET} ${BOLD}ISO File Creation:${NC}        ${YELLOW}${iso_formatted}${NC} (${iso_duration} seconds)"
        else
            echo -e "  ${CLOCK} ${BOLD}Total Build Time:${NC}          ${GREEN}${total_formatted}${NC} (${total_duration} seconds)"
            echo -e "  ${GEAR} ${BOLD}Note:${NC}                      Detailed timing unavailable (kickstart timestamp not found)"
        fi
        echo ""
        
        # Show generated files
        if ls "${BUILD_NAME}".iso &>/dev/null; then
            local iso_size=$(du -h "${BUILD_NAME}".iso 2>/dev/null | cut -f1)
            print_message "SUCCESS" "${PACKAGE} Generated: ${BUILD_NAME}.iso (${iso_size:-Unknown size})"
        fi
        
        if [ -f "$BUILD_LOG" ]; then
            local log_size=$(du -h "$BUILD_LOG" 2>/dev/null | cut -f1)
            print_message "INFO" "${WRENCH} Log file: $BUILD_LOG (${log_size:-Unknown size})"
        fi
        
        print_message "HEADER" "BUILD COMPLETED SUCCESSFULLY!"
        
    else
        print_message "ERROR" "${CROSS} Live CD creation failed!"
        print_message "ERROR" "${CLOCK} Build failed after ${total_duration} seconds"
        print_message "INFO" "${WRENCH} Check log file for details: $BUILD_LOG"
        
        print_message "HEADER" "BUILD FAILED - CHECK LOGS"
    fi
}

# Main execution function
main() {
    local start_time=$(date +%s)
    
    # Initialize log file with header information
    {
        echo "=============================================================="
        echo "FEDORA REMIX ENHANCED BUILD LOG - $(date)"
        echo "=============================================================="
        echo ""
        echo "Script: Enhanced_Remix_Build_Script.sh"
        echo "Started: $(date)"
        echo "User: $(whoami)"
        echo "Working Directory: $(pwd)"
        echo ""
        echo "=============================================================="
        echo "ENHANCED SCRIPT OUTPUT:"
        echo "=============================================================="
        echo ""
    } > "$BUILD_LOG"
    
    # Show header
    print_message "HEADER" "FEDORA REMIX ENHANCED BUILD SCRIPT"
    
    # Run build process
    check_prerequisites
    prepare_environment
    show_build_info
    
    print_message "INFO" "${CLOCK} Build started at $(date)"
    
    # Run the actual build
    run_build
    local build_result=$?
    
    # Calculate total build duration
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Show results with both total and ISO build times
    show_build_results $build_result $total_duration $ISO_BUILD_TIME
    
    # Add final log footer
    {
        echo ""
        echo "=============================================================="
        echo "BUILD COMPLETED: $(date)"
        echo "Exit Code: $build_result"
        echo "Total Duration: ${total_duration} seconds ($(format_duration $total_duration))"
        if [ $ISO_BUILD_TIME -gt 0 ]; then
            echo "Package Installation + Post Scripts: $((total_duration - ISO_BUILD_TIME)) seconds ($(format_duration $((total_duration - ISO_BUILD_TIME))))"
            echo "Actual ISO File Creation: ${ISO_BUILD_TIME} seconds ($(format_duration $ISO_BUILD_TIME))"
        else
            echo "Note: Detailed timing breakdown unavailable"
        fi
        echo "=============================================================="
    } >> "$BUILD_LOG"
    
    print_message "INFO" "${WRENCH} Complete build log saved to: $BUILD_LOG"
    
    # Exit with same code as the build
    exit $build_result
}

# Trap to ensure clean exit
trap 'print_message "ERROR" "Build interrupted!"; exit 130' INT TERM

# Run main function
main "$@"
