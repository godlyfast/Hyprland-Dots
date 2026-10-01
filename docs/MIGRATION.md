# Hyprland-Dots Migration Guide

## Overview

This repository (`godlyfast/Hyprland-Dots`) carries local machine customizations as atomic
commits on top of the actively maintained `LinuxBeginnings/Hyprland-Dots` upstream
(successor of the archived `JaKooLit/Hyprland-Dots`).

**Original migration (JaKooLit → LinuxBeginnings):** 2026-05-05, base v2.3.23
**Last upgrade:** 2026-10-01, **ported to Lua** on `upstream/main` at v2.3.27.5 (`40203767`).
Upstream deleted every Hyprlang `.conf` (starting with #128), so the customizations were re-written
as Lua overrides instead of replaying the 29 `.conf` commits (see "Lua port"). **Not deployed yet:**
the live session still runs the `.conf` config from the 2026-09-15 deploy until a Lua deploy.
Previous upgrades: 2026-09-15, v2.3.26.5 (`5cf37fb4`, last `.conf` base); 2026-08-08, post-v2.3.25.
**Tracked branch:** `upstream/main` (stable). Do NOT base on `upstream/development`.

---

## Architecture

| Repository | Purpose | Remote setup |
|------------|---------|--------------|
| `Hyprland-Dots` | Dotfiles/configs (`config/`, `copy.sh`) | fork `godlyfast/Hyprland-Dots` (origin) + `LinuxBeginnings/Hyprland-Dots` (upstream) |
| `Arch-Hyprland` | Installer scripts | **no fork** — tracks `LinuxBeginnings/Arch-Hyprland` directly (fork dropped 2026-08-08: it had zero unique commits and the installer clones the Dots repo itself) |

The installer clones `LinuxBeginnings/Hyprland-Dots` during install; on this machine,
deploy from `~/Hyprland-Dots` (this fork) with `copy.sh` instead.

---

## Lua port (2026-10-01)

Built on a fresh branch from `upstream/main` and fast-forwarded into `main`; the `.conf` history is
kept on `backup-main-2026-10-01`. Customizations live in the `UserConfigs/user_*.lua` layer
(loaded last by `lua/user_overrides.lua`, restored by copy.sh). Upstream files are edited only where
the user layer has no hook or would be clumsier: `lua/env.lua` (NVIDIA vars),
`configs/system_keybinds.lua` (the `repeating` fix, chosen over 16 user-layer rebinds),
`hypridle.conf` (lid guard), four scripts (WallustSwww, RefreshNoWaybar, WallpaperAutoChange,
Distro_update) and two waybar files (`hypr/waybar/ModulesWorkspaces`,
`hypr/waybar/style/Dark-Wallust-Obsidian-Edge.css`).

| Retired `.conf` | Lua home |
|-----------------|----------|
| `UserSettings.conf`, `configs/SystemSettings.conf` | `UserConfigs/user_settings.lua` (only values that differ from `lua/settings.lua`) |
| `UserDecorations.conf` | `UserConfigs/user_decorations.lua` |
| `UserKeybinds.conf`, `configs/Keybinds.conf` fixes, `Laptops.conf` Fn keys | `UserConfigs/user_keybinds.lua` |
| `01-UserDefaults.conf` (`EDITOR`/`VISUAL` = nvim) | `UserConfigs/user_env.lua` + `UserConfigs/user_defaults.lua` |
| `Laptops.conf` touchpad | `UserConfigs/user_laptops.lua` (replaced, see below) |
| `UserConfigs/Startup_Apps.conf`, `configs/Startup_Apps.conf` | `UserConfigs/user_startup.lua` |
| `WindowRules.conf`, `LayerRules.conf` | `UserConfigs/user_window_rules.lua`, `user_layer_rules.lua` |
| `monitors.conf`, `workspaces.conf` | `UserConfigs/monitors.lua`, `UserConfigs/workspaces.lua` |
| `configs/ENVariables.conf` | `lua/env.lua` (loaded through `configs/system_env.lua`) |
| `config/waybar/`, `config/kitty/kitty.conf` | upstream moved them: `config/hypr/waybar/`, `UserConfigs/kitty.conf` |

| Commit | What |
|--------|------|
| Carry fork-only scripts and docs onto the Lua base | MemoryMonitor, StatusCheck, SidebarToggle, SchedulerSwitch, ProfileSwitch, WallpaperChange, RofiBrowserSelect, wallust `RainbowBorders.sh`, `AGENTS.md`, this file. `Tak0-Autodispatch.sh` dropped (unused since 2026-09-15) |
| Re-apply local script, waybar and kitty tweaks | Wallust `--dynamic-threshold` retry, quickshell restart disabled, 300 s wallpaper interval, update-window error hold, workspace glyphs, no blue tray pill, kitty JetBrainsMono NF + black background + numpad Enter, `.gitignore` |
| Lua: port user settings and decorations | us,ua / pc105+inet, touchscreen off, master layout (`new_status = master`, on top, mfact 0.5), `allow_tearing`, `vrr = 2`, `mouse_move_enables_dpms = false`, `no_hardware_cursors = 1`, gaps 2/4, border 2, shadow range 3, blur `ignore_opacity = false` (upstream 76f3cedd only fixed the `.conf`) |
| Lua: port user keybinds and ASUS Fn keys | Keybind table below; SUPER+(SHIFT+)Tab collision fix; CTRL+ALT+W path fix; 8 stock binds that did nothing under Lua (ALT+Tab raise, group moves, move-workspace-to-monitor) rebound with native dispatchers |
| Lua: port laptop, monitor, workspace and window/layer rules | Touchpad off + TouchPad.sh state seed; eDP-1 2560x1600@240 scale 1.6; workspaces 1–5 on eDP-1; UT99 tearing rule; HyprWave blur |
| Lua: port startup apps, NVIDIA env and the hypridle lid guard | rog-control-center, blueman-applet (no longer in stock Lua startup), MemoryMonitor, login wallpaper, `lid-panel.sh`; `EDITOR`/`VISUAL` nvim; NVIDIA env commented; hypridle keeps upstream `hl.dsp.dpms` with every "on" lid-guarded |
| Scripts: make RainbowBorders and the browser picker work on the Lua base | `RainbowBorders.sh` set the border with `hyprctl keyword`, which Lua mode rejects (exit 0, so silently): now upstream's `set_gradient_border` (keyword, then `hyprctl eval`). `RofiBrowserSelect.sh` theme moved to `hypr/rofi/` (copy.sh empties `~/.config/rofi`, so SUPER+ALT+D was already broken live) |
| system_keybinds: use repeating, the option hl.bind reads | 16 stock binds pass `["repeat"] = true`, which `hl.bind` ignores (`HL.BindOptions.repeating`): volume, brightness and resize would not repeat when held. Drop once upstream fixes it |
| Docs: Lua port | This file, `AGENTS.md`, `tools/verify-lua.sh` + `tools/bindmap.lua` |

**`user_laptops.lua` is replaced, not patched.** Upstream's version disables the internal panel
whenever the lid is closed (at load, on every reload and on each lid event). eDP-1 is the only
monitor here, so that strands every workspace on a headless fallback output. The lid stays outside
the Hyprland config: logind `HandleLidSwitch=ignore` (`/etc/systemd/logind.conf.d/lid-switch.conf`,
closing the lid never suspends so agents keep running) and the machine-local
`~/.local/bin/lid-panel.sh`, which follows logind's `LidClosed` and turns eDP-1 DPMS off/on. It tries
the Lua `hl.dsp.dpms` dispatcher first and falls back to the `.conf` form, so it works on both.
Not `switch:` binds: libinput fakes a lid-open on internal key presses and lit the panel under the lid.

**Not ported (obsolete on the Lua base):** brightness-key de-duplication (Lua binds them once);
`KeybindsLayoutInit.sh` (obsolete in Lua mode); an explicit `RainbowBorders.sh` startup entry (system
`RainbowBordersStartup.sh` runs `UserScripts/RainbowBorders.sh` when no mode file is set); `Polkit-NixOS.sh` (no longer started); quickshell de-duplication
and the `lib_apps.sh` guard (upstream starts two distinct `qs` configs on purpose and no longer appends
`exec-once = qs`); the commented Virtual-1 monitor line; the oh-my-zsh SUPER+SHIFT+R move (a
leftover of the reverted keyboard switcher, so stock SUPER+SHIFT+O stays).

**Checking a port or rebase:** `tools/verify-lua.sh` copies `config/hypr` into a throwaway HOME and
exits non-zero on any finding:
- `luac -p` on every Lua file;
- `Hyprland --verify-config` (unknown keys and rule fields), plus the `[Lua] [WARN] Unable to load
  user override file` lines Hyprland only logs at DEBUG: user files load through `pcall`, so one that
  fails at runtime still ends in `config ok`;
- `tools/bindmap.lua`: `DUP` chords, `MISSING` exec targets (a command not on PATH or a script that
  does not exist; function binds are probed by calling them against a recording `hl.dispatch`, which
  catches `dispatch()` helpers that fall back to `hl.dsp.exec_raw`, i.e. a shell command) and
  `BADOPT` (`["repeat"]`).

Expected: `verify-lua: PASS` with no `DUP`, `MISSING` or `BADOPT` lines.

**Upstream bugs found while porting** (fixed or worked around here; worth reporting upstream):
`configs/system_keybinds.lua` CTRL+ALT+W and `waybar/ModulesCustom` right-click point at
`UserScripts/WallpaperRandom.sh` (it lives in `scripts/`; the waybar one is not patched here); 16
`["repeat"]` options; `lua/user_keybinds_helper.lua` has no `changegroupactive` case and falls back
to `hl.dsp.exec_raw`, i.e. a shell command; the same fallback in `configs/system_keybinds.lua`'s own
`dispatch()` kills `bringactivetotop`, `moveintogroup`, `moveoutofgroup` and
`movecurrentworkspacetomonitor` (ALT+Tab raise, SUPER+CTRL+J/L/H, SUPER+CTRL+F9–F12); `lua/decorations.lua` / `user_decorations.lua` still ship
`ignore_opacity = true` after 76f3cedd; `user_laptops.lua` disables the only monitor on lid close.

---

## Keybind decisions (machine-local)

| Bind | Action | Note |
|------|--------|------|
| SUPER+SPACE | float current window | **stock** |
| ALT+SHIFT / SHIFT+ALT | `KeyboardLayout.sh switch` (global) / `Tak0-Per-Window-Switch.sh` (per-window) | **stock** (us ⇄ ua) |
| SUPER+F / SUPER+SHIFT+F | maximize / true fullscreen | **stock** |
| SUPER+(SHIFT+)Tab | group cycling only (`hl.dsp.group.next/prev`) | stock also binds next/previous workspace to the same press; unbound |
| ALT+Tab | next window, then raise it (`window.cycle_next` + `window.bring_to_top`) | one bind replacing stock's pair: stock's `LuaCycleWindow.sh` + a dead `bringactivetotop` |
| SUPER+CTRL+J / L / H | move into group left / right, out of group | native `hl.dsp.window.move`; stock's binds ran a non-existent shell command |
| SUPER+CTRL+F9–F12 | move workspace to monitor l / r / u / d | native `hl.dsp.workspace.move`; same stock bug |
| CTRL+ALT+W | random wallpaper (`scripts/WallpaperRandom.sh`) | stock path points at `UserScripts/`, where the script is not |
| SUPER+SHIFT+T / C / B | Thunderbird / Chrome / Brave | B replaces stock static rainbow border |
| SUPER+ALT+D | default-browser picker (`UserScripts/RofiBrowserSelect.sh`) | rofi list of WebBrowser .desktop entries → `xdg-settings set default-web-browser`; also CLI `--get/--list/--set`; live-only symlink `~/.local/bin/default-browser` → the script (recreate if missing) |
| SUPER+CTRL+SHIFT+B | Booru sidebar (`SidebarToggle.sh`) | quickshell `booru-sidebar` config |
| SUPER+ALT+I / K / W | status / scheduler cycle / wallpaper | K, not stock-owned SUPER+ALT+S (scrolling V/H toggle) |
| SUPER+ALT+M / SUPER+CTRL+M | HyprWave visibility / expand | |
| Fn+F4 / Fn+F5 | `asusctl aura effect --next-mode` / `ProfileSwitch.sh` | replace stock RGB / fan-profile scripts |

---

<details><summary>Historical: the <code>.conf</code>-era fork (2026-05-05 → 2026-10-01)</summary>

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

</details>

</details>

---

## Daily Workflow

### Pull latest upstream (stable)

```bash
cd ~/Hyprland-Dots
git branch -f backup-main-$(date +%F) main
git fetch upstream
git rebase upstream/main        # replays the customization commits
tools/verify-lua.sh             # expect: verify-lua: PASS
# the active gh account (cendastsmyrjsn) cannot write to the fork; push as godlyfast
gh auth switch --user godlyfast && git push --force-with-lease origin main; gh auth switch --user cendastsmyrjsn
```

Expected conflict areas: `lua/env.lua` (NVIDIA block), `hypridle.conf`, `UserConfigs/user_*.lua`
(upstream edits its own templates). Resolve keeping upstream structure + local intent; a commit that
comes up empty means upstream absorbed it — skip it. Upstream's `user_laptops.lua` must stay replaced.

### Deploying to ~/.config

Run `./copy.sh --upgrade` (answer **NO** to Express mode; drive it in a tmux pty, never
unattended). copy.sh auto-restores the old `UserConfigs/` backup over the freshly-copied ones —
afterwards re-sync this repo's `UserConfigs/` and custom scripts to `~/.config/hypr/`.

**First Lua deploy (pending):** the live tree still has the `.conf` config and a dormant
`hyprland.lua.disable`. Expected sequence (re-check the prompts on the day):
1. Answer **`y`** to `Configuration will be migrated to LUA. Continue?` (`lib_prompts.sh`). The
   `.conf`-era answer was `n`, but upstream no longer ships any `.conf`, so `n` would leave
   `hyprland.lua.disable` on a tree with nothing to load. `y` runs `migrate-hypr-to-lua.sh` on the
   restored `.conf` UserConfigs.
2. **After** copy.sh: overwrite **all of** `~/.config/hypr/UserConfigs/` with this repo's
   `config/hypr/UserConfigs/` (`user_*.lua`, `monitors.lua`, `workspaces.lua`, `kitty.conf`, …).
   copy.sh's restore puts the old backup back with `rsync -a`, and the stale `kitty.conf` matters:
   under Lua, `lua/env.lua` points `KITTY_CONFIG_DIRECTORY` at `UserConfigs`, so it becomes kitty's
   active config (old font, no black background, `allow_remote_control yes`).
3. Confirm Hyprland loads `hyprland.lua` (`hyprctl dispatch hl.dsp.dpms '{ action = "on" }'` answers
   `ok`, not `Invalid dispatcher`), and keep `~/.local/bin/lid-panel.sh` (machine-local, not in this
   repo).

Then re-verify the machine-local invariants copy.sh is known to clobber (see workstation skill):

1. `hypridle.conf` `lock_cmd = pidof hyprlock || hyprlock` (exactly — nothing else), and every
   `hl.dsp.dpms … "on"` guarded by `grep -q open /proc/acpi/button/lid/LID0/state &&`
2. `~/.config/systemd/user/swaync.service` must NOT exist (no mask symlink)
3. NVIDIA env vars in `lua/env.lua` stay **commented** (`lib_detect.sh` re-uncomments them
   AND edits this repo's working tree — `git checkout -- config/` afterwards);
   `no_hardware_cursors = 1` comes from `user_settings.lua`
4. `UserConfigs/user_laptops.lua` is this repo's short version (touchpad off, no lid/monitor
   logic), not upstream's panel-disabling one
5. **Exec bits**: `find ~/.config/hypr/{scripts,UserScripts} -name '*.sh' ! -perm -u+x`
   must return nothing (non-executable scripts fail keybinds silently)
6. Waybar selection (live-only, reset by copy.sh/style scripts; waybar now lives in
   `~/.config/hypr/waybar`, see upstream `docs/HOWTO-Migrate-Waybar-To-Hypr.md`):
   layout `[TOP & BOT] SummitSplit v3`, style `[Dark] Wallust Obsidian Edge.css`
7. `UserConfigs/monitors.lua` has the eDP-1 `2560x1600@240`, scale `1.6` rule
8. Exactly one hypridle: `pgrep -xc hypridle` prints `1` (upstream `HypridleStartup.sh` starts
   it once and kills strays), and `hypridle.service` is not *enabled*
9. Icon pool: only `breeze-dark` matches `*Dark*` in `~/.icons`, `~/.local/share/icons`,
   `/usr/share/icons` (otherwise `DarkLight.sh` picks a random theme each login)
10. No keybind collisions: this prints nothing (ALT+Tab is one bind since the Lua port):
    `hyprctl binds -j | jq -r 'group_by([.submap,.modmask,.key]) | .[] | select(length>1) | "\(.[0].modmask) \(.[0].key)"'`
11. Updater quiet: `~/.config/hypr/scripts/KooLsDotsUpdate.sh` reports the current version.
    **Partial deploys** (copying files instead of copy.sh) must include `lua/env.lua`; the
    updater reads `DOTS_VERSION` from it
12. kitty: `~/.config/hypr/UserConfigs/kitty.conf` has `font_family JetBrainsMono Nerd Font Mono`,
    `background #000000` after the theme include, and `allow_remote_control socket-only`
13. Lid: exactly one `~/.local/bin/lid-panel.sh` running; closing the lid turns eDP-1 DPMS off
    (`cat /sys/class/drm/card*-eDP-1/dpms` → `Off`) and opening it turns it back on

Waybar `ModulesWorkspaces` icons are committed in this repo and deploy with copy.sh.

---

## Rollback

Backup branches (local):

- `backup-main-2026-10-01` — `main` before the Lua port (last `.conf` fork, v2.3.26.5 base)
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
