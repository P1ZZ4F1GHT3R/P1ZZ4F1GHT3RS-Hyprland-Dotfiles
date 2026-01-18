#!/usr/bin/env bash
set -e  # Remove -x for cleaner output, add back for debugging

BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CONFIG_BACKUP="$BACKUP_ROOT/config-$TIMESTAMP"
STOWALL="./scripts/.config/scripts/system/stowall.sh"
INSTALL_LOG="$HOME/hyprland-install-$TIMESTAMP.log"

# Log everything
exec > >(tee -a "$INSTALL_LOG") 2>&1

echo "== Arch Hyprland dotfiles install starting =="
echo "Log: $INSTALL_LOG"

# --- sanity checks ---
if ! command -v pacman >/dev/null 2>&1; then
    echo "ERROR: Not Arch Linux. Exiting."
    exit 1
fi

if [ ! -f "$STOWALL" ]; then
    echo "ERROR: stowall.sh not found at $STOWALL"
    echo "Run this script from the repository root."
    exit 1
fi

# Check if running as root (shouldn't be)
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Don't run this script as root/sudo"
    exit 1
fi

# --- system update ---
echo "Updating system..."
sudo pacman -Syu --noconfirm

# --- base tools ---
echo "Installing base tools..."
sudo pacman -S --needed --noconfirm \
    git \
    base-devel \
    stow \
    curl \
    wget

# --- yay ---
if ! command -v yay >/dev/null 2>&1; then
    echo "Installing yay..."
    YAY_TMP="/tmp/yay-install-$$"
    git clone https://aur.archlinux.org/yay.git "$YAY_TMP"
    cd "$YAY_TMP"
    makepkg -si --noconfirm
    cd -
    rm -rf "$YAY_TMP"
else
    echo "yay already installed"
fi

# --- pacman packages ---
echo "Installing official packages..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    bash \
    zsh \
    fish \
    Thunar \
    dunst \
    neofetch \
    fastfetch \
    pavucontrol \
    starship \
    swaync \
    waybar \
    easyeffects \
    wofi \
    wlogout \
    yazi \
    btop \
    ghostty \
    swww \
    vscodium \
    sddm \
    neovim

# --- AUR packages ---
echo "Installing AUR packages..."
set +e  # Don't exit on AUR failures
yay -S --needed --noconfirm \
    waytrogen \
    kew \
    vicinae \
    wallust \
    sunsetr \
    cmatrix-git

AUR_EXIT=$?
set -e

if [ $AUR_EXIT -ne 0 ]; then
    echo "WARNING: Some AUR packages failed. Continuing..."
fi

# --- backup .config ---
if [ -d "$HOME/.config" ]; then
    echo "Backing up ~/.config to $CONFIG_BACKUP"
    mkdir -p "$BACKUP_ROOT"
    cp -r "$HOME/.config" "$CONFIG_BACKUP"  # Copy instead of move (safer)
    echo "Backup saved at: $CONFIG_BACKUP"
fi

# --- stow dotfiles ---
echo "Stowing dotfiles..."
chmod +x "$STOWALL"

if ! "$STOWALL"; then
    echo "ERROR: Stowing failed!"
    echo "Your original config backup is at: $CONFIG_BACKUP"
    echo "To restore: rm -rf ~/.config && mv $CONFIG_BACKUP ~/.config"
    exit 1
fi

echo "== Installation complete =="
echo "Log saved to: $INSTALL_LOG"

# --- optional reboot ---
echo
read -r -p "Reboot now? [y/N]: " REBOOT_CHOICE
case "$REBOOT_CHOICE" in
    y|Y|yes|YES)
        echo "Rebooting in 3 seconds... (Ctrl+C to cancel)"
        sleep 3
        sudo systemctl reboot
        ;;
    *)
        echo "Reboot skipped."
        echo "To complete setup, reboot with: sudo systemctl reboot"
        ;;
esac

# --- optional self-delete ---
read -r -p "Delete this install script? [y/N]: " DELETE_CHOICE
case "$DELETE_CHOICE" in
    y|Y|yes|YES)
        echo "Removing install script..."
        rm -- "$0"
        ;;
    *)
        echo "Install script kept."
        ;;
esac