#!/bin/bash
# Memory pressure monitor with desktop notifications
# Warns before systemd-oomd kills your session (95% threshold)

# Thresholds (percentage)
SWAP_WARNING=70      # Early warning - time to close some apps
SWAP_CRITICAL=85     # Urgent - close apps NOW or face oomd
RAM_AVAILABLE_LOW=15  # Warn when less than 15% RAM available (after cache reclaim)

# Check interval in seconds
INTERVAL=30

# Cooldown: don't spam notifications (seconds between same-level alerts)
COOLDOWN=300

# State tracking
LAST_WARNING=0
LAST_CRITICAL=0

notify() {
    local urgency="$1"
    local title="$2"
    local message="$3"
    local icon="$4"

    notify-send -u "$urgency" -i "$icon" "$title" "$message"
}

get_memory_stats() {
    # Get RAM available percentage (available = memory apps can actually use)
    # "used" includes reclaimable cache, "available" is what matters for OOM
    read -r total available <<< $(free -b | awk '/^Mem:/ {print $2, $7}')
    RAM_AVAILABLE_PERCENT=$((available * 100 / total))
    RAM_PERCENT=$((100 - RAM_AVAILABLE_PERCENT))  # For display: "X% in use"
    RAM_AVAILABLE_GB=$(awk "BEGIN {printf \"%.1f\", $available / 1024 / 1024 / 1024}")
    RAM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $total / 1024 / 1024 / 1024}")

    # Get swap usage percentage
    read -r swap_total swap_used <<< $(free -b | awk '/^Swap:/ {print $2, $3}')
    if [[ $swap_total -gt 0 ]]; then
        SWAP_PERCENT=$((swap_used * 100 / swap_total))
        SWAP_USED_GB=$(awk "BEGIN {printf \"%.1f\", $swap_used / 1024 / 1024 / 1024}")
        SWAP_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $swap_total / 1024 / 1024 / 1024}")
    else
        SWAP_PERCENT=0
        SWAP_USED_GB="0"
        SWAP_TOTAL_GB="0"
    fi
}

get_top_consumers() {
    # Get top 3 memory consumers
    ps aux --sort=-%mem | awk 'NR>1 && NR<=4 {printf "%s (%.0fMB)\n", $11, $6/1024}' | \
        sed 's|/.*bin/||; s|--.*||' | head -3 | tr '\n' ', ' | sed 's/, $//'
}

check_and_notify() {
    local now
    now=$(date +%s)

    get_memory_stats

    # Critical swap alert (85%+)
    if [[ $SWAP_PERCENT -ge $SWAP_CRITICAL ]]; then
        if [[ $((now - LAST_CRITICAL)) -ge $COOLDOWN ]]; then
            local top_procs
            top_procs=$(get_top_consumers)
            notify "critical" "⚠️ MEMORY CRITICAL" \
                "Swap: ${SWAP_USED_GB}GB/${SWAP_TOTAL_GB}GB (${SWAP_PERCENT}%)\nRAM available: ${RAM_AVAILABLE_GB}GB\n\nClose apps NOW or oomd will kill session!\n\nTop: $top_procs" \
                "dialog-error"
            LAST_CRITICAL=$now
            LAST_WARNING=$now  # Also reset warning cooldown
        fi
        return
    fi

    # Warning swap alert (70%+)
    if [[ $SWAP_PERCENT -ge $SWAP_WARNING ]]; then
        if [[ $((now - LAST_WARNING)) -ge $COOLDOWN ]]; then
            notify "normal" "Memory Warning" \
                "Swap: ${SWAP_USED_GB}GB/${SWAP_TOTAL_GB}GB (${SWAP_PERCENT}%)\nRAM available: ${RAM_AVAILABLE_GB}GB\n\nConsider closing some applications." \
                "dialog-warning"
            LAST_WARNING=$now
        fi
        return
    fi

    # RAM-only warning (swap is fine but available RAM is low)
    if [[ $RAM_AVAILABLE_PERCENT -le $RAM_AVAILABLE_LOW && $SWAP_PERCENT -lt $SWAP_WARNING ]]; then
        if [[ $((now - LAST_WARNING)) -ge $COOLDOWN ]]; then
            notify "low" "Low Available RAM" \
                "Available: ${RAM_AVAILABLE_GB}GB/${RAM_TOTAL_GB}GB (${RAM_AVAILABLE_PERCENT}%)\nSwap headroom: ${SWAP_TOTAL_GB}GB" \
                "dialog-information"
            LAST_WARNING=$now
        fi
    fi
}

# Handle graceful shutdown
cleanup() {
    echo "Memory monitor stopped"
    exit 0
}
trap cleanup SIGTERM SIGINT

# Main loop
echo "Memory monitor started (swap warn: ${SWAP_WARNING}%, critical: ${SWAP_CRITICAL}%)"
while true; do
    check_and_notify
    sleep "$INTERVAL"
done
