# AGENTS.md — Hyprland-Dots/

Parent: `~/AGENTS.md`

## OVERVIEW

JaKooLit Hyprland dotfiles fork for Arch Linux (CachyOS). ~960 config files across Hyprland, AGS, Quickshell, Waybar, Rofi, Kitty, and more. Orchestrated by `copy.sh` for install/upgrade.

> **Note:** Project being archived March 2026; maintained by [Dwilliams](https://github.com/LinuxBeginnings).

## STRUCTURE

```
Hyprland-Dots/
├── config/
│   ├── hypr/          # Hyprland Lua config, scripts, UserConfigs (incl. kitty.conf),
│   │                  #   waybar/, rofi/, wallust/ (moved under hypr/ by upstream)
│   ├── ags/           # AGS widgets (config.js, modules, user_options.js)
│   ├── quickshell/    # Quickshell overview widget
│   ├── btop/          # btop config + themes
│   ├── cava/          # Audio visualizer config + shaders
│   ├── fastfetch/     # Fastfetch configs
│   ├── Kvantum/       # Qt theme configs
│   └── ...            # qt5ct, qt6ct, ghostty, wezterm, wlogout, swaync, yazi
├── scripts/           # copy.sh library modules (lib_*.sh)
├── tools/             # fork-only: verify-lua.sh + bindmap.lua (offline config checks)
├── copy.sh            # Main install/upgrade orchestrator
├── assets/            # Wallpapers, images
└── wallpapers/        # Default wallpaper pack
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Install / upgrade dotfiles | `copy.sh` | Interactive; express mode overwrites customizations |
| Hyprland core settings | `config/hypr/` | Lua: `hyprland.lua` → `lua/user_overrides.lua` → `configs/system_*.lua`, then `UserConfigs/user_*.lua` |
| Fork customizations | `config/hypr/UserConfigs/user_*.lua`, `lua/env.lua` | Map and rationale: `docs/MIGRATION.md` "Lua port"; check with `tools/verify-lua.sh` |
| Hyprland utility scripts | `config/hypr/scripts/` | 30+ shell scripts (brightness, keybinds, gamemode, etc.) |
| AGS widgets | `config/ags/` | `config.js` entry; modules in `modules/` |
| Quickshell overview | `config/quickshell/` | Separate from booru-sidebar repo |
| Waybar | `config/hypr/waybar/` | Configs in `configs/`; styles in `style/` (moved under `hypr/` by upstream) |
| Colors / theming | `config/hypr/wallust/` | Templates generate colors for multiple apps |

## CONVENTIONS

### Shell Scripts
- Shebang: `#!/bin/bash`
- Colored output via `tput setaf`
- `copy.sh` sources modular helpers: `lib_detect.sh`, `lib_prompts.sh`, `lib_backup.sh`, `lib_copy.sh`, `lib_apps.sh`, `lib_update.sh`, `copy_menu.sh`

### Config Files
- Hyprland: Lua (`hyprland.lua`) since the 2026-10-01 port; upstream deleted the Hyprlang `.conf` files
- AGS: JavaScript (`config.js`, `user_options.js`)
- Quickshell: QML
- Waybar: JSON configs + CSS styles

## ANTI-PATTERNS

- **NEVER answer YES to `copy.sh` Express mode** — overwrites all customizations without per-file prompts. Backups land at `~/.config/hypr-backup-back-up_*/`.
- **Never hardcode GPU env vars in `lua/env.lua`** — use `supergfxctl -g` dynamic detection via `~/.local/bin/start-hyprland.sh`.
- **Never run `copy.sh` as root** — script checks and refuses.

## COMMANDS

```bash
# Install or upgrade dotfiles (interactive)
./copy.sh

# Check the Lua config offline before deploying (fork-only)
tools/verify-lua.sh

# Run express mode (DANGEROUS — overwrites everything)
./copy.sh --express
```

## NOTES

- `config/hypr/UserConfigs/` — user overrides that survive copy.sh
- `config/hypr/UserScripts/` — user custom scripts
- `scripts/` contains `lib_*.sh` modules used by `copy.sh`; not standalone utilities
