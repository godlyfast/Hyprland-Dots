-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- User laptop overrides (godlyfast fork: ASUS ROG, eDP-1 is the only monitor).
--
-- Upstream's version of this file disables the internal panel whenever the lid
-- is closed: at config load, on every reload and on each lid switch event. With
-- eDP-1 as the only monitor that moves every workspace to a headless fallback
-- output, so it is replaced here. The lid is handled outside Hyprland's config:
--   * logind HandleLidSwitch=ignore (/etc/systemd/logind.conf.d/lid-switch.conf):
--     closing the lid never suspends, so agents keep running.
--   * ~/.local/bin/lid-panel.sh (user_startup.lua) follows logind's LidClosed and
--     turns eDP-1 DPMS off/on. Not switch:on/off binds: libinput fakes a lid-open
--     on internal key presses and would light the panel under the lid.
-- Fn+F4/Fn+F5 are bound in user_keybinds.lua.

-- Touchpad off by default; Fn+F10 (scripts/TouchPad.sh) toggles it.
-- No `local`: TouchPad.sh finds the device by grepping this exact line.
touchpad_device = "asuf1205:00-2808:0106-touchpad"
hl.device({ name = touchpad_device, enabled = false })

-- TouchPad.sh treats a missing state file as "enabled", which made the first
-- Fn+F10 press a no-op. Record the real state on every (re)load.
local status = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/touchpad.status", "w")
if status then
  status:write("false\n")
  status:close()
end
