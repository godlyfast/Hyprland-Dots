#!/usr/bin/env bash
# Rofi picker to switch the system default web browser (xdg-settings).
# Bound to SUPER+ALT+D in UserConfigs/UserKeybinds.conf.
#
# Lists every installed .desktop entry that is a WebBrowser and handles https,
# highlights the current default, and applies the choice with
# `xdg-settings set default-web-browser`, which rewrites http/https/text/html
# in ~/.config/mimeapps.list consistently.
#
#   RofiBrowserSelect.sh                 interactive rofi picker
#   RofiBrowserSelect.sh --get           print current default (id + name)
#   RofiBrowserSelect.sh --list          print candidates (id<TAB>name), current marked *
#   RofiBrowserSelect.sh --set <query>   set by name or id, case-insensitive
#                                        substring (e.g. "brave", "chrome", "firefox")
# Also reachable as `default-browser` via ~/.local/bin symlink.

set -euo pipefail

rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-Animations.rasi"

current="$(xdg-settings get default-web-browser 2>/dev/null || true)"

# Collect candidates: user dir first so it shadows system entries with the same id.
declare -A seen=()
ids=() names=()
for dir in "${XDG_DATA_HOME:-$HOME/.local/share}/applications" /usr/share/applications; do
    for f in "$dir"/*.desktop; do
        [[ -f "$f" ]] || continue
        id="${f##*/}"
        [[ -n "${seen[$id]:-}" ]] && continue
        seen[$id]=1
        grep -qE '^NoDisplay=true' "$f" && continue                       # hidden dupes (com.google.Chrome.desktop)
        grep -qE '^MimeType=.*x-scheme-handler/https' "$f" || continue     # must handle web links
        grep -qE '^Categories=.*WebBrowser' "$f" || continue               # skip Zoom/Teams-style https handlers
        name="$(grep -m1 '^Name=' "$f" | cut -d= -f2-)"
        ids+=("$id"); names+=("${name:-$id}")
    done
done

if (( ${#ids[@]} == 0 )); then
    notify-send -u critical "Default browser" "No web browsers found in applications dirs"
    exit 1
fi

# Sort by display name, keep id/name pairs aligned.
mapfile -t sorted < <(paste -d $'\t' <(printf '%s\n' "${ids[@]}") <(printf '%s\n' "${names[@]}") | sort -t $'\t' -k2,2)

apply() {  # apply <id> <name>
    if [[ "$1" == "$current" ]]; then
        echo "$2 is already the default"
        return 0
    fi
    xdg-settings set default-web-browser "$1" && echo "Default browser: $2 ($1)"
}

case "${1:-}" in
    --get|get)
        for line in "${sorted[@]}"; do
            [[ "${line%%$'\t'*}" == "$current" ]] && { echo "$current  (${line#*$'\t'})"; exit 0; }
        done
        echo "${current:-<unset>}"; exit 0 ;;
    --list|list)
        for line in "${sorted[@]}"; do
            mark=" "; [[ "${line%%$'\t'*}" == "$current" ]] && mark="*"
            printf '%s %s\n' "$mark" "$line"
        done; exit 0 ;;
    --set|set)
        q="${2:-}"
        [[ -n "$q" ]] || { echo "usage: ${0##*/} --set <name|id>" >&2; exit 2; }
        for line in "${sorted[@]}"; do
            id="${line%%$'\t'*}"; name="${line#*$'\t'}"
            if [[ "${id,,}" == *"${q,,}"* || "${name,,}" == *"${q,,}"* ]]; then
                apply "$id" "$name"; exit $?
            fi
        done
        echo "no browser matching '$q'; try --list" >&2; exit 1 ;;
    -h|--help|help)
        sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "") ;;  # interactive rofi below
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
esac

# Build rofi rows; remember which row is current for pre-selection.
rows=() row_ids=() selected_row=0 current_name="(none)"
i=0
for line in "${sorted[@]}"; do
    id="${line%%$'\t'*}"; name="${line#*$'\t'}"
    if [[ "$id" == "$current" ]]; then
        rows+=("$name  ✔"); selected_row=$i; current_name="$name"
    else
        rows+=("$name")
    fi
    row_ids+=("$id")
    ((i++)) || true
done

pkill -x rofi 2>/dev/null || true

choice_index="$(printf '%s\n' "${rows[@]}" | rofi -i -dmenu -format i \
    -config "$rofi_theme" \
    -theme-str 'entry { placeholder: " 🌐 Choose default web browser"; } listview { columns: 1; lines: 5; }' \
    -p "Default browser" \
    -mesg "Current: $current_name" \
    -selected-row "$selected_row")" || exit 0

[[ "$choice_index" =~ ^[0-9]+$ ]] || exit 0
new_id="${row_ids[$choice_index]}"
new_name="${sorted[$choice_index]#*$'\t'}"

if [[ "$new_id" == "$current" ]]; then
    notify-send "Default browser" "$new_name is already the default"
    exit 0
fi

if xdg-settings set default-web-browser "$new_id"; then
    notify-send "Default browser" "Switched to $new_name"
else
    notify-send -u critical "Default browser" "Failed to set $new_id (see xdg-settings)"
    exit 1
fi
