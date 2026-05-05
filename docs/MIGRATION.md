# Hyprland-Dots Migration Guide

## Overview

This repository (`godlyfast/Hyprland-Dots`) is a fork of the Hyprland desktop environment dotfiles, migrated from the archived `JaKooLit/Hyprland-Dots` to the actively maintained `LinuxBeginnings/Hyprland-Dots` upstream. All local machine customizations have been preserved as atomic commits on top of the new upstream.

**Date of migration:** 2026-05-05  
**Base upstream version:** v2.3.23 (`3e00d002`)  
**Original upstream:** `JaKooLit/Hyprland-Dots` (archived)  
**New upstream:** `LinuxBeginnings/Hyprland-Dots` (active)

---

## Architecture

The Hyprland ecosystem consists of two separate repositories:

| Repository | Purpose | Your Fork |
|------------|---------|-----------|
| `Hyprland-Dots` | Actual dotfiles/configs (`config/`, `copy.sh`) | `github.com/godlyfast/Hyprland-Dots` |
| `Arch-Hyprland` | Installer scripts (`install.sh`, `install-scripts/`) | `github.com/godlyfast/Arch-Hyprland` |

**Relationship:** The installer (`Arch-Hyprland`) does not contain configs. During installation, it clones `Hyprland-Dots` and runs `copy.sh` to deploy configs to `~/.config/`.

---

## Migration Summary

### What Changed

- **Upstream switched:** `origin` remote now points to `LinuxBeginnings/Hyprland-Dots`
- **116 new commits:** Migrated from archived JaKooLit `v2.3.20` to active LinuxBeginnings `v2.3.23`
- **Archiving notice removed:** The "Update README with project archiving notice" commit from JaKooLit is no longer in history
- **Local customizations preserved:** All 6 modified config/script files retained as atomic commits
- **Installer patched:** `godlyfast/Arch-Hyprland` is wired to clone `godlyfast/Hyprland-Dots` instead of upstream

### Customization Commits (on top of v2.3.23)

| Commit | File(s) | Description |
|--------|---------|-------------|
| `d718c4c` | `AGENTS.md` | Project context documentation |
| `88654cf` | `01-UserDefaults.conf`, `ENVariables.conf` | Editor = nvim, Bibata cursor theme, NVIDIA GPU env vars |
| `a7b558b` | `Startup_Apps.conf`, `SystemSettings.conf` | Startup apps (ROG, blueman, qs), hardware cursors disabled |
| `f6ee20a` | `Refresh.sh`, `RefreshNoWaybar.sh` | Quickshell restart enabled on refresh |
| `18fb4d5` | `.gitignore` | Ignore `Copy-Logs/` and `*.backup` files |

**Customizations in detail:**

- **Editor:** Changed default from `vim` to `nvim` (`$EDITOR = nvim`)
- **Cursor:** Enabled `Bibata-Modern-Ice` cursor theme (24px)
- **NVIDIA:** Set `LIBVA_DRIVER_NAME=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `NVD_BACKEND=direct`, `GSK_RENDERER=ngl`
- **Startup apps:** Added `rog-control-center`, `blueman-applet`, `qs` (quickshell), `KeybindsLayoutInit.sh`
- **Hardware cursors:** Disabled (`no_hardware_cursors = 1`) for NVIDIA compatibility
- **Quickshell:** Both refresh scripts restart quickshell on execution

---

## Remote Configuration

Your local `~/Hyprland-Dots` should have these remotes:

```bash
$ git remote -v
origin    https://github.com/godlyfast/Hyprland-Dots.git (fetch)
origin    https://github.com/godlyfast/Hyprland-Dots.git (push)
upstream  https://github.com/LinuxBeginnings/Hyprland-Dots.git (fetch)
upstream  https://github.com/LinuxBeginnings/Hyprland-Dots.git (push)
```

---

## Daily Workflow

### Pull Latest Upstream Changes

```bash
cd ~/Hyprland-Dots
git fetch upstream
git rebase upstream/main
git push origin main
```

This replays your 5 customization commits on top of the latest upstream.

### Push Customizations to Your Fork

```bash
git push origin main
```

---

## Fresh Machine Setup

### Option A: Full Automated Install (Arch Linux)

```bash
git clone https://github.com/godlyfast/Arch-Hyprland.git
cd Arch-Hyprland
./install.sh
```

The installer will:
1. Install all required packages
2. Clone `godlyfast/Hyprland-Dots` (your customized dotfiles)
3. Run `copy.sh` to deploy to `~/.config/`

### Option B: Dotfiles Only (Any Distro)

```bash
git clone https://github.com/godlyfast/Hyprland-Dots.git
cd Hyprland-Dots
./copy.sh
```

This only deploys configs. You must install Hyprland and dependencies separately.

---

## Rollback

If anything goes wrong, the pre-migration state is preserved:

```bash
git checkout main
git reset --hard backup-pre-migration
```

The `backup-pre-migration` branch contains the exact state before the migration (JaKooLit upstream + uncommitted local modifications).

---

## File Inventory

### Modified Files (6)

| File | Type | Customization |
|------|------|---------------|
| `config/hypr/UserConfigs/01-UserDefaults.conf` | Config | `$EDITOR = nvim` |
| `config/hypr/configs/ENVariables.conf` | Config | Bibata cursor + NVIDIA env vars |
| `config/hypr/configs/Startup_Apps.conf` | Config | Added 4 `exec-once` startup commands |
| `config/hypr/configs/SystemSettings.conf` | Config | `no_hardware_cursors = 1` |
| `config/hypr/scripts/Refresh.sh` | Script | Enabled `pkill qs && qs &` |
| `config/hypr/scripts/RefreshNoWaybar.sh` | Script | Enabled `pkill qs && qs &` |

### New Files (1)

| File | Description |
|------|-------------|
| `AGENTS.md` | Project context and workspace map for AI assistants |

### Ignored Files

```gitignore
Copy-Logs/
*.backup
```

---

## Troubleshooting

### Conflicts During `git rebase upstream/main`

If upstream modifies the same lines as your customizations:

1. Resolve the conflict in the affected file(s)
2. `git add <file>`
3. `git rebase --continue`

Most likely conflict area: `config/hypr/scripts/Refresh.sh` (if upstream changes process kill logic).

### Recovering Pre-Migration State

```bash
git branch -D main
git checkout -b main backup-pre-migration
```

---

## Upstream Links

- **Dotfiles:** https://github.com/LinuxBeginnings/Hyprland-Dots
- **Installer:** https://github.com/LinuxBeginnings/Arch-Hyprland
- **Wiki:** https://github.com/LinuxBeginnings/Hyprland-Dots/wiki
- **Changelogs:** https://github.com/LinuxBeginnings/Hyprland-Dots/wiki/Changelogs

## Your Forks

- **Dotfiles:** https://github.com/godlyfast/Hyprland-Dots
- **Installer:** https://github.com/godlyfast/Arch-Hyprland
