#!/usr/bin/env bash
# Check this repo's Lua Hyprland config without touching the live session:
# copies config/hypr into a throwaway HOME, then
#   1. luac -p on every .lua (syntax),
#   2. Hyprland --verify-config (unknown keys / rule fields), surfacing the
#      "[Lua] [WARN] Unable to load user override file" lines Hyprland logs at
#      DEBUG level: user_*.lua load through pcall, so a file that fails at
#      runtime still ends in "config ok",
#   3. tools/bindmap.lua: duplicate chords, exec targets that don't exist, and
#      any chords passed as arguments.
# Exit status is non-zero if any step finds a problem.
# usage: tools/verify-lua.sh ["SUPER SHIFT B" ...]
set -u
repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
H="$tmp/home/.config/hypr"
mkdir -p "$tmp/home/.config" "$tmp/run" && cp -a "$repo/config/hypr" "$H"
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config" XDG_RUNTIME_DIR="$tmp/run"
fail=0

for f in "$H"/hyprland.lua "$H"/lua/*.lua "$H"/configs/*.lua "$H"/UserConfigs/*.lua; do
  luac -p "$f" || fail=1
done
[ "$fail" = 0 ] && echo "luac: all files parse"

out="$(cd "$tmp" && timeout 30 Hyprland --verify-config -c "$H/hyprland.lua" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')"
printf '%s\n' "$out" | grep -E '\[Lua\] \[(WARN|ERROR)\]|^[^D=].' | sed "s#$tmp/home#~#g"
printf '%s\n' "$out" | grep -qE '\[Lua\] \[(WARN|ERROR)\]' && fail=1
printf '%s\n' "$out" | grep -qx 'config ok' || fail=1

VERIFY_LUA_SANDBOX=1 lua "$repo/tools/bindmap.lua" "$H" "$@" || fail=1
[ "$fail" = 0 ] && echo "verify-lua: PASS" || echo "verify-lua: FAIL"
exit "$fail"
