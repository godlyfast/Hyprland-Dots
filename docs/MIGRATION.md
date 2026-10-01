# Hyprland-Dots Migration Guide

## Overview

This repository (`godlyfast/Hyprland-Dots`) carries local machine customizations as atomic
commits on top of the actively maintained `LinuxBeginnings/Hyprland-Dots` upstream
(successor of the archived `JaKooLit/Hyprland-Dots`).

**Original migration (JaKooLit → LinuxBeginnings):** 2026-05-05, base v2.3.23
**Last upgrade:** 2026-09-15, rebased onto `upstream/main` at v2.3.26.5 (`5cf37fb4`) and
deployed to `~/.config` by targeted copies plus a full file-by-file audit (see
"Live-vs-upstream decisions"). Previous upgrade: 2026-08-08, post-v2.3.25 (`bca86bbe`).
**Tracked branch:** `upstream/main` (stable). Do NOT base on `upstream/development` —
it is mid-flight in a Lua config conversion and frequently broken.

---

## Architecture

| Repository | Purpose | Remote setup |
|------------|---------|--------------|
| `Hyprland-Dots` | Dotfiles/configs (`config/`, `copy.sh`) | fork `godlyfast/Hyprland-Dots` (origin) + `LinuxBeginnings/Hyprland-Dots` (upstream) |
| `Arch-Hyprland` | Installer scripts | **no fork** — tracks `LinuxBeginnings/Arch-Hyprland` directly (fork dropped 2026-08-08: it had zero unique commits and the installer clones the Dots repo itself) |

The installer clones `LinuxBeginnings/Hyprland-Dots` during install; on this machine,
deploy from `~/Hyprland-Dots` (this fork) with `copy.sh` instead.

---

## Customization Commits (on top of upstream/main)

| Commit subject | File(s) | Description |
|----------------|---------|-------------|
| Add AGENTS.md for project context | `AGENTS.md` | AI-assistant workspace map |
| Comment out NVIDIA env vars; set editor to nvim | `configs/ENVariables.conf` | **Inverted vs 2026-05**: upstream now ships NVIDIA env vars uncommented; this machine needs them commented because `start-hyprland.sh` sets GPU vars dynamically per `supergfxctl` mode |
| Configure Hyprland startup apps and disable hardware cursors | `configs/Startup_Apps.conf`, `configs/SystemSettings.conf` | Adds `rog-control-center`. Hardware cursors off (NVIDIA): `SystemSettings.conf` keeps upstream's `no_hardware_cursors = 0`, and `UserConfigs/UserSettings.conf` (sourced later) sets `1`, which is the effective value |
| Update .gitignore for logs and backup files | `.gitignore` | Ignore `Copy-Logs/`, `*.backup` |
| Add migration documentation | `docs/MIGRATION.md` | This file |
| Sync local custom bindings, scripts and configs | `UserConfigs/*`, `scripts/*`, `UserScripts/RainbowBorders.sh` | Personal keybinds (Thunderbird, browsers, StatusCheck, SchedulerSwitch, HyprWave), touchpad device block, custom scripts (MemoryMonitor, ProfileSwitch, SchedulerSwitch, SidebarToggle, WallpaperChange, StatusCheck), HyprWave blur layer rules (`LayerRules.conf`), native UT99 window rules: tearing, opaque, no blur/shadow/dim (`WindowRules.conf`). `SwitchKeyboardLayout.sh` was also added here and removed 2026-09-15 |
| Keep user settings compatible with Hyprland 0.55 | `UserConfigs/UserSettings.conf` | Removes `pseudotile`/`vfr` (dropped in Hyprland 0.55+; still correct on 0.56) |

**Absorbed by upstream (no longer fork commits):** nvim as default editor,
Bibata-Modern-Ice cursor theme, `blueman-applet`/`qs`/`KeybindsLayoutInit.sh` startup
entries, `PortalHyprland.sh` autostart (Chrome-GTK4 crash fix), togglesplit `layoutmsg`
fix, `KooLsDotsUpdate.sh` curl hardening, kitty `-e` in `Distro_update.sh`.

### Post-deploy audit commits (2026-08-08)

