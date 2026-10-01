-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- User monitor overrides for Lua workflow.
-- MonitorProfiles.sh writes selected Lua monitor profiles into this file.
-- Keep custom hl.monitor(...) entries here so upgrades preserve them.

-- Example:
-- hl.monitor({
--     output = "eDP-1",
--     mode = "preferred",
--     position = "auto",
--     scale = "1",
-- })

-- Local: internal panel at native mode, 1.6 scale.
hl.monitor({
  output = "eDP-1",
  mode = "2560x1600@240",
  position = "0x0",
  scale = "1.6",
})
