# Hyprland-Dots Migration Guide

## Overview

This repository (`godlyfast/Hyprland-Dots`) carries local machine customizations as atomic
commits on top of the actively maintained `LinuxBeginnings/Hyprland-Dots` upstream
(successor of the archived `JaKooLit/Hyprland-Dots`).

**Original migration (JaKooLit → LinuxBeginnings):** 2026-05-05, base v2.3.23
**Last upgrade:** 2026-08-08, rebased onto `upstream/main` post-v2.3.25 (`bca86bbe`)
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
Bibata-Modern-Ice cursor theme, quickshell restart in `Refresh.sh`/`RefreshNoWaybar.sh`,
`blueman-applet`/`qs`/`KeybindsLayoutInit.sh` startup entries.

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

Run `./copy.sh` (answer **NO** to Express mode). Afterwards re-verify the
machine-local invariants that copy.sh is known to clobber (see workstation skill):

1. `hypridle.conf` `lock_cmd = pidof hyprlock || hyprlock` (exactly — nothing else)
2. `~/.config/systemd/user/swaync.service` must NOT exist (no mask symlink)
3. NVIDIA env vars in `configs/ENVariables.conf` stay **commented**
   (`detect_nvidia_adjust()` re-uncomments them)
4. Touchpad device block present in `UserConfigs/Laptops.conf`
5. Waybar `ModulesWorkspaces` window-rewrite customizations (waybar config is not
   in git; icons for Chrome, Thunderbird, Roon, Viber, Claude Code, Teams, Tidal, Steam)

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