After deploying, every backed-up config tree was diffed against the exact JaKooLit
v2.3.20 baseline to find local edits the upgrade dropped. Three more commits resulted:

| Commit | What it restores |
|--------|------------------|
| "Sync post-May live drift" | SUPER+F floating / SUPER+SPACE layout-switch / waybar-layout-menu / wallpaper-change keybinds; 2px borders, 2/4 gaps. *SUPER+F, SUPER+SPACE and the waybar-layout-menu bind are superseded; see the commit table below* |
| "Restore customizations lost in v2.3.20 → v2.3.25 migration" | `TouchPad.sh` `device[name]` v3 syntax; `Distro_update.sh` error-hold on failed paru/yay; `RefreshNoWaybar.sh` quickshell restart disabled; `WallpaperAutoChange` 5-min interval; Fn+F4 RGB via `asusctl aura effect --next-mode`; kitty numpad-Enter map; waybar keyboard-layout module (`cat ~/.cache/kb_layout` + `SwitchKeyboardLayout.sh` on-click; *reverted to stock 2026-09-15*); waybar custom app icons (Roon, Viber, Claude Code, Teams, Tidal, Steam, Chrome); user-rewritten `Tak0-Autodispatch.sh` → `UserScripts/` |
| "Fix script exec bits, keybind collisions, sidebar startup race" | `chmod +x` on all custom scripts (stored non-executable since May — every custom-script keybind failed silently with permission denied); keybind collision fixes; `SidebarToggle.sh` waits for quickshell IPC |
| "Kitty: pin black background, JetBrainsMono NF" | Upstream v2.3.25 switched kitty to the wallust theme (`01-Wallust.conf`), which made the background follow the wallpaper (blue on 2026-08-08). Fix: `background #000000` at the END of `kitty.conf` (after the theme include — kitty is last-value-wins), so ANSI colors/cursor/tabs still re-theme per wallpaper while the background stays black. Font: FantasqueSansM → `JetBrainsMono Nerd Font Mono` |

### Later commits (2026-08-10 → 2026-10-01)

| Commit | File(s) | What and why |
|--------|---------|--------------|
| Waybar: add workspace glyph for hiresTI player | `waybar/ModulesWorkspaces` | `class<com.hiresti.player>` → disc glyph; the tile otherwise fell through to the default red X |
| Keybinds: bind Chrome to SUPER+SHIFT+C, drop two redundant binds | `UserConfigs/UserKeybinds.conf` | Chrome on SUPER+SHIFT+C. Dropped SUPER+ALT+F (Firefox is the xdg https default, stock SUPER+B reaches it) and SUPER+SHIFT+ALT+B (duplicated stock SUPER+ALT+B waybar layout menu) |
| Wallust: retry with a dynamic threshold on low-color wallpapers | `scripts/WallustSwww.sh` | Flat wallpapers made wallust fail with "Not enough colors!", leaving the old palette. Retries once with `--dynamic-threshold`, only for that error and only if the flag exists |
| Ignore .omc/ runtime state | `.gitignore` | Claude Code session state; `.omc/skills/` stays committable |
| Add rofi default-browser picker (SUPER+ALT+D) | `UserScripts/RofiBrowserSelect.sh`, `UserKeybinds.conf` | See keybind table |
| Sync live drift and de-duplicate upstream startup entries | `monitors.conf`, `workspaces.conf`, `configs/Startup_Apps.conf` | eDP-1 at 2560x1600@240 scale 1.6; Virtual-1 entry commented; workspaces pinned to eDP-1; one quickshell instance (`qs -c overview`); NixOS polkit agent commented (`Polkit.sh` already starts hyprpolkitagent) |
| Re-apply local overrides that copy.sh reverts on every deploy | `ENVariables.conf`, `RefreshNoWaybar.sh`, `Startup_Apps.conf`, `scripts/lib_apps.sh`, keyboard settings | NVIDIA vars commented; quickshell restart kept disabled as `# pkill` so `enable_quickshell` can't re-enable it; `lib_apps.sh` matches any `exec-once = qs` so copy.sh stops appending duplicate launchers (live had reached four); keyboard `us,ua` / `pc105+inet` |
| Resolve keybind collisions introduced by v2.3.26.4 | `configs/Keybinds.conf`, `UserKeybinds.conf` | Brightness keys were bound in both `Keybinds.conf` and `Laptops.conf` (double step): Laptops pair kept. SUPER+(SHIFT+)Tab switched workspace *and* cycled groups: group cycling kept. SchedulerSwitch moved SUPER+ALT+S → SUPER+ALT+K |
| Waybar: drop the blue tray pill from the active style | `waybar/style/Dark-Wallust-Obsidian-Edge.css` | Upstream's tray readability override paints items on an opaque blue pill; made transparent with `@foreground` glyphs. **Only this style is patched**: switching style brings the blue back |
| Keyboard: route all layout binds to one global switcher → Keyboard: drop custom layout switcher, restore stock SUPER+SPACE | keybinds (conf + Lua), `ModulesCustom`, `UserKeybinds.conf` | Added 2026-08-10, fully reverted to upstream 2026-09-15. Net fork diff for keyboard layout: none |
| Sync live decisions from full config audit | `Laptops.conf`, `workspaces.conf`, this file | Lid binds stay commented; workspace 4 pinned; audit decisions recorded below |
| Keybinds: restore stock SUPER+F maximize | `UserKeybinds.conf` | The SUPER+F float override duplicated stock SUPER+SPACE once that was restored; SUPER+CTRL+F freed |
| hypridle: use .conf dpms dispatcher, never light the panel under a closed lid | `hypridle.conf` | Upstream's `hl.dsp.dpms '{ action = "…" }'` is Lua-only: on this `.conf` session it prints `Invalid dispatcher` (exit 0), so the 12-min screen-off and `after_sleep_cmd` never ran. Now `hyprctl dispatch dpms off/on`, with every `on` guarded by `grep -q open /proc/acpi/button/lid/LID0/state`. Switch back to `hl.dsp.dpms` after a Lua migration |

