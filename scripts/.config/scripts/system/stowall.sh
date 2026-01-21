#!/bin/bash
set -e

echo "Re-stowing dotfiles (handling broken symlinks)..."

PACKAGES=(
    "hypr"
    "pavucontrol.ini"
    "wallust"
    "waybar"
)

# Step 1: Unstow everything (removes all symlinks)
echo "Step 1: Removing existing symlinks..."
for pkg in "${PACKAGES[@]}"; do
    stow -D -v "$pkg" 2>/dev/null || true
done

for pkg in */; do
    pkg_name="${pkg%/}"
    if [[ ! " ${PACKAGES[@]} " =~ " ${pkg_name} " ]] && [ -d "$pkg_name/.config" ]; then
        stow -D -v "$pkg_name" 2>/dev/null || true
    fi
done

# Step 2: Adopt any remaining files (the ones that broke symlinks)
echo "Step 2: Adopting broken symlink files back into repo..."
for pkg in "${PACKAGES[@]}"; do
    stow --adopt -v "$pkg" 2>/dev/null || true
done

for pkg in */; do
    pkg_name="${pkg%/}"
    if [[ ! " ${PACKAGES[@]} " =~ " ${pkg_name} " ]] && [ -d "$pkg_name/.config" ]; then
        stow --adopt -v "$pkg_name" 2>/dev/null || true
    fi
done

# Step 3: Stow everything cleanly
echo "Step 3: Stowing all packages..."
for pkg in "${PACKAGES[@]}"; do
    stow -v "$pkg"
done

for pkg in */; do
    pkg_name="${pkg%/}"
    if [[ ! " ${PACKAGES[@]} " =~ " ${pkg_name} " ]] && [ -d "$pkg_name/.config" ]; then
        stow -v "$pkg_name"
    fi
done

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

echo ""
echo "✓ Done! All symlinks restored."