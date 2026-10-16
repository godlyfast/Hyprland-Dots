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

-- Local: workspaces live on the output that renders the desktop: the Moonlight virtual desktop
-- while the lid is closed (Sunshine captures it, eDP-1 mirrors it), eDP-1 otherwise. See stream-route.sh.
local flag = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-stream-route")
local streaming = flag ~= nil
if flag then flag:close() end

for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = streaming and "Moonlight" or "eDP-1", layout = "dwindle" })
end
