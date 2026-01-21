#!/usr/bin/env bash
set -e

echo "== Stowing dotfiles =="

# Get the repo root directory (where this script lives)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "Repository root: $REPO_ROOT"

# Remove conflicting files/directories in .config before stowing
# This allows stow to create symlinks without conflicts
remove_conflicts() {
    local package=$1
    local config_path="$package/.config"
    
    if [ ! -d "$config_path" ]; then
        return
    fi
    
    # For each item in the package's .config directory
    find "$config_path" -mindepth 1 -maxdepth 1 | while read -r item; do
        local basename=$(basename "$item")
        local target="$HOME/.config/$basename"
        
        # If target exists and is NOT already a symlink to our repo
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "  Removing conflicting: $target"
            rm -rf "$target"
        elif [ -L "$target" ]; then
            # If it's a symlink but points elsewhere, remove it
            local link_target=$(readlink "$target")
            if [[ "$link_target" != "$REPO_ROOT"* ]]; then
                echo "  Removing external symlink: $target"
                rm -f "$target"
            fi
        fi
    done
}

# Process each package
for package in */; do
    if [ -d "$package" ]; then
        echo "Stowing: $package"
        
        # Remove conflicts first
        remove_conflicts "$package"
        
        # Now stow (will create symlinks)
        stow -v -t "$HOME/.config" -d . "$package" 2>&1 | grep -v "LINK:" || true
        
    else
        echo "Warning: Package '$package' not found, skipping"
    fi
done

echo "== Stowing complete =="
echo
echo "Symlinks created. Files remain in: $REPO_ROOT"
