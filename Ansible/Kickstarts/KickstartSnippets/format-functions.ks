## Shared Formatting Functions for Kickstart Snippets
## This file provides consistent formatting across all installation stages

# Enable UTF-8 for Unicode support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Enhanced color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Unicode symbols
readonly CHECKMARK="✅"
readonly CROSS="❌"
readonly ARROW="➤"
readonly GEAR="⚙️"
readonly ROCKET="🚀"
readonly PACKAGE="📦"
readonly WRENCH="🔧"
readonly DOWNLOAD="📥"
readonly INSTALL="💾"
readonly CONFIG="⚙️"
readonly SUCCESS_STAR="⭐"
readonly WARNING_SIGN="⚠️"
readonly INFO_ICON="ℹ️"
readonly FIRE="🔥"
readonly SPARKLES="✨"

# Formatting functions
ks_print_header() {
    local message="$1"
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC} ${BOLD}${WHITE}%-76s${NC} ${CYAN}║${NC}\n" "$message"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

ks_print_section() {
    local message="$1"
    echo -e "\n${PURPLE}${SUCCESS_STAR}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${SUCCESS_STAR}${NC} ${BOLD}${WHITE}$message${NC}"
    echo -e "${PURPLE}${SUCCESS_STAR}═══════════════════════════════════════════════════════════════════════════════${NC}\n"
}

ks_print_info() {
    local message="$1"
    echo -e "${BLUE}${INFO_ICON}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${message}"
}

ks_print_success() {
    local message="$1"
    echo -e "${GREEN}${CHECKMARK}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${GREEN}${message}${NC}"
}

ks_print_warning() {
    local message="$1"
    echo -e "${YELLOW}${WARNING_SIGN}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${YELLOW}${message}${NC}"
}

ks_print_error() {
    local message="$1"
    echo -e "${RED}${CROSS}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} ${RED}${message}${NC}"
}

ks_print_install() {
    local package="$1"
    echo -e "${BLUE}${INSTALL}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} Installing ${GREEN}${package}${NC}..."
}

ks_print_download() {
    local item="$1"
    echo -e "${CYAN}${DOWNLOAD}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} Downloading ${GREEN}${item}${NC}..."
}

ks_print_configure() {
    local component="$1"
    echo -e "${PURPLE}${CONFIG}${NC} ${BOLD}$(date '+%H:%M:%S')${NC} Configuring ${GREEN}${component}${NC}..."
}

ks_print_step() {
    local step_num="$1"
    local total_steps="$2"
    local description="$3"
    local progress_bar=""
    local filled=$((step_num * 20 / total_steps))
    
    # Create progress bar
    for i in $(seq 1 $filled); do progress_bar+="█"; done
    for i in $(seq $((filled + 1)) 20); do progress_bar+="░"; done
    
    echo -e "${WHITE}${BOLD}[$step_num/$total_steps]${NC} ${CYAN}${progress_bar}${NC} ${description}"
}

ks_separator() {
    echo -e "${DIM}${WHITE}─────────────────────────────────────────────────────────────────────────────────${NC}"
}

ks_completion_banner() {
    local component="$1"
    echo -e "\n${GREEN}${SPARKLES}${SPARKLES}${SPARKLES}${NC} ${BOLD}${GREEN}$component installation completed successfully!${NC} ${GREEN}${SPARKLES}${SPARKLES}${SPARKLES}${NC}\n"
}
