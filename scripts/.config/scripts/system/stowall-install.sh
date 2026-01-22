#!/usr/bin/env bash
set -euo pipefail

TMP="$HOME/.config-staging"
TARGET="$HOME/.config"

rm -rf "$TMP"
mkdir -p "$TMP"

echo "Building symlink tree..."
for pkg in */; do
    echo "  Stowing ${pkg%/}..."
    stow -t "$TMP" "${pkg%/}"
done

echo "Deploying configs..."
rsync -av --delete "$TMP/.config/" "$TARGET/"

echo "Cleanup staging..."
rm -rf "$TMP"

echo "✓ Done!"