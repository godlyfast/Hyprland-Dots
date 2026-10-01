#!/bin/bash
# Power Profile Switcher with Notifications
# Cycles through: Performance → Smart Quiet → Balanced → Quiet
# Smart Quiet = Performance thermal policy + quiet fan curves (crackle-free audio)
#
# Updated for asusctl 6.x syntax (2024+)

notif="$HOME/.config/swaync/images/ja.png"
STATE_FILE="$HOME/.cache/power-profile-state"

# Define profile order (4 states)
PROFILES=("Performance" "SmartQuiet" "Balanced" "Quiet")

# Read current state (default to 0 = Performance)
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_INDEX=$(cat "$STATE_FILE")
else
    CURRENT_INDEX=0
fi

# Cycle to next profile
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % 4 ))
echo "$NEXT_INDEX" > "$STATE_FILE"

NEXT_PROFILE="${PROFILES[$NEXT_INDEX]}"

# Apply profile settings
case "$NEXT_PROFILE" in
    "Performance")
        # Stock Performance: max power, stock loud fans
        asusctl profile set Performance
        asusctl fan-curve --mod-profile Performance --enable-fan-curves false
        scxctl switch --sched lavd --mode gaming
        PROFILE_DISPLAY="⚡ Performance"
        PROFILE_DESC="Maximum power, stock fans"
        ;;
    "SmartQuiet")
        # Smart Quiet: Performance thermal (no audio cracks) + quiet fans
        asusctl profile set Performance
        # Set quiet fan curves
        asusctl fan-curve --mod-profile Performance --fan cpu --data "40c:0%,55c:5%,60c:10%,65c:18%,70c:28%,75c:40%,80c:55%,88c:75%"
        asusctl fan-curve --mod-profile Performance --fan gpu --data "40c:0%,55c:8%,60c:15%,65c:22%,70c:32%,75c:45%,80c:60%,88c:75%"
        asusctl fan-curve --mod-profile Performance --fan mid --data "40c:5%,55c:10%,60c:15%,65c:20%,70c:28%,75c:35%,80c:42%,88c:50%"
        asusctl fan-curve --mod-profile Performance --enable-fan-curves true
        scxctl switch --sched lavd --mode gaming
        PROFILE_DISPLAY="🎮 Smart Quiet"
        PROFILE_DESC="Gaming mode, quiet fans, no audio cracks"
        ;;
    "Balanced")
        asusctl profile set Balanced
        asusctl fan-curve --mod-profile Balanced --enable-fan-curves false
        scxctl switch --sched lavd --mode lowlatency
        PROFILE_DISPLAY="⚖️  Balanced"
        PROFILE_DESC="Moderate performance (may have audio cracks)"
        ;;
    "Quiet")
        asusctl profile set Quiet
        asusctl fan-curve --mod-profile Quiet --enable-fan-curves false 2>/dev/null || true
        scxctl switch --sched lavd --mode powersave
        PROFILE_DISPLAY="🔇 Quiet"
        PROFILE_DESC="Low power, quietest fans (may have audio cracks)"
        ;;
esac

# Send notification
notify-send -e -u normal -i "$notif" "Power Profile" "$PROFILE_DISPLAY\n$PROFILE_DESC"
