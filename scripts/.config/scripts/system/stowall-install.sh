#!/usr/bin/env bash
set -euo pipefail

TMP="$HOME/.config-staging"
TARGET="$HOME/.config"

rm -rf "$TMP"
mkdir -p "$TMP"

echo "Building symlink tree..."
stow -t "$TMP" */

echo "Deploying configs..."
rsync -a --delete "$TMP/" "$TARGET/"

echo "Cleanup staging..."
rm -rf "$TMP"

echo "Done."
