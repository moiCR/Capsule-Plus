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
clear
echo -e "\e[1;35m💊 capsule-dots - Dependency Installer\e[0m"
echo -e "----------------------------------------"

# 1. Detect AUR helper
print_status "Detecting AUR helper..."
AUR_HELPER=""

if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

if [[ -z "$AUR_HELPER" ]]; then
    print_error "Neither 'paru' nor 'yay' was found on your system."
    print_error "An AUR helper is required to install 'quickshell-git'."
    print_error "Please install paru or yay and run this installer again."
    exit 1
fi

print_success "Found AUR helper: \e[1;36m$AUR_HELPER\e[0m"

AUR_DEPENDENCIES=(
    "hyprland"
    "ttf-jetbrains-mono-nerd"
    "ghostty"
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
    "brave-origin-bin"
    "yazi"
    "cliphist"
    "cpupower"
    "hyprlock"
    "qt5ct"
    "qt6ct"
)

print_status "Checking package status..."
TO_INSTALL=()

for pkg in "${AUR_DEPENDENCIES[@]}"; do
    if "$AUR_HELPER" -Qq "$pkg" &>/dev/null; then
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
        # Run the AUR helper
        print_status "Starting installation using $AUR_HELPER..."
        if $AUR_HELPER -S --needed "${TO_INSTALL[@]}"; then
            print_success "All packages installed successfully!"
        else
            print_error "Installation failed. Please check the logs above."
            exit 1
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

