#!/usr/bin/env bash
# One-shot wallpaper change with wallust color regeneration
# Use on login/lock when waybar reload won't be visible

WALLPAPER_DIR="${1:-$HOME/Pictures/wallpapers}"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Pick random wallpaper
wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)

if [[ -z "$wallpaper" ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Get focused monitor
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# Set wallpaper
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_TYPE=simple
swww img -o "$focused_monitor" "$wallpaper"

# Regenerate wallust colors
$HOME/.config/hypr/scripts/WallustSwww.sh "$wallpaper"

# Refresh UI (swaync, rainbow borders - no quickshell restart)
$HOME/.config/hypr/scripts/RefreshNoWaybar.sh

echo "Wallpaper changed to: $wallpaper"
