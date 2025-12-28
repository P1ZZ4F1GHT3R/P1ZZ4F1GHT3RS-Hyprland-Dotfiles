#!/bin/bash

#===============================================================================
# Color Processing Utilities Library
# ~/.config/scripts/lib/color-utils.sh
# Description: Color manipulation and processing functions
# Author: saatvik333
# Version: 1.0
#===============================================================================

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# --- Color Conversion Functions ---
hex_to_rgb() {
    local -r hex="$1"
    local -r r=$((0x${hex:0:2}))
    local -r g=$((0x${hex:2:2}))
    local -r b=$((0x${hex:4:2}))
    echo "$r,$g,$b"
}

lighten_hex() {
    local -r hex="$1"
    local -r percent="$2"
    local r g b
    
    r=$((0x${hex:0:2}))
    g=$((0x${hex:2:2}))
    b=$((0x${hex:4:2}))
    
    r=$((r + (255 - r) * percent / 100))
    g=$((g + (255 - g) * percent / 100))
    b=$((b + (255 - b) * percent / 100))
    
    r=$((r > 255 ? 255 : r))
    g=$((g > 255 ? 255 : g))
    b=$((b > 255 ? 255 : b))
    
    printf "%02x%02x%02x" "$r" "$g" "$b"
}

calculate_luminance() {
    local -r r="$1"
    local -r g="$2"
    local -r b="$3"
    
    echo "scale=0; ($r * 299 + $g * 587 + $b * 114) / 1000" | bc
}

# --- Color Extraction Functions ---
extract_css_color() {
    local -r file="$1"
    local -r var_name="$2"
    
    grep "^[[:space:]]*--${var_name}:" "$file" 2>/dev/null | \
        sed -E 's/^[[:space:]]*--[^:]+:[[:space:]]*#([0-9a-fA-F]{6}).*/\1/' || echo ""
}

# --- Image Analysis Functions ---
get_image_dimensions() {
    local -r image="$1"
    
    validate_dependencies "magick"
    
    magick identify -format "%w %h" "$image" 2>/dev/null || \
        die "Failed to get image dimensions for: $image"
}

extract_region_rgb() {
    local -r image="$1"
    local -r width="$2"
    local -r height="$3"
    local -r x_offset="${4:-0}"
    local -r y_offset="${5:-0}"
    
    validate_dependencies "magick"
    
    magick "$image" \
        -crop "${width}x${height}+${x_offset}+${y_offset}" \
        -resize 1x1! \
        -format "%[fx:int(255*r)] %[fx:int(255*g)] %[fx:int(255*b)]" \
        info:- 2>/dev/null || \
        die "Failed to extract RGB values from: $image"
}

# --- GIF Processing Functions ---
extract_gif_frame() {
    local -r gif_path="$1"
    local -r output_path="$2"
    
    validate_dependencies "convert"
    
    log_info "Extracting first frame from GIF: $gif_path"
    
    ensure_directory "$(dirname "$output_path")"
    
    if ! convert "${gif_path}[0]" "$output_path" 2>/dev/null; then
        die "Failed to extract first frame from GIF: $gif_path"
    fi
    
    if [[ ! -f "$output_path" || ! -s "$output_path" ]]; then
        die "GIF frame extraction failed or produced empty file"
    fi
    
    log_success "Extracted GIF frame to: $output_path"
    echo "$output_path"
}