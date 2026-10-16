-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- User workspace rules for Lua workflow.
-- PersistWorkspaceLayout.sh writes workspace layout rules into this file.
-- Keep custom hl.workspace_rule(...) entries here so upgrades preserve them.

-- Example:
-- hl.workspace_rule({
--     workspace = "1",
--     monitor = "eDP-1",
--     layout = "dwindle",
-- })

-- Local: workspaces live on the enabled output: the Moonlight virtual desktop while the lid is
-- closed (eDP-1 disabled, Sunshine captures Moonlight), eDP-1 otherwise. See stream-route.sh.
local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-panel-off")
local panel_off = f ~= nil
if f then f:close() end

for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = panel_off and "Moonlight" or "eDP-1", layout = "dwindle" })
end
