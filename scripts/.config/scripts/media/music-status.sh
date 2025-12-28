#!/bin/bash

#===============================================================================
# Music Status Display
# ~/.config/scripts/media/music-status.sh
# Description: Displays current music status for hyprlock and other widgets
# Author: saatvik333
# Version: 2.0
# Dependencies: playerctl
#===============================================================================

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# --- Configuration ---
readonly MAX_TITLE_LENGTH=30
readonly MAX_ARTIST_LENGTH=20
readonly PLAYING_ICON="󰎇"
readonly PAUSED_ICON="◦"

# --- Functions ---
truncate_text() {
    local -r text="$1"
    local -r max_length="$2"
    
    if (( ${#text} > max_length )); then
        echo "${text:0:$((max_length - 3))}..."
    else
        echo "$text"
    fi
}

find_active_player() {
    local players
    players=$(playerctl -l 2>/dev/null) || return 1
    
    [[ -z "$players" ]] && return 1
    
    local fallback_player=""
    
    for player in $players; do
        local status
        status=$(playerctl -p "$player" status 2>/dev/null) || continue
        
        case "$status" in
            "Playing")
                echo "$player"
                return 0
                ;;
            "Paused")
                [[ -z "$fallback_player" ]] && fallback_player="$player"
                ;;
        esac
    done
    
    [[ -n "$fallback_player" ]] && echo "$fallback_player" && return 0
    return 1
}

get_track_metadata() {
    local -r player="$1"
    local title artist status
    
    title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "")
    artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "")
    status=$(playerctl -p "$player" status 2>/dev/null || echo "")
    
    [[ -z "$title" ]] && return 1
    
    echo "$title|$artist|$status"
}

format_music_output() {
    local -r title="$1"
    local -r artist="$2"
    local -r status="$3"
    
    local formatted_title formatted_artist icon
    formatted_title=$(truncate_text "$title" "$MAX_TITLE_LENGTH")
    formatted_artist=$(truncate_text "$artist" "$MAX_ARTIST_LENGTH")
    
    case "$status" in
        "Playing") icon="$PLAYING_ICON" ;;
        *) icon="$PAUSED_ICON" ;;
    esac
    
    if [[ -n "$formatted_artist" ]]; then
        echo "$icon $formatted_artist · $formatted_title"
    else
        echo "$icon $formatted_title"
    fi
}

main() {
    validate_dependencies "playerctl"
    
    local active_player metadata
    active_player=$(find_active_player) || { echo ""; exit 0; }
    
    metadata=$(get_track_metadata "$active_player") || { echo ""; exit 0; }
    
    IFS='|' read -r title artist status <<< "$metadata"
    
    format_music_output "$title" "$artist" "$status"
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi