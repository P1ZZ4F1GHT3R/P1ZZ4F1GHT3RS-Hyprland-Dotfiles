#!/usr/bin/env bash
set -ex

BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CONFIG_BACKUP="$BACKUP_ROOT/config-$TIMESTAMP"
STOWALL="./scripts/.config/scripts/system/stowall.sh"

echo "== Arch install starting =="

# --- sanity ---
if ! command -v pacman >/dev/null 2>&1; then
  echo "Not Arch. Exiting."
  exit 1
fi

if [ ! -f "$STOWALL" ]; then
  echo "stowall.sh not found. Run this from the repo root."
  exit 1
fi

# --- base tools ---
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm \
  git \
  base-devel \
  stow \
  curl \
  wget

# --- yay ---
if ! command -v yay >/dev/null 2>&1; then
  echo "Installing yay..."
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd /
  rm -rf /tmp/yay
fi

# --- pacman deps ---
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
  cmatrix-git \
  neovim

# --- AUR deps ---
set +e
yay -S --needed --noconfirm \
  waytrogen \
  kew \
  vicinae \
  wallust \
  sunsetr
set -e 

# --- backup entire .config ---
if [ -d "$HOME/.config" ]; then
  echo "Backing up ~/.config to $CONFIG_BACKUP"
  mkdir -p "$BACKUP_ROOT"
  mv "$HOME/.config" "$CONFIG_BACKUP"
fi

# --- recreate empty .config ---
mkdir -p "$HOME/.config"

# --- stow ---
echo "Stowing dotfiles..."
chmod +x $STOWALL
"$STOWALL"

echo "== Done. Reboot recommended =="

# --- optional reboot ---
echo
read -r -p "Reboot now? [y/N]: " REBOOT_CHOICE
case "$REBOOT_CHOICE" in
  y|Y|yes|YES)
    echo "Rebooting..."
    sudo systemctl reboot
    ;;
  *)
    echo "Reboot skipped."
    ;;
esac

# --- self-delete ---
echo "Install complete. Removing install script..."
rm -- "$0"