### Keybind decisions (machine-local)

| Bind | Action | Note |
|------|--------|------|
| SUPER+SPACE | float current window | **stock** (layout-switch override dropped 2026-09-15) |
| ALT+SHIFT / SHIFT+ALT | `KeyboardLayout.sh switch` (global) / `Tak0-Per-Window-Switch.sh` (per-window) | **stock** (us ⇄ ua), see below |
| SUPER+F | maximize window (`fullscreen, 1`) | **stock** (float override + SUPER+CTRL+F maximize dropped 2026-09-15; it duplicated SUPER+SPACE) |
| SUPER+SHIFT+F | true fullscreen | stock |
| SUPER+SHIFT+B | Brave | stock RainbowBorders-low-cpu unbound |
| SUPER+CTRL+SHIFT+B | Booru sidebar (`SidebarToggle.sh`) | quickshell `booru-sidebar` config |
| SUPER+ALT+D | default-browser picker (`UserScripts/RofiBrowserSelect.sh`) | rofi list of WebBrowser .desktop entries → `xdg-settings set default-web-browser`; also CLI `--get/--list/--set`; live-only symlink `~/.local/bin/default-browser` → the script (not deployed by copy.sh, recreate if missing); added 2026-08-17 |

#### Live-vs-upstream decisions (2026-09-15 full audit)

