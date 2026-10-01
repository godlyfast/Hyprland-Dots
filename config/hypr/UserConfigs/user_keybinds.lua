-- User keybind overrides.
-- Add, override, or rebind keybinds here.
--
-- =============================================================================
-- KEYBIND RULES & SYNTAX
-- =============================================================================
-- • bind("MODS", "KEY", action, [options])
-- • unbind("MODS", "KEY")
--
-- Supported modifiers:
--   "SUPER", "SHIFT", "CTRL", "ALT", or combinations like "SUPER SHIFT", "SUPER ALT"
--
-- Actions:
--   • exec_cmd("command")       -> launches a terminal command or script
--   • dispatch("dispatcher", [arg]) -> triggers a Hyprland dispatcher (e.g. killactive, togglefloating)
--
-- =============================================================================
-- EXAMPLES
-- =============================================================================
--
-- NOTE ON LUA REBINDS:
--   Yes — same rule as Hyprlang applies in practice: if a key combo is already bound,
--   unbind("MODS", "KEY") first, then bind(...) it to the new action.
--   This keeps behavior explicit and avoids duplicate/conflicting binds.
--
-- 1. ADDING A BRAND NEW KEYBIND (combo not used by default):
--    bind("SUPER", "Z", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--    bind("SUPER SHIFT", "V", exec_cmd("pavucontrol"), { description = "Audio Control" })
--    bind("SUPER", "X", dispatch("killactive"), { description = "Close active window" })
--
-- 2. OVERRIDING AN EXISTING COMBO WITH A DIFFERENT APP/COMMAND:
--    -- To replace what SUPER+Return opens (default: kitty):
--    unbind("SUPER", "Return")
--    bind("SUPER", "Return", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--
-- 3. REBINDING / MOVING AN ACTION TO A NEW KEY COMBINATION:
--    -- Example: Move File Manager from SUPER+E to SUPER+F, and use SUPER+E for Emacs:
--    unbind("SUPER", "E")       -- unbind default file manager from SUPER+E
--    unbind("SUPER", "F")       -- unbind whatever SUPER+F was doing (default: fake fullscreen)
--    bind("SUPER", "F", exec_cmd("$HOME/.config/hypr/scripts/LaunchFileManager.sh '$files' '$term'"), { description = "File manager" })
--    bind("SUPER", "E", exec_cmd("emacsclient -c -a 'emacs'"), { description = "Launch Emacs" })
--
-- 4. REBINDING COMPOSITOR DISPATCHERS (e.g. workspace, fullscreen, floating):
--    unbind("SUPER", "Q")
--    bind("SUPER", "Q", dispatch("killactive"), { description = "Close active window" })
--    unbind("SUPER", "F") -- default fakefullscreen
--    bind("SUPER SHIFT", "F", dispatch("fullscreen", "0"), { description = "Toggle fullscreen" })
--    bind("SUPER ALT", "W", dispatch("workspace", "special:scratchpad"), { description = "Toggle scratchpad" })
--
-- 5. BIND OPTIONS (locked, repeating):
--    -- locked = true     -> runs even when lockscreen is active (e.g. media keys)
--    -- repeating = true  -> repeats when key is held down (e.g. volume / brightness)
--    bind("CTRL ALT", "bracketright", exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"), { description = "Brightness up", repeating = true })
--    bind("", "XF86AudioMute", exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"), { description = "Mute audio", locked = true })
--
-- =============================================================================
local user_keybinds_helper = nil
local submap_helper = nil
do
  local source = (debug.getinfo(1, "S") or {}).source or ""
  local source_path = source:match("^@(.+)$")
  local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
  local home = os.getenv("HOME") or ""

  -- Load a helper module from the first candidate path that defines what we
  -- expect. Each helper is loaded exactly once, so a local copy always wins
  -- over the shipped template and no module is executed twice.
  local function load_helper(file_name, validate)
    local candidate_paths = {
      source_dir and (source_dir .. "/../lua/" .. file_name) or nil,
      home ~= "" and (home .. "/.config/hypr/lua/" .. file_name) or nil,
      home ~= "" and (home .. "/.config/hypr/" .. file_name) or nil,
    }

    local tried_paths = {}
    for _, helper_path in ipairs(candidate_paths) do
      if helper_path then
        table.insert(tried_paths, helper_path)
        local f = io.open(helper_path, "r")
        if f then
          f:close()
          local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
          if loaded_ok and type(loaded_helpers) == "table" and validate(loaded_helpers) then
            return loaded_helpers
          end
        end
      end
    end

    return nil, tried_paths
  end

  local tried_paths
  user_keybinds_helper, tried_paths = load_helper("user_keybinds_helper.lua", function(helpers)
    return helpers.bind ~= nil
  end)
  if not user_keybinds_helper then
    error("Failed to load user_keybinds_helper.lua from: " .. table.concat(tried_paths or {}, ", "))
  end

  -- submap_helper is optional: a missing or broken file must not take down all
  -- user keybinds, so it degrades to a warning and the keybinds below still load.
  submap_helper = load_helper("submap_helper.lua", function(helpers)
    return helpers.submap ~= nil
  end)
end

local exec_cmd = user_keybinds_helper.exec_cmd
local dispatch = user_keybinds_helper.dispatch
local bind = user_keybinds_helper.bind
local unbind = user_keybinds_helper.unbind
local submap = submap_helper and submap_helper.submap or nil
if not submap then
  print("[WARN] submap_helper.lua was not found; the submap.* helpers are unavailable. "
    .. "Copy config/hypr/lua/submap_helper.lua to ~/.config/hypr/lua/ to enable them.")
end


-- ===== Local (godlyfast fork) =====
local scripts = "$HOME/.config/hypr/scripts"

-- Stock binds SUPER+Tab / SUPER+SHIFT+Tab to group cycling AND next/previous
-- workspace, so one press did both. Keep group cycling; workspaces stay on
-- SUPER+period/comma and SUPER+scroll.
unbind("SUPER", "Tab")
unbind("SUPER SHIFT", "Tab")
-- Not dispatch("changegroupactive"): this helper has no case for it and falls back
-- to hl.dsp.exec_raw, which runs it as a shell command. Same call as stock.
bind("SUPER", "Tab", function() hl.dispatch(hl.dsp.group.next()) end, { description = "Change Group Forward" })
bind("SUPER SHIFT", "Tab", function() hl.dispatch(hl.dsp.group.prev()) end, { description = "Change Group Back" })

-- Stock binds these through its dispatch() helper, which has no case for them and
-- falls back to hl.dsp.exec_raw, i.e. a shell command that does not exist. Native
-- dispatchers (Hyprland 0.56.2 LuaBindingsDispatchers.cpp), as the .conf binds were.
local function run(...)
  local dispatchers = { ... }
  return function()
    for _, d in ipairs(dispatchers) do hl.dispatch(d) end
  end
end
-- ALT+Tab: cycle, then raise the newly focused window (.conf: cyclenext + bringactivetotop)
unbind("ALT", "Tab")
bind("ALT", "Tab", run(hl.dsp.window.cycle_next(), hl.dsp.window.bring_to_top()), { description = "cycle next window, bring to top" })
unbind("SUPER CTRL", "J")
unbind("SUPER CTRL", "L")
unbind("SUPER CTRL", "H")
bind("SUPER CTRL", "J", run(hl.dsp.window.move({ into_group = "l" })), { description = "Move left into group" })
bind("SUPER CTRL", "L", run(hl.dsp.window.move({ into_group = "r" })), { description = "Move Right into group" })
bind("SUPER CTRL", "H", run(hl.dsp.window.move({ out_of_group = true })), { description = "Move active out of group" })
for key, dir in pairs({ F9 = "l", F10 = "r", F11 = "u", F12 = "d" }) do
  unbind("SUPER CTRL", key)
  bind("SUPER CTRL", key, run(hl.dsp.workspace.move({ monitor = dir })), { description = "move workspace to monitor " .. dir })
end

-- Apps
bind("SUPER SHIFT", "T", exec_cmd("thunderbird"), { description = "email (Thunderbird)" })
bind("SUPER SHIFT", "C", exec_cmd("google-chrome-stable"), { description = "Chrome browser" })
unbind("SUPER SHIFT", "B") -- stock: static Rainbow Border
bind("SUPER SHIFT", "B", exec_cmd("brave"), { description = "Brave browser" })
bind("SUPER ALT", "D", exec_cmd("$HOME/.config/hypr/UserScripts/RofiBrowserSelect.sh"), { description = "default browser picker" })

-- Machine tools
bind("SUPER CTRL SHIFT", "B", exec_cmd(scripts .. "/SidebarToggle.sh"), { description = "toggle Booru sidebar" })
bind("SUPER ALT", "I", exec_cmd(scripts .. "/StatusCheck.sh"), { description = "show GPU/power status" })
-- Not SUPER+ALT+S: stock binds that to the scrolling V/H toggle.
bind("SUPER ALT", "K", exec_cmd(scripts .. "/SchedulerSwitch.sh"), { description = "cycle scheduler modes" })
bind("SUPER ALT", "M", exec_cmd("hyprwave-toggle visibility"), { description = "toggle HyprWave visibility" })
bind("SUPER CTRL", "M", exec_cmd("hyprwave-toggle expand"), { description = "toggle HyprWave expand" })
bind("SUPER ALT", "W", exec_cmd(scripts .. "/WallpaperChange.sh"), { description = "change wallpaper" })
-- Stock CTRL+ALT+W points at UserScripts/WallpaperRandom.sh; the script lives in scripts/.
unbind("CTRL ALT", "W")
bind("CTRL ALT", "W", exec_cmd(scripts .. "/WallpaperRandom.sh"), { description = "random wallpaper" })

-- ASUS ROG Fn keys
unbind("", "xf86Launch4")
bind("", "xf86Launch4", exec_cmd(scripts .. "/ProfileSwitch.sh"), { description = "FN+F5 profile cycling (SmartQuiet)" })
unbind("", "xf86Launch3")
bind("", "xf86Launch3", exec_cmd("asusctl aura effect --next-mode"), { description = "FN+F4 keyboard RGB mode" })
