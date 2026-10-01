-- Static keybind map for the KooL Lua config: stubs `hl`, loads the bind files in
-- user_overrides.lua order, applies unbinds, and reports
--   DUP      two binds on one chord (modifier order ignored, like Hyprland's matching)
--   MISSING  an exec bind whose command is neither on PATH nor an existing script; function
--            binds are probed by calling them against a recording hl.dispatch, which catches
--            dispatch() helpers that fall back to hl.dsp.exec_raw (a shell command)
--   BADOPT   a bind option hl.bind ignores (["repeat"]; the field is `repeating`)
-- Exit status 1 on any DUP, MISSING or BADOPT.
-- Run it through tools/verify-lua.sh only: loading the config writes runtime files
-- (e.g. $XDG_RUNTIME_DIR/touchpad.status) and reads ~/.config, so it needs the sandbox HOME.
-- usage (sandboxed): lua tools/bindmap.lua <hyprDir> [chord ...]
if os.getenv("VERIFY_LUA_SANDBOX") ~= "1" then
  io.stderr:write("bindmap.lua: run via tools/verify-lua.sh (needs its throwaway HOME)\n")
  os.exit(2)
end
local dir = arg[1]
local binds, src, bad = {}, "", 0

-- chord key for duplicate detection: modifiers sorted, key lowercased
local function norm(s)
  local parts = {}
  for t in s:gsub("%+", " "):gmatch("%S+") do parts[#parts + 1] = t end
  local k = table.remove(parts):lower()
  for i, m in ipairs(parts) do parts[i] = m:upper() end
  table.sort(parts)
  return table.concat(parts, " ") .. " : " .. k
end
-- Hyprland's removeKeybind compares the display string with spaces removed, lowercased
local function raw(s) return (s:gsub("%s", ""):lower()) end

-- hl.dsp.* records what a bind would do: { dsp = "dsp.exec_cmd", arg = "..." }
local function recorder(path)
  return setmetatable({}, {
    __index = function(_, k) if type(k) == "string" then return recorder(path .. "." .. k) end end,
    __call = function(_, a) return { dsp = path, arg = a } end,
  })
end
-- Other hl.* fields: string keys chain, numeric keys end ipairs loops, calls return nil
-- (so `hl.get_monitors() or {}` yields {} instead of looping forever).
local any
any = setmetatable({}, { __index = function(_, k) if type(k) == "string" then return any end end,
                         __call = function() return nil end })

local function show(v)
  if type(v) ~= "table" then return tostring(v) end
  local keys, parts = {}, {}
  for k in pairs(v) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. tostring(v[k]) end
  return "{" .. table.concat(parts, ", ") .. "}"
end
local function describe(fn)
  if type(fn) == "table" and fn.dsp then return fn.dsp .. "(" .. show(fn.arg) .. ")" end
  return type(fn)
end

hl = setmetatable({
  dsp = recorder("dsp"),
  bind = function(ch, fn, opts)
    if type(opts) == "table" and opts["repeat"] ~= nil then
      bad = bad + 1
      print(("BADOPT   %-26s %s: [\"repeat\"] is ignored by hl.bind, use repeating"):format(norm(ch), src))
    end
    binds[#binds + 1] = { k = norm(ch), raw = raw(ch), fn = fn, src = src,
                          d = type(opts) == "table" and opts.description or "?" }
  end,
  -- Real hl.unbind reads only its first argument (the user helper also passes (mods, key))
  unbind = function(chord)
    local r = raw(chord)
    for i = #binds, 1, -1 do if binds[i].raw == r then table.remove(binds, i) end end
  end,
}, { __index = function() return any end })

for _, f in ipairs({ "configs/system_keybinds.lua", "configs/system_laptops.lua",
                     "UserConfigs/user_keybinds.lua", "UserConfigs/user_laptops.lua" }) do
  src = f:match("([^/]+)%.lua$")
  local ok, err = pcall(dofile, dir .. "/" .. f)
  if not ok then print("LOAD ERROR " .. f .. ": " .. tostring(err)) end
end

-- exec target check: first word of the command, $HOME expanded, must be a script or on PATH
local home = os.getenv("HOME") or ""
local missing = 0
local function target_exists(cmd)
  local first
  for w in cmd:gmatch("%S+") do
    if not w:match("^[%a_][%w_]*=") then first = w; break end -- skip VAR=value prefixes
  end
  if not first then return true end
  first = first:gsub("^[\"']", ""):gsub("[\"']$", "")
  first = first:gsub("%$HOME", home):gsub("^~", home):gsub("^%$%{HOME%}", home)
  if first:find("/", 1, true) then
    return os.execute("test -x '" .. first .. "'") == true
  end
  return os.execute("command -v '" .. first .. "' >/dev/null 2>&1") == true
end

-- What a bind runs: its dispatcher descriptor, or for a Lua function every descriptor it
-- passes to hl.dispatch / every command it hands to hl.exec_cmd when called.
local function actions(fn)
  if type(fn) == "table" and fn.dsp then return { fn } end
  if type(fn) ~= "function" then return {} end
  local got = {}
  local saved_d, saved_e = rawget(hl, "dispatch"), rawget(hl, "exec_cmd")
  local saved_x, saved_p = os.execute, io.popen
  rawset(hl, "dispatch", function(d) if type(d) == "table" and d.dsp then got[#got + 1] = d end end)
  rawset(hl, "exec_cmd", function(c) got[#got + 1] = { dsp = "dsp.exec_cmd", arg = c } end)
  -- a probed bind must never run real commands
  os.execute = function(c) got[#got + 1] = { dsp = "dsp.exec_cmd", arg = c }; return true end
  io.popen = function() return nil end
  pcall(fn)
  os.execute, io.popen = saved_x, saved_p
  rawset(hl, "dispatch", saved_d); rawset(hl, "exec_cmd", saved_e)
  return got
end

local by, dups = {}, 0
for _, b in ipairs(binds) do
  by[b.k] = by[b.k] or {}; table.insert(by[b.k], b)
  for _, a in ipairs(actions(b.fn)) do
    if (a.dsp == "dsp.exec_cmd" or a.dsp == "dsp.exec_raw") and type(a.arg) == "string"
       and not target_exists(a.arg) then
      missing = missing + 1
      print(("MISSING  %-26s %s: %s"):format(b.k, b.src, describe(a)))
    end
  end
end
print(("binds: %d"):format(#binds))
for k, list in pairs(by) do
  if #list > 1 then
    dups = dups + 1
    local d = {}
    for _, b in ipairs(list) do d[#d + 1] = b.src .. ": " .. b.d end
    print("DUP      " .. k .. "  =>  " .. table.concat(d, " | "))
  end
end
for i = 2, #arg do
  local k = norm(arg[i])
  local d = {}
  for _, b in ipairs(by[k] or {}) do
    local acts = {}
    for _, x in ipairs(actions(b.fn)) do acts[#acts + 1] = describe(x) end
    d[#d + 1] = b.src .. ": " .. b.d .. " -> " .. (#acts > 0 and table.concat(acts, ", ") or describe(b.fn))
  end
  print(("Q        %-26s => %s"):format(k, #d > 0 and table.concat(d, " | ") or "(unbound)"))
end
os.exit((missing == 0 and bad == 0 and dups == 0) and 0 or 1)
