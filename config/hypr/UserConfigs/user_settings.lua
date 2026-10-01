-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- User settings overrides template.
-- Add your personal hl.config(...) values here.

hl.config({
  input = {
    kb_layout = "us,ua",
    kb_variant = "",
    kb_model = "pc105+inet",
    kb_options = "",
    kb_rules = "",
    repeat_rate = 50,
    repeat_delay = 300,
    sensitivity = 0,
    numlock_by_default = true,
    left_handed = false,
    follow_mouse = 1,
    float_switch_override_focus = false,
    touchpad = {
      disable_while_typing = true,
      natural_scroll = true,
      clickfinger_behavior = false,
      middle_button_emulation = false,
      tap_to_click = true,
      drag_lock = false,
    },
    touchdevice = {
      enabled = false,
    },
    tablet = {
      transform = 0,
      left_handed = 0,
    },
  },
})

-- ===== Local (godlyfast fork): values that differ from lua/settings.lua =====
hl.config({
  master = {
    new_status = "master",
    new_on_top = true,
    mfact = 0.5,
  },
  general = {
    allow_tearing = true,
  },
  misc = {
    vrr = 2,
    -- true lit the panel under a closed lid; ~/.local/bin/lid-panel.sh owns eDP-1 DPMS
    mouse_move_enables_dpms = false,
  },
  cursor = {
    -- NVIDIA hybrid: hardware cursors glitch
    no_hardware_cursors = 1,
  },
})

-- Example:
-- hl.config({
--   general = {
--     gaps_in = 4,
--     gaps_out = 8,
--     border_size = 1,
--   },
-- })
--

-- Disable cursor being centered when swap workspaces
--
-- hl.config({
-- 	cursor = {
-- 		no_warps = true,
-- 		warp_on_change_workspace = 0,
-- 	},
-- })
