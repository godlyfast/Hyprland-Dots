# Hyprland-Dots Migration Guide

## Overview

This repository (`godlyfast/Hyprland-Dots`) carries local machine customizations as atomic
commits on top of the actively maintained `LinuxBeginnings/Hyprland-Dots` upstream
(successor of the archived `JaKooLit/Hyprland-Dots`).

**Original migration (JaKooLit → LinuxBeginnings):** 2026-05-05, base v2.3.23
**Last upgrade:** 2026-08-08, rebased onto `upstream/main` post-v2.3.25 (`bca86bbe`),
deployed to `~/.config` the same day (previous live config was JaKooLit v2.3.20)
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
| Configure Hyprland startup apps and disable hardware cursors | `configs/Startup_Apps.conf`, `configs/SystemSettings.conf` | Adds `rog-control-center`; `no_hardware_cursors = 1` (NVIDIA) |
| Update .gitignore for logs and backup files | `.gitignore` | Ignore `Copy-Logs/`, `*.backup` |
| Add migration documentation | `docs/MIGRATION.md` | This file |
| Sync local custom bindings, scripts and configs | `UserConfigs/*`, `scripts/*`, `UserScripts/RainbowBorders.sh` | Personal keybinds (Thunderbird, browsers, StatusCheck, SchedulerSwitch, HyprWave), touchpad device block, custom scripts (MemoryMonitor, ProfileSwitch, SidebarToggle, SwitchKeyboardLayout, WallpaperChange, StatusCheck) |
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
| "Sync post-May live drift" | SUPER+F floating / SUPER+SPACE layout-switch / waybar-layout-menu / wallpaper-change keybinds; 2px borders, 2/4 gaps |
| "Restore customizations lost in v2.3.20 → v2.3.25 migration" | `TouchPad.sh` `device[name]` v3 syntax; `Distro_update.sh` error-hold on failed paru/yay; `RefreshNoWaybar.sh` quickshell restart disabled; `WallpaperAutoChange` 5-min interval; Fn+F4 RGB via `asusctl aura effect --next-mode`; kitty numpad-Enter map; waybar keyboard-layout module (`cat ~/.cache/kb_layout` + `SwitchKeyboardLayout.sh` on-click); waybar custom app icons (Roon, Viber, Claude Code, Teams, Tidal, Steam, Chrome); user-rewritten `Tak0-Autodispatch.sh` → `UserScripts/` |
| "Fix script exec bits, keybind collisions, sidebar startup race" | `chmod +x` on all custom scripts (stored non-executable since May — every custom-script keybind failed silently with permission denied); keybind collision fixes; `SidebarToggle.sh` waits for quickshell IPC |

### Keybind decisions (machine-local)

| Bind | Action | Note |
|------|--------|------|
| SUPER+SPACE | `SwitchKeyboardLayout.sh` (us ⇄ ua) | stock float-toggle unbound |
| SUPER+F | toggle floating | stock "maximize" unbound |
| SUPER+CTRL+F | maximize window (`fullscreen, 1`) | relocated stock bind |
| SUPER+SHIFT+F | true fullscreen | stock |
| SUPER+SHIFT+B | Brave | stock RainbowBorders-low-cpu unbound |
| SUPER+CTRL+SHIFT+B | Booru sidebar (`SidebarToggle.sh`) | quickshell `booru-sidebar` config |

---

## Daily Workflow

### Pull latest upstream (stable)

```bash
cd ~/Hyprland-Dots
git fetch upstream
git rebase upstream/main        # replays the customization commits
git push --force-with-lease origin main
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

Waybar `ModulesWorkspaces` icons and the `ModulesCustom` keyboard-layout module are
committed in this repo since 2026-08-08 and deploy with copy.sh.

---

## Rollback

Backup branches (local):

- `backup-pre-upgrade-2026-08-08` — pre-upgrade `development` tip (old JaKooLit-era base + customizations)
- `backup-main-2026-08-08` — pre-upgrade `main`
- `backup-pre-migration` — original pre-May-2026 JaKooLit state

`copy.sh` also snapshots the live config to `~/.config/hypr-backup-*` before deploying.

---

## Links

- **Dotfiles upstream:** https://github.com/LinuxBeginnings/Hyprland-Dots
- **Installer upstream:** https://github.com/LinuxBeginnings/Arch-Hyprland
- **Fork:** https://github.com/godlyfast/Hyprland-Dots
