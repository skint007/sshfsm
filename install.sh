#!/bin/bash

set -e

SCRIPT_NAME="sshm"
BIN_DIR="$HOME/.local/bin"
COMPLETION_DIR="/etc/bash_completion.d"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# check_root() {
#     if [[ $EUID -ne 0 ]]; then
#         log_error "This script must be run as root (use sudo)"
#         exit 1
#     fi
# }

check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for sshfs
    if ! command -v sshfs &> /dev/null; then
        missing_deps+=("sshfs")
    fi
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    # Check for fusermount
    if ! command -v fusermount &> /dev/null; then
        missing_deps+=("fuse2") # or fuse3
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        
        # Auto-install on Arch Linux
        if command -v pacman &> /dev/null; then
            log_info "Detected Arch Linux. Installing missing dependencies..."
            pacman -S --needed --noconfirm "${missing_deps[@]}"
            log_info "Dependencies installed successfully"
        else
            log_error "Please install the following dependencies manually:"
            for dep in "${missing_deps[@]}"; do
                echo "  - $dep"
            done
            echo ""
            echo "Common installation commands:"
            echo "  Arch Linux: sudo pacman -S sshfs jq"
            echo "  Ubuntu/Debian: sudo apt install sshfs jq"
            echo "  CentOS/RHEL: sudo yum install sshfs jq"
            echo "  Fedora: sudo dnf install sshfs jq"
            exit 1
        fi
    else
        log_info "All dependencies are satisfied"
    fi
}

install_script() {
    log_info "Installing $SCRIPT_NAME to $BIN_DIR..."
    
    if [[ ! -f "$SCRIPT_NAME" ]]; then
        log_error "Script file '$SCRIPT_NAME' not found in current directory"
        exit 1
    fi
    
    # Copy script to bin directory
    cp "$SCRIPT_NAME" "$BIN_DIR/$SCRIPT_NAME"
    chmod +x "$BIN_DIR/$SCRIPT_NAME"
    chown $USER:$USER "$BIN_DIR/$SCRIPT_NAME"

    log_info "Script installed to $BIN_DIR/$SCRIPT_NAME"
}

install_completion() {
    log_info "Installing bash completion..."
    
    if [[ ! -f "sshm-completion.bash" ]]; then
        log_warn "Completion file 'sshm-completion.bash' not found, skipping completion install"
        return
    fi

    if [[ -f "$COMPLETION_DIR/sshm" ]]; then
        log_info "Bash completion already installed at $COMPLETION_DIR/sshm, skipping"
        return
    fi
    
    # Create completion directory if it doesn't exist
    if [[ ! -d "$COMPLETION_DIR" ]]; then
        mkdir -p "$COMPLETION_DIR"
    fi
    
    # Install completion
    sudo cp "sshm-completion.bash" "$COMPLETION_DIR/sshm"

    log_info "Bash completion installed to $COMPLETION_DIR/sshm"
    log_info "Completion will be available in new shell sessions"
}

verify_installation() {
    log_info "Verifying installation..."
    
    if command -v "$SCRIPT_NAME" &> /dev/null; then
        local version
        version=$("$SCRIPT_NAME" --version 2>/dev/null)
        log_info "Installation successful: $version"
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

show_usage_info() {
    log_info "Installation complete!"
    echo ""
    echo "Quick start:"
    echo "  $SCRIPT_NAME --init                    # Initialize configuration"
    echo "  $SCRIPT_NAME hostname                  # Mount a server"
    echo "  $SCRIPT_NAME user@hostname             # Mount with specific user"
    echo "  $SCRIPT_NAME --help                    # Show help"
    echo ""
    echo "For bash completion to work in current session, run:"
    echo "  source $COMPLETION_DIR/sshm"
    echo ""
    echo "Configuration will be stored in: ~/.config/sshm/"
}

main() {
    echo "SSHM Installation Script"
    echo "========================"
    echo ""
    
    # check_root
    check_dependencies
    install_script
    install_completion
    verify_installation
    show_usage_info
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: sudo ./install.sh"
        echo ""
        echo "Installs sshm and its dependencies."
        echo ""
        echo "This script will:"
        echo "  1. Check for and install dependencies (sshfs, jq)"
        echo "  2. Install sshm to /usr/bin/"
        echo "  3. Install bash completion"
        echo "  4. Verify the installation"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac