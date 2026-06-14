#!/bin/bash

set -e

SCRIPT_NAME="sshm"
BIN_DIR="$HOME/.local/bin"
COMPLETION_DIR="/etc/bash_completion.d"
ZSH_COMPLETION_DIR="/usr/share/zsh/site-functions"

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
    chown "$USER:$USER" "$BIN_DIR/$SCRIPT_NAME"

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

install_zsh_completion() {
    log_info "Installing zsh completion..."

    if [[ ! -f "sshm-completion.zsh" ]]; then
        log_warn "Completion file 'sshm-completion.zsh' not found, skipping zsh completion install"
        return
    fi

    if [[ -f "$ZSH_COMPLETION_DIR/_sshm" ]]; then
        log_info "Zsh completion already installed at $ZSH_COMPLETION_DIR/_sshm, skipping"
        return
    fi

    # Create completion directory if it doesn't exist
    if [[ ! -d "$ZSH_COMPLETION_DIR" ]]; then
        sudo mkdir -p "$ZSH_COMPLETION_DIR"
    fi

    # Install completion (function file must be named _sshm on $fpath)
    sudo cp "sshm-completion.zsh" "$ZSH_COMPLETION_DIR/_sshm"

    log_info "Zsh completion installed to $ZSH_COMPLETION_DIR/_sshm"
    log_info "Run 'compinit' or start a new shell, and ensure $ZSH_COMPLETION_DIR is on your \$fpath"
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
    echo "For zsh completion, ensure $ZSH_COMPLETION_DIR is on your \$fpath,"
    echo "then run 'compinit' or start a new shell."
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
    install_zsh_completion
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
        echo "  3. Install bash and zsh completion"
        echo "  4. Verify the installation"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac