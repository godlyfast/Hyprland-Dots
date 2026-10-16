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

-- Lid open: eDP-1 renders directly and Moonlight is disabled. Lid closed: the Moonlight virtual desktop
-- (Sunshine's capture) owns the workspaces and eDP-1 is disabled. Exactly one is enabled, so a lid
-- change mid-stream makes Sunshine's capture fail and reselect the other output. (A lit eDP-1 mirroring
-- Moonlight rendered every frame twice and lagged the desktop; a dark mirror never failed, so the
-- stream went black.) ~/.local/bin/stream-route.sh (driven by lid-panel.sh) sets these flags and
-- reloads in two steps, both outputs enabled in between, so Hyprland never falls back to a headless output.
local function flag(name)
  local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/" .. name)
  if f then f:close() end
  return f ~= nil
end
local moonlight_on = flag("hypr-moonlight-on")
local panel_off = flag("hypr-panel-off")

hl.monitor({
  output = "Moonlight",
  -- 60 Hz = the fps Moonlight clients request; at 240 Hz 3 of 4 frames were rendered for nothing
  -- (iGPU ~91% vs ~51%). Raise it only if a client streams above 60 fps.
  mode = "2560x1600@60",
  -- Beside eDP-1 while both are enabled (no overlap); alone at the origin once the panel is off.
  position = panel_off and "0x0" or "1600x0",
  scale = "1.6",
  disabled = not moonlight_on,
})

-- Local: internal panel at native mode, 1.6 scale.
hl.monitor({
  output = "eDP-1",
  mode = "2560x1600@240",
  position = "0x0",
  scale = "1.6",
  disabled = panel_off,
})
