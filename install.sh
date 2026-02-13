#!/usr/bin/env bash
set -e  # Remove -x for cleaner output, add back for debugging

BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CONFIG_BACKUP="$BACKUP_ROOT/config-$TIMESTAMP"
STOWALLINSTALL="./scripts/.config/scripts/system/stowall-install.sh"
STOWALL="./scripts/.config/scripts/system/stowall.sh"
SCRIPTS_DIR="./scripts/.config/scripts"

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
    thunar \
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
    cmatrix-git \
    ttf-material-symbols-variable-git

AUR_EXIT=$?
set -e

if [ $AUR_EXIT -ne 0 ]; then
    echo "WARNING: Some AUR packages failed. Continuing..."
fi

# --- GTK themes (Colloid variants) ---
COLLOID_TMP="/tmp/colloid-theme-$$"
if [ -d "$COLLOID_TMP" ]; then
    rm -rf "$COLLOID_TMP"
fi

git clone https://github.com/vinceliuice/Colloid-gtk-theme.git "$COLLOID_TMP"
cd "$COLLOID_TMP"

echo "Building Colloid theme variants..."
# Install only dark variants with default (nord-like blue) color
./install.sh -t default -c dark --tweaks catppuccin black rimless
./install.sh -t default -c dark --tweaks everforest black rimless
./install.sh -t default -c dark --tweaks gruvbox black rimless
./install.sh -t default -c dark --tweaks nord black rimless
./install.sh -t default -c dark --tweaks dracula black rimless
./install.sh -t default -c dark --tweaks black rimless

cd -
rm -rf "$COLLOID_TMP"

echo "Colloid theme variants installed:"
echo "  - Colloid-Dark (Black/Animated)"
echo "  - Colloid-Dark-Catppuccin"
echo "  - Colloid-Dark-Everforest"
echo "  - Colloid-Dark-Gruvbox"
echo "  - Colloid-Dark-Nord"
echo "  - Colloid-Dark-Dracula (Onedark)"


# --- backup .config ---
if [ -d "$HOME/.config" ]; then
    echo "Backing up ~/.config to $CONFIG_BACKUP"
    mkdir -p "$BACKUP_ROOT"
    cp -r "$HOME/.config" "$CONFIG_BACKUP"  # Copy instead of move (safer)
    echo "Backup saved at: $CONFIG_BACKUP"
fi

# --- make scripts executable ---
echo "Making all scripts executable..."
if [ -d "$SCRIPTS_DIR" ]; then
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    echo "Scripts in $SCRIPTS_DIR are now executable"
else
    echo "WARNING: Scripts directory not found at $SCRIPTS_DIR"
fi

# --- stow dotfiles ---
echo "Stowing dotfiles..."

if ! "$STOWALLINSTALL"; then
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
