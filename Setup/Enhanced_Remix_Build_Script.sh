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
readonly BUILD_LOG="FedoraBuild-${BUILD_DATE}.log"
readonly BUILD_NAME="FedoraRemix"
readonly KS_FILE="FedoraRemix.ks"
readonly CACHE_DIR="/livecd-creator/package-cache"
readonly BUILD_TITLE="Travis's Fedora Remix 42"

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
    
    # Use exec to redirect all subsequent output to both terminal and log
    exec > >(tee -a "$BUILD_LOG") 2>&1
    
    # Run the build command directly with proper argument handling
    livecd-creator --cache="$CACHE_DIR" -f "$BUILD_NAME" -c "$KS_FILE" --title="$BUILD_TITLE"
    local build_exit_code=$?
    
    # Restore normal output
    exec > /dev/tty 2>&1
    
    return $build_exit_code
}

# Function to show build results
show_build_results() {
    local exit_code=$1
    local build_duration=$2
    
    print_message "STAGE" "Build Results"
    
    if [ $exit_code -eq 0 ]; then
        print_message "SUCCESS" "${ROCKET} Live CD created successfully!"
        print_message "INFO" "${CLOCK} Build completed in ${build_duration} seconds"
        
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
        print_message "ERROR" "${CLOCK} Build failed after ${build_duration} seconds"
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
    
    # Calculate build duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Show results
    show_build_results $build_result $duration
    
    # Add final log footer
    {
        echo ""
        echo "=============================================================="
        echo "BUILD COMPLETED: $(date)"
        echo "Exit Code: $build_result"
        echo "Duration: ${duration} seconds"
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
