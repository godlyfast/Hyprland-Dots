#!/bin/bash
# Scheduler Mode Switcher
# Cycles through SCX scheduler modes: auto -> powersave -> gaming -> lowlatency -> kernel-default

notif="$HOME/.config/swaync/images/ja.png"

# Check if kernel supports sched-ext (CachyOS kernels only)
KERNEL=$(uname -r)
if [[ ! "$KERNEL" =~ "cachyos" ]]; then
    notify-send -e -u normal -i "$notif" "Scheduler Not Available" "🐧 Kernel: $KERNEL\nSched-ext requires CachyOS kernel"
    exit 0
fi

# Get current scheduler info
CURRENT_INFO=$(scxctl get 2>&1)

# Check if scheduler is stopped (kernel-default mode)
if echo "$CURRENT_INFO" | grep -qi "not running\|no scheduler"; then
    # Start with auto mode (follows ASUS power profile)
    NEXT_MODE="auto"
    MODE_DISPLAY="🔄 Auto"
    MODE_DESC="Follows ASUS power profile automatically"
    scxctl start --sched lavd --mode "$NEXT_MODE"
# Extract current mode from the output (e.g., "running Lavd in Auto mode")
elif echo "$CURRENT_INFO" | grep -qi "auto"; then
    NEXT_MODE="powersave"
    MODE_DISPLAY="🔋 Power Save"
    MODE_DESC="Energy efficient sched-ext mode"
    scxctl switch --mode "$NEXT_MODE"
elif echo "$CURRENT_INFO" | grep -qi "powersave"; then
    NEXT_MODE="gaming"
    MODE_DISPLAY="🎮 Gaming"
    MODE_DESC="Optimized for gaming performance"
    scxctl switch --mode "$NEXT_MODE"
elif echo "$CURRENT_INFO" | grep -qi "gaming"; then
    NEXT_MODE="lowlatency"
    MODE_DISPLAY="⚡ Low Latency"
    MODE_DESC="Minimal latency for responsive tasks"
    scxctl switch --mode "$NEXT_MODE"
elif echo "$CURRENT_INFO" | grep -qi "lowlatency"; then
    # Switch to kernel-default (BORE) by stopping sched-ext
    NEXT_MODE="kernel-default"
    MODE_DISPLAY="🐧 Kernel Default (BORE)"
    MODE_DESC="Built-in BORE scheduler (no sched-ext)"
    scxctl stop
else
    # Default to auto if we can't detect current mode
    NEXT_MODE="auto"
    MODE_DISPLAY="🔄 Auto"
    MODE_DESC="Follows ASUS power profile automatically"
    scxctl start --sched lavd --mode "$NEXT_MODE"
fi

# Send notification
notify-send -e -u normal -i "$notif" "Scheduler Mode Switched" "$MODE_DISPLAY\n$MODE_DESC"
