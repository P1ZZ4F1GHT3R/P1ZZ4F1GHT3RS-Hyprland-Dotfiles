#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
CONFIG_DIR="$HOME/.config"

if ! command -v stow >/dev/null 2>&1; then
  echo "stow not found. Install it first."
  exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
  echo "~/.config does not exist. Creating it."
  mkdir -p "$CONFIG_DIR"
fi

echo "Copying files into ~/.config..."

# Copy every top-level directory in repo into ~/.config
for dir in */; do
  # Skip non-directories or stuff you don’t want
  [ -d "$dir" ] || continue

  echo "→ Copying $dir"
  cp -rT "$REPO_ROOT/$dir" "$CONFIG_DIR/${dir%/}"
done

echo "Adopting into stow..."

for dir in */; do
  [ -d "$dir" ] || continue
  echo "→ Stowing $dir"
  stow --adopt "${dir%/}"
done

echo "Done. Everything is now symlinked via stow."