| Setting | Decision | Why |
|---------|----------|-----|
| `UserDecorations.conf` blur `xray` / `ignore_opacity` | **upstream** (`false`) | Upstream `76f3cedd` (2026-07-11) set both to false to fix qs-hyprview blur. Live had kept `true` because copy.sh restores the old `UserConfigs/` backup over every deploy. |
| `UserConfigs/Laptops.conf` lid binds | **local**: commented out | Since 2026-10-01 the lid never suspends (`/etc/systemd/logind.conf.d/lid-switch.conf`: `HandleLidSwitch*=ignore`, so agents keep running); the panel follows the lid via machine-local `~/.local/bin/lid-panel.sh` (logind `LidClosed` → `dpms off/on eDP-1`), not `switch:` binds: libinput fakes a lid-open on internal key presses. Upstream's `LidSwitch.sh` disables eDP-1, which as the only monitor shuffles every workspace. |
| `workspaces.conf` | **local**: workspaces 1–5 pinned to eDP-1 | Live had the workspace 4 pin, which never made it into the fork. |
| waybar `Modules` / layouts `"device": "intel_backlight"` | **upstream** (removed, #113) | This laptop only has `nvidia_wmi_ec_backlight`; the hardcoded device broke the brightness module. |
| `quickshell/` (except `overview/` widget fix) | **local**, not redeployed | Live is the January install with personal settings (Booru sidebar); copy.sh only replaces it on an explicit yes. `overview` keeps `scale: 0.12`. |

A full audit compares every file under `config/` with `~/.config/`. Expected noise: wallust colour
files (including `cava/config`, which is generated from wallust's `colors-cava` template on every
wallpaper change), `hypr/wallpaper_effects/.wallpaper_current`, `swaync/style.css` and `qt5ct`/`qt6ct` (rewritten at login by the theme script), and
`ags/` (not installed). Backups of files replaced on 2026-09-15: `~/.config/dots-backup-2026-09-15/`.

#### Keyboard layout: back on the upstream mechanism (2026-09-15)

The fork no longer carries a layout switcher. `SwitchKeyboardLayout.sh` was deleted and every
bind (`configs/Keybinds.conf`, Lua equivalents) plus the waybar `custom/keyboard` module are
stock again: `KeyboardLayout.sh` for the global switch and waybar status, `Tak0-Per-Window-Switch.sh`
for per-window. The reason was to stop maintaining a private script that has to be re-merged
on every rebase. v2.3.26.5 also fixed the Lua modifier spelling (`ALT` + `Shift_L`/`Shift_R`
rather than `ALT_L` as a modifier). SUPER+SPACE is stock float-toggle again.

If the per-window listener's snap-back described below shows up again, the fix belongs upstream
(or in a one-line bind override in `UserConfigs/UserKeybinds.conf`), not in a forked script.

<details><summary>Historical: why the fork diverged 2026-08-10 → 2026-09-15</summary>

v2.3.25 shipped two `bindlnd` entries on the **same** Alt+Shift chord, running **different**
scripts — `ALT_L, SHIFT_L` → `KeyboardLayout.sh switch` (global) and `SHIFT_L, ALT_L` →
`Tak0-Per-Window-Switch.sh` (per-window). Which one fired depended on finger order, so with
`kb_layout = us,ua` the layout behaved chaotically. Three compounding defects:

1. **Same chord, two semantics.** Both binds are non-consuming (`n`), so the chord isn't
   swallowed; whichever order you hit picked a different layout model.
2. **A self-installing daemon.** `Tak0-Per-Window-Switch.sh` forks `--listener` in the
   background on first use (it is in no `Startup_Apps.conf`). That listener subscribes to
   `.socket2.sock` and calls `cmd_restore` on **every** `activewindow` event; any window absent
   from `~/.cache/kb_layout_per_window` falls back to `kb_layouts[0]` = `us`. Net effect: switch
   to `ua`, click another window, get snapped back to `us`.
3. **Three scripts, three state files.** `SwitchKeyboardLayout.sh` → `~/.cache/kb_layout`;
   `KeyboardLayout.sh` → nothing; `Tak0` → `~/.cache/kb_layout_per_window`. Waybar reads
   `~/.cache/kb_layout`, so the indicator desynced from the real keymap.

**Resolution.** All layout binds route to `SwitchKeyboardLayout.sh` — the only switcher that
writes the waybar cache. Both key orders are bound to it, so the result is order-independent
(exactly one toggle fires per gesture: at Shift-down the held mod is Alt, and vice versa).
Patched in `configs/Keybinds.conf` plus the dormant Lua equivalents (`lua/keybinds.lua`,
`configs/system_keybinds.lua`) so the bug does not return at the Hyprland Lua migration.

Do **not** restore the upstream pair on rebase. If per-window switching is ever wanted, it needs
a single unambiguous chord, an explicit `exec-once` listener, and a patch making Tak0 write
`~/.cache/kb_layout`. Check after every upstream rebase:
`hyprctl binds -j | jq -r '.[] | select(.dispatcher=="exec" and (.arg|test("KeyboardLayout|Tak0")))'`

---

## Daily Workflow

### Pull latest upstream (stable)

```bash
cd ~/Hyprland-Dots
git branch -f backup-main-$(date +%F) main
git fetch upstream
git rebase upstream/main        # replays the customization commits
# the active gh account (cendastsmyrjsn) cannot write to the fork; push as godlyfast
gh auth switch --user godlyfast && git push --force-with-lease origin main; gh auth switch --user cendastsmyrjsn
```

Expected conflict areas: `configs/ENVariables.conf` (NVIDIA block),
`configs/Startup_Apps.conf`, `UserConfigs/*`. Resolve keeping upstream structure +
local intent; a cherry-pick that comes up empty means upstream absorbed it — skip it.

### Deploying to ~/.config

Run `./copy.sh --upgrade` (answer **NO** to Express mode). copy.sh auto-restores the
old `UserConfigs/` backup over the freshly-copied ones — afterwards re-sync this repo's
`UserConfigs/` and custom scripts to `~/.config/hypr/`, then re-verify the machine-local
invariants copy.sh is known to clobber (see workstation skill):

1. `hypridle.conf` `lock_cmd = pidof hyprlock || hyprlock` (exactly — nothing else;
   upstream ships this since v2.3.25, but verify)
2. `~/.config/systemd/user/swaync.service` must NOT exist (no mask symlink)
3. NVIDIA env vars in `configs/ENVariables.conf` stay **commented**
   (`detect_nvidia_adjust()` re-uncomments them AND edits this repo's working tree —
   `git checkout -- config/` afterwards); `no_hardware_cursors = 1` (hybrid path sets 0)
4. Touchpad device block present in `UserConfigs/Laptops.conf`
5. **Exec bits**: `find ~/.config/hypr/{scripts,UserScripts} -name '*.sh' ! -perm -u+x`
   must return nothing (non-executable scripts fail keybinds silently)
6. Waybar selection symlinks (live-only, reset by copy.sh/style scripts):
   `config` → `[TOP & BOT] SummitSplit v3`, `style.css` → `[Dark] Wallust Obsidian Edge.css`
7. `monitors.conf`: explicit `monitor=eDP-1,2560x1600@240.0,0x0,1.6` line present
   (deploy may replace the nwg-displays file with the stock template)
8. Exactly one hypridle: `pgrep -xc hypridle` prints `1`, and `hypridle.service` is not enabled
9. Icon pool: only `breeze-dark` matches `*Dark*` in `~/.icons`, `~/.local/share/icons`,
   `/usr/share/icons` (otherwise `DarkLight.sh` picks a random theme each login)
10. No keybind collisions: the only duplicate should be the intentional ALT+Tab pair
    (`cyclenext` + `bringactivetotop`):
    `hyprctl binds -j | jq -r 'group_by([.submap,.modmask,.key]) | .[] | select(length>1) | "\(.[0].modmask) \(.[0].key)"'`
11. Updater quiet: `~/.config/hypr/scripts/KooLsDotsUpdate.sh` reports the current version.
    **Partial deploys** (copying files instead of copy.sh) must include `lua/env.lua` and
    `configs/ENVariables.conf`; the updater reads `DOTS_VERSION` from them

Waybar `ModulesWorkspaces` icons are committed in this repo since 2026-08-08 and deploy
with copy.sh. The keyboard-layout module is stock again (2026-09-15).

---

## Rollback

Backup branches (local):

- `backup-main-2026-09-15` — `main` before the v2.3.26.5 rebase
- `backup-pre-upgrade-2026-08-08` — pre-upgrade `development` tip (old JaKooLit-era base + customizations)
- `backup-main-2026-08-08` — pre-upgrade `main`
- `backup-pre-migration` — original pre-May-2026 JaKooLit state

`copy.sh` also snapshots the live config to `~/.config/hypr-backup-*` before deploying.
The 2026-09-15 targeted deploy backed up every replaced live file to
`~/.config/dots-backup-2026-09-15/` (same relative paths as `~/.config`).

---

## Links

- **Dotfiles upstream:** https://github.com/LinuxBeginnings/Hyprland-Dots
- **Installer upstream:** https://github.com/LinuxBeginnings/Arch-Hyprland
- **Fork:** https://github.com/godlyfast/Hyprland-Dots
