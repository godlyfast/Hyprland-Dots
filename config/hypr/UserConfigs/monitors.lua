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

-- Sunshine captures the Moonlight virtual desktop, which owns the workspaces only while the lid is closed.
-- Mirroring onto a lit panel renders every frame twice on the iGPU and lags the local desktop, so
-- ~/.local/bin/stream-route.sh (driven by lid-panel.sh) sets this flag and reloads on lid close only.
local flag = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-stream-route")
local streaming = flag ~= nil
if flag then flag:close() end

hl.monitor({
  output = "Moonlight",
  -- Lid open it is disabled: no render cost, and Sunshine falls back to capturing eDP-1.
  -- 60 Hz = the fps Moonlight clients request; at 240 Hz 3 of 4 frames were rendered for nothing
  -- (iGPU ~91% vs ~51%). Raise it only if a client streams above 60 fps.
  mode = "2560x1600@60",
  position = "0x0",
  scale = "1.6",
  disabled = not streaming,
})

-- Local: internal panel at native mode, 1.6 scale.
hl.monitor({
  output = "eDP-1",
  mode = "2560x1600@240",
  position = "0x0",
  scale = "1.6",
  mirror = streaming and "Moonlight" or nil,
})
