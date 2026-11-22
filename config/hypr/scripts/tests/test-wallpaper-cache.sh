#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib_test.sh
source "$HERE/lib_test.sh"

WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
HOME_DIR="$WORK/home"
BIN="$WORK/bin"
CACHE="$HOME_DIR/.cache/awww"
ENTRY="$CACHE/0.12.1/eDP-1"
mkdir -p -- "$BIN" "${ENTRY%/*}"
printf '%s\0' '/wallpapers/last.png' >"$WORK/expected"
cp -- "$WORK/expected" "$ENTRY"

# Expose only the tools needed by the fixture and the old migration.
for tool in bash mkdir rm touch; do
  ln -s -- "$(type -P "$tool")" "$BIN/$tool"
done
cat >"$BIN/awww" <<'EOS'
#!/usr/bin/env bash
[[ ${1:-} == clear-cache ]] || exit 1
# Reproduce the cache deletion without looking outside this fixture.
rm -f -- "${0%/*}/../home/.cache/awww/0.12.1/eDP-1"
EOS
chmod +x -- "$BIN/awww"

it 'sourcing WallpaperCmd preserves the versioned awww cache without a migration marker'
if ! env -i HOME="$HOME_DIR" PATH="$BIN" "$BASH" --noprofile --norc -ec \
  'source "$1"; [[ $WWW_CMD == awww ]]' _ "$SCRIPT_DIR/WallpaperCmd.sh"; then
  fail 'could not source WallpaperCmd.sh with awww selected'
elif ! cmp -s -- "$WORK/expected" "$ENTRY"; then
  fail 'the cached wallpaper entry was removed or changed'
elif [[ -e $CACHE/.cache_cleared || -L $CACHE/.cache_cleared ]]; then
  fail 'sourcing recreated the obsolete cache migration marker'
else
  pass_msg
fi

summary wallpaper-cache
