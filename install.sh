#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Visual styling helper functions
print_status() {
    echo -e "\e[1;34m[capsule-dots]\e[0m $1"
}

print_success() {
    echo -e "\e[1;32m[✔]\e[0m $1"
}

print_error() {
    echo -e "\e[1;31m[✘]\e[0m $1" >&2
}

# Clear and header
clear 2>/dev/null || true
echo -e "\e[1;35m💊 capsule-dots - Dependency Installer\e[0m"
echo -e "----------------------------------------"

# 1. Detect operating system
print_status "Detecting operating system..."
OS=""
if [[ -f /etc/os-release ]]; then
    # Read OS release info in subshell to avoid polluting global environment
    OS_ID=$(bash -c '. /etc/os-release && echo "${ID:-}"')
    OS_LIKE=$(bash -c '. /etc/os-release && echo "${ID_LIKE:-}"')
    if [[ "$OS_ID" == "arch" || "$OS_LIKE" =~ "arch" ]]; then
        OS="arch"
    elif [[ "$OS_ID" == "fedora" || "$OS_LIKE" =~ "fedora" ]]; then
        OS="fedora"
    fi
fi

if [[ -z "$OS" ]]; then
    if command -v pacman &>/dev/null; then
        OS="arch"
    elif command -v dnf &>/dev/null; then
        OS="fedora"
    else
        print_error "Unsupported distribution. Only Arch Linux and Fedora are supported."
        exit 1
    fi
fi

print_success "Detected operating system: \e[1;36m$OS\e[0m"

# 2. Setup distribution specific settings and package manager
AUR_HELPER=""
SUDO=""
if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
fi

if [[ "$OS" == "arch" ]]; then
    print_status "Detecting AUR helper..."
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    fi

    if [[ -z "$AUR_HELPER" ]]; then
        print_error "Neither 'paru' nor 'yay' was found on your system."
        print_error "An AUR helper is required to install dependencies on Arch Linux."
        print_error "Please install paru or yay and run this installer again."
        exit 1
    fi

    print_success "Found AUR helper: \e[1;36m$AUR_HELPER\e[0m"

    DEPENDENCIES=(
        "hyprland"
        "kitty"
        "fish"
        "networkmanager"
        "pipewire"
        "wireplumber"
        "upower"
        "libpulse"
        "polkit"
        "playerctl"
        "gsettings-desktop-schemas"
        "nautilus"
        "hyprshot"
        "zen-browser"
        "yazi"
        "cliphist"
        "cpupower"
        "hyprlock"
        "qt5ct"
        "qt6ct"
        "xdg-desktop-portal-gtk"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal"
    )
elif [[ "$OS" == "fedora" ]]; then
    # Enable Fedora COPR repositories
    print_status "Enabling required COPR repositories for Fedora..."
    FEDORA_COPRS=(
        "solopasha/hyprland"
        "sneexy/zen-browser"
        "lihaohong/yazi"
    )

    for copr in "${FEDORA_COPRS[@]}"; do
        print_status "Enabling COPR: $copr..."
        if $SUDO dnf copr enable -y "$copr"; then
            print_success "COPR repository '$copr' enabled."
        else
            print_error "Failed to enable COPR repository '$copr'. Some packages might not be available."
        fi
    done

    DEPENDENCIES=(
        "hyprland"
        "kitty"
        "fish"
        "NetworkManager"
        "pipewire"
        "wireplumber"
        "upower"
        "pulseaudio-libs"
        "polkit"
        "playerctl"
        "gsettings-desktop-schemas"
        "nautilus"
        "hyprshot"
        "zen-browser"
        "yazi"
        "cliphist"
        "kernel-tools"
        "hyprlock"
        "qt5ct"
        "qt6ct"
        "xdg-desktop-portal-gtk"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal"
    )
fi

# 3. Check package installation status
print_status "Checking package status..."
TO_INSTALL=()

check_package_installed() {
    local pkg="$1"
    if [[ "$OS" == "arch" ]]; then
        "$AUR_HELPER" -Qq "$pkg" &>/dev/null
    elif [[ "$OS" == "fedora" ]]; then
        rpm -q "$pkg" &>/dev/null
    fi
}

for pkg in "${DEPENDENCIES[@]}"; do
    if check_package_installed "$pkg"; then
        echo -e "  \e[1;32m✔ \e[0m $pkg \e[2minstalled\e[0m"
    else
        echo -e "  \e[1;33m➜ \e[0m $pkg \e[1mwill be installed\e[0m"
        TO_INSTALL+=("$pkg")
    fi
done

# 4. Perform installation if needed
if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
    echo -e "----------------------------------------"
    print_status "Packages to install: ${#TO_INSTALL[@]}"

    # Ask user for confirmation
    confirm="y"
    if [[ -t 0 ]]; then
        read -rp "Do you want to proceed with the installation of dependencies? [Y/n] " confirm
    fi
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

    if [[ "$confirm" == "n" || "$confirm" == "no" ]]; then
        print_status "Package installation skipped by user."
    else
        # Run package installer
        if [[ "$OS" == "arch" ]]; then
            print_status "Starting installation using $AUR_HELPER..."
            if $AUR_HELPER -S --needed "${TO_INSTALL[@]}"; then
                print_success "All packages installed successfully!"
            else
                print_error "Installation failed. Please check the logs above."
                exit 1
            fi
        elif [[ "$OS" == "fedora" ]]; then
            print_status "Starting installation using dnf..."
            if $SUDO dnf install -y "${TO_INSTALL[@]}"; then
                print_success "All packages installed successfully!"
            else
                print_error "Installation failed. Please check the logs above."
                exit 1
            fi
        fi
    fi
else
    echo -e "----------------------------------------"
    print_success "All dependencies are already installed!"
fi

# 5. Create symlinks
echo -e "----------------------------------------"
print_status "Setting up configuration symlinks..."

create_symlink() {
    local src="$1"
    local dest="$2"
    local dest_dir
    dest_dir=$(dirname "$dest")

    # Ensure destination directory exists
    mkdir -p "$dest_dir"

    # Check if destination already exists
    if [[ -e "$dest" || -L "$dest" ]]; then
        # If it's already a symlink pointing to the correct source, do nothing
        if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            print_success "Symlink already correct: $dest -> $src"
            return
        fi

        # Backup existing file/directory
        local backup="${dest}.bak.$(date +%Y%m%d_%H%M%S)"
        print_status "Backing up existing $dest to $backup"
        mv "$dest" "$backup"
    fi

    # Create the symlink
    ln -s "$src" "$dest"
    print_success "Created symlink: $dest -> $src"
}

DOTFILES_DIR="$HOME/.config/capsule"

create_symlink "$DOTFILES_DIR/hypr" "$HOME/.config/hypr"
create_symlink "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"

echo -e "----------------------------------------"
print_success "Setup completed successfully!"

if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    print_status "Reloading Hyprland..."
    hyprctl reload
    print_success "Hyprland reloaded!"
fi

if command -v Capsule &>/dev/null; then
    print_status "Starting Capsule..."
    Capsule &>/dev/null &
    print_success "Capsule started!"
fi


