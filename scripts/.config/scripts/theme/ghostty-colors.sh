#!/bin/bash

JSON_FILE="$HOME/.cache/wallust/colors.json"
CONF_FILE="$HOME/.config/ghostty/themes/wallust.conf"

mkdir -p "$(dirname "$CONF_FILE")"

BG=$(jq -r '.special.background' "$JSON_FILE")
FG=$(jq -r '.special.foreground' "$JSON_FILE")
CURSOR=$(jq -r '.special.cursor' "$JSON_FILE")

{
    # Palette
    for i in {0..15}; do
        COLOR=$(jq -r ".colors.color$i" "$JSON_FILE")
        echo "palette = $i=$COLOR"
    done

    echo
    echo "background = $BG"
    echo "foreground = $FG"
    echo "cursor-color = $CURSOR"
    echo "cursor-text = $FG"

    # Optional but sane defaults
    echo "selection-background = $(jq -r '.colors.color8' "$JSON_FILE")"
    echo "selection-foreground = $FG"
} > "$CONF_FILE"
