#!/bin/bash
# Check current GPU mode and power profile

notif="$HOME/.config/swaync/images/ja.png"
STATE_FILE="$HOME/.cache/power-profile-state"

# Get GPU mode (clean output)
GPU_MODE=$(supergfxctl -g 2>/dev/null)

# Get active power profile (asusctl 6.x syntax)
POWER_PROFILE=$(asusctl profile get 2>&1 | grep "^Active profile" | sed 's/Active profile: //')

# Get scheduler info
SCHEDULER_INFO=$(scxctl get 2>/dev/null || echo "Unknown")

# Check if we're in SmartQuiet mode (state file index 1)
PROFILE_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "-1")

# Format GPU mode for display
case "$GPU_MODE" in
    "Integrated")
        GPU_DISPLAY="🔋 Integrated (Intel iGPU)"
        GPU_ICON="battery"
        ;;
    "Hybrid")
        GPU_DISPLAY="⚡ Hybrid (iGPU + dGPU)"
        GPU_ICON="balanced"
        ;;
    "AsusMuxDgpu")
        GPU_DISPLAY="🚀 dGPU Only (RTX 4090)"
        GPU_ICON="performance"
        ;;
    *)
        GPU_DISPLAY="$GPU_MODE"
        GPU_ICON="info"
        ;;
esac

# Format power profile for display (check SmartQuiet first)
if [[ "$PROFILE_STATE" == "1" && "$POWER_PROFILE" == "Performance" ]]; then
    # SmartQuiet mode: Performance thermal + quiet fans
    PROFILE_DISPLAY="🎮 Smart Quiet (Gaming)"
elif [[ "$PROFILE_STATE" == "0" && "$POWER_PROFILE" == "Performance" ]]; then
    PROFILE_DISPLAY="⚡ Performance (Max Power)"
else
    case "$POWER_PROFILE" in
        "Performance")
            PROFILE_DISPLAY="⚡ Performance (Max Power)"
            ;;
        "Balanced")
            PROFILE_DISPLAY="⚖️  Balanced"
            ;;
        "Quiet")
            PROFILE_DISPLAY="🔇 Quiet (Low Power)"
            ;;
        *)
            PROFILE_DISPLAY="$POWER_PROFILE"
            ;;
    esac
fi

# Format scheduler for display
if [[ "$SCHEDULER_INFO" =~ Lavd.*Gaming ]]; then
    SCHEDULER_DISPLAY="🎮 Scheduler: Lavd (Gaming)"
elif [[ "$SCHEDULER_INFO" =~ Lavd.*LowLatency ]]; then
    SCHEDULER_DISPLAY="⚡ Scheduler: Lavd (LowLatency)"
elif [[ "$SCHEDULER_INFO" =~ Lavd.*PowerSave ]]; then
    SCHEDULER_DISPLAY="💤 Scheduler: Lavd (PowerSave)"
elif [[ "$SCHEDULER_INFO" == "Unknown" ]]; then
    SCHEDULER_DISPLAY="❓ Scheduler: Unknown"
else
    # Extract scheduler name and mode if available
    SCHEDULER_DISPLAY="🔧 Scheduler: $SCHEDULER_INFO"
fi

# Get memory stats
RAM_AVAIL=$(free -h | awk '/^Mem:/ {print $7}')
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')

# Get zram stats (compression ratio)
if [[ -f /sys/block/zram0/mm_stat ]]; then
    read -r orig compr _ _ _ _ _ _ < /sys/block/zram0/mm_stat
    if [[ $compr -gt 0 ]]; then
        ZRAM_RATIO=$(awk "BEGIN {printf \"%.1f\", $orig / $compr}")
        ZRAM_USED=$(awk "BEGIN {printf \"%.1f\", $orig / 1024 / 1024 / 1024}")
        ZRAM_DISPLAY="zram: ${ZRAM_USED}GB (${ZRAM_RATIO}:1)"
    else
        ZRAM_DISPLAY="zram: empty"
    fi
else
    ZRAM_DISPLAY="zram: N/A"
fi

# Get swap usage
SWAP_USED=$(free -h | awk '/^Swap:/ {print $3}')
SWAP_TOTAL=$(free -h | awk '/^Swap:/ {print $2}')
SWAP_PCT=$(free -b | awk '/^Swap:/ {if($2>0) printf "%.0f", $3/$2*100; else print "0"}')

# Format memory display
MEM_DISPLAY="💾 RAM: ${RAM_AVAIL}/${RAM_TOTAL} avail | ${ZRAM_DISPLAY} | swap: ${SWAP_USED}/${SWAP_TOTAL} (${SWAP_PCT}%)"

# Send notification with clean, formatted info
notify-send -e -u normal -i "$notif" "System Status" "GPU: $GPU_DISPLAY\nProfile: $PROFILE_DISPLAY\n$SCHEDULER_DISPLAY\n$MEM_DISPLAY"
