-- Fine Aim -- right-mouse aiming for Saints Reborn.
-- Settings: mod.ini. Camera presets: presets.ini / my_presets.ini. See README.txt.

-- ---------------------------------------------------------------------------
-- Game addresses
-- ---------------------------------------------------------------------------
local A = {
  PLAYER        = 0x8309ABEC,
  OBJECTS       = 0x830866C8,
  CAMERA        = 0x827D9778,
  CAMERA_MODE   = 0x827DA15C,
  CLOCK         = 0x827AA6E0,
  FRAME_HOOK    = 0x82167690,   -- per-frame player update
  CAMERA_UPDATE = 0x82109608,
  RAISE_FN      = 0x82449708,   -- weapon raise setter (player, on, hold_ms)
  MOVE_FN       = 0x8245FC08,   -- movement (character in r3)
  POSE_FN       = 0x82443DD8,   -- carry pose (character in r3)
  SPREAD_FN     = 0x824703A8,   -- weapon cone (out min r3, out max r4, character r7)
  LOCO_FN       = 0x82468398,   -- locomotion / strafe (character in r3)
  CROUCH_FN     = 0x82461F58,   -- the game's own "crouch now" (character in r3)
  FP_FLAG       = 0x8370D01E,   -- camera_first_mode player flag
  FP_CONSOLE    = 0x8370CFEF,   -- camera_first_mode console on/off
  CROUCH_OFFSET = 0x827D937C,   -- camera_free.xtbl crouch_y_offset
  WEAPON_TABLE  = 0x832ABCA8,
  WEAPON_COUNT  = 0x832ABCAC,
  MENU_WORDS    = { 0x839E0DF8, 0x839E0FB0, 0x82FFE434, 0x82FFE43C },
  DRAW_BITMAP   = 0x8227E720,   -- HUD bitmap draw (handle, x, y, rotation, scale)
  HUD_BITMAPS   = 0x827AF1C8,   -- HUD bitmap table, 8 bytes per entry (name, handle)
}
A.CAM_POS   = A.CAMERA + 44
A.CAM_RIGHT = A.CAMERA + 80
A.CAM_UP    = A.CAMERA + 92
A.CAM_FWD   = A.CAMERA + 104
A.CAM_FOV   = A.CAMERA + 188

local P_FLAGS, P_MOVE, P_EQUIP, P_EXPIRY, P_SEAT, P_STATE = 0xD8, 0x200, 3548, 0x7C8, 2496, 508
local CROUCH_BIT = 0x20000000
local RETICLE_FIRST, RETICLE_LAST = 9, 19   -- reticule_a_0 .. reticule_e_1, reticule_friendly
local SLOT_STRIDE, SLOT_MIN, SLOT_MAX, SLOT_ID = 520, 0xA8, 0xAC, 0x20
local VEHICLE  = { [7] = true, [21] = true }
local GAMEPLAY = { [6] = true, [7] = true, [15] = true, [16] = true, [17] = true, [18] = true, [21] = true }
local RMB, LMB = 2, 1

-- Weapons whose right click is not "aim": scopes, throwables, melee.
local NO_AIM = {
  sniper_rifle = true, grenade = true, bombsml = true, molotov = true, pipe_bomb = true,
  knife = true, knifel = true, baseball_bat = true, nightstick = true, tire_iron = true,
  kabob = true, ["40oz"] = true,
}

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------
local function on(v) return v == 1 or v == true end
local function setting(name, default) local v = wml.setting(name, default) if v == nil then return default end return v end

local S = {
  aim_key        = setting("aim_key", 2),
  remap_melee    = on(setting("remap_melee", 1)),
  melee_key      = setting("melee_key", "X"),
  aim_speed      = setting("aim_speed", 8.0),
  aim_return     = setting("aim_return", 0.0),
  pause_frames   = setting("pause_frames", 3),
  raise_hold_ms  = setting("raise_hold_ms", 500),
  start_preset   = tostring(setting("preset", "SR1")),

  fp_moves       = on(setting("first_person_moves", 1)),
  slow_walk      = setting("slow_walk", 1),
  walk_key       = setting("walk_toggle_key", 20),
  walk_on        = on(setting("walk_start", 0)),
  aim_walk_speed = setting("aim_walk_speed", 1.8),
  hip_face_ms    = setting("hip_face_ms", 600),
  crouch_scale   = setting("crouch_scale", 1.25),
  crouch_moving  = on(setting("crouch_while_moving", 1)),
  crouch_key     = setting("crouch_key", "C"),
  raise_after_sprint = on(setting("raise_after_sprint", 1)),
  raise_wait     = setting("raise_wait_frames", 20),

  cone_model     = on(setting("cone_model", 1)),
  moving_speed   = setting("moving_speed", 0.6),
  cone = {
    stand_hip           = setting("cone_stand_hip", 1.00),
    stand_ads           = setting("cone_stand_ads", 0.40),
    crouch_hip          = setting("cone_crouch_hip", 0.80),
    crouch_ads          = setting("cone_crouch_ads", 0.30),
    move_hip            = setting("cone_move_hip", 1.60),
    move_ads            = setting("cone_move_ads", 0.70),
    crouch_move_hip     = setting("cone_crouch_move_hip", 1.30),
    crouch_move_ads     = setting("cone_crouch_move_ads", 0.55),
    slowwalk_hip        = setting("cone_slowwalk_hip", 1.25),
    slowwalk_ads        = setting("cone_slowwalk_ads", 0.55),
    crouch_slowwalk_hip = setting("cone_crouch_slowwalk_hip", 1.05),
    crouch_slowwalk_ads = setting("cone_crouch_slowwalk_ads", 0.45),
    sprint              = setting("cone_sprint", 2.00),
    vehicle_hip         = setting("cone_vehicle_hip", 2.00),
    vehicle_ads         = setting("cone_vehicle_ads", 1.00),
  },
  vehicle_fov    = setting("vehicle_fov", 0.85),

  reticle_cone   = on(setting("reticle_follows_cone", 1)),
  reticle_grow   = setting("reticle_grow", 0.4),
  reticle_shrink = setting("reticle_shrink", 1.0),
  reticle_aim    = setting("aim_reticle_scale", 0.6),

  tune_keys      = on(setting("tune_keys", 1)),
  tune_step      = setting("tune_step", 0.25),
}

-- Camera constants: SR1 orbit (camera_first_mode, sub_8210FEE0) and zoom style.
local ORBIT_DIST, ORBIT_UP, PITCH_MAX, HALF_PI = 1.85, 0.15, 0.9414778, math.pi / 2
local PIVOT_H, AIM_LIFT, HEIGHT_RATE = 1.4, 0.1, 0.8
local LIM = { zoom = { -3.5, 0.0 }, fov = { 0.5, 1.0 }, height = { 0.8, 2.6 }, shoulder = { -1.5, 1.5 } }
local SLOWWALK = { move_ads = "slowwalk_ads", crouch_move_ads = "crouch_slowwalk_ads",
                   move_hip = "slowwalk_hip", crouch_move_hip = "crouch_slowwalk_hip" }

local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
local function read_vec(a) return wml.read_f32(a), wml.read_f32(a + 4), wml.read_f32(a + 8) end
local function write_vec(a, x, y, z) wml.write_f32(a, x) wml.write_f32(a + 4, y) wml.write_f32(a + 8, z) end
local function key_ok(k)
  if type(k) == "number" then return k > 0 and k < 256 end
  return k ~= nil and k ~= "" and pcall(wml.key_down, k)
end
local function down(k) return k ~= nil and wml.key_down(k) == true end

if not key_ok(S.aim_key) then wml.log("aim_key is not a usable key; aiming is off") S.aim_key = nil end
if S.remap_melee and not key_ok(S.melee_key) then
  wml.log("melee_key is not a usable key; melee stays on right mouse") S.remap_melee = false
end
if S.walk_key == 0 or S.walk_key == "" or not key_ok(S.walk_key) then S.walk_key = nil end
if S.crouch_moving and not key_ok(S.crouch_key) then S.crouch_moving = false end

-- ---------------------------------------------------------------------------
-- Runtime state
-- ---------------------------------------------------------------------------
local st = {
  player = 0, frames = 0, blend = 0.0, aiming = false, equipped = nil, seated = false,
  aim_latch = false, armed = false, veh_held = false, veh_aim = false, vblend = 0.0,
  last_gun = nil, last_frame_clock = 0,
  pause_open = false, clock_last = 0, frozen = 0,
  fp_ours = false, win = false, win_saved = 0, win_ours = 0,
  sprint_wins = false, prev_shift = false, prev_rmb = false, shift_taken = false,
  rmb_hold = false, walk_prev = false,
  move_state = 0, sprint_wait = 0, hold_raise = false,
  crouched = false, crouch_now = 0.0,
  crouch_prev = false, crouch_key_prev = false, crouch_at = 0, crouch_until = 0,
  speed = 0.0, last_x = nil, last_z = nil, last_clock = nil,
  ws_x = nil, ws_z = nil,
  hip_until = 0, hip_fire = false,
  cam_saved = false, saved_pos = { 0, 0, 0 }, written_pos = { 0, 0, 0 },
  fov_base = 60.0, fov_written = false,
  in_veh = false, ret_now = 1.0, ret_tick = 0, ret_handles = {}, ret_set = {},
}

-- ---------------------------------------------------------------------------
-- Weapons
-- ---------------------------------------------------------------------------
local W = { built = false, tries = 0, by_id = {}, by_name = {}, obj = nil, name = nil }

local function read_name(addr)
  if type(addr) ~= "number" or addr < 0x80000000 or addr >= 0xC0000000 then return nil end
  local out = {}
  for w = 0, 12 do
    local v = wml.read_u32(addr + w * 4)
    if type(v) ~= "number" then return nil end
    for b = 3, 0, -1 do
      local c = (v >> (b * 8)) & 0xFF
      if c == 0 then return table.concat(out) end
      if c < 32 or c > 126 then return nil end
      out[#out + 1] = string.char(c)
    end
  end
  return nil
end

local function build_weapons()
  if W.built then return true end
  if st.frames < W.tries then return false end
  W.tries = st.frames + 60
  local base, cnt = wml.read_u32(A.WEAPON_TABLE), wml.read_u32(A.WEAPON_COUNT)
  if type(base) ~= "number" or base == 0 or type(cnt) ~= "number" or cnt <= 0 or cnt > 4096 then
    return false
  end
  for i = 0, cnt - 1 do
    local slot = base + i * SLOT_STRIDE
    local nm = read_name(wml.read_u32(slot))
    if nm and nm ~= "" then
      local mn, mx = wml.read_f32(slot + SLOT_MIN), wml.read_f32(slot + SLOT_MAX)
      local e = { name = nm, min = mn, max = mx, cone = mx > 0 and mx <= 1.0 and mn >= 0 and mn <= mx }
      W.by_name[nm] = e
      local id = wml.read_u32(slot + SLOT_ID)
      if id and id ~= 0 then W.by_id[id] = e end
    end
  end
  W.built = next(W.by_name) ~= nil
  return W.built
end

-- Equipped weapon name, cached per weapon record.
local function resolve_equipped()
  local p = st.player
  if p == 0 then return nil end
  local w = wml.read_u32(p + P_EQUIP)
  if type(w) ~= "number" or w == 0 then W.obj, W.name = nil, nil return nil end
  local direct = wml.read_u32(w + 8)
  local alt = wml.read_u32(w + 16)
  if type(alt) == "number" and alt ~= 0 then alt = wml.read_u32(alt + 8) end
  if W.built and w == W.obj and direct == W.direct and alt == W.alt then return W.name end
  if not build_weapons() then return nil end
  local e = W.by_id[alt] or W.by_id[direct]
  W.obj, W.direct, W.alt, W.name = w, direct, alt, e and e.name or nil
  return W.name
end

local function aims_with(name) return type(name) == "string" and name ~= "" and not NO_AIM[name] end

-- ---------------------------------------------------------------------------
-- Presets
-- ---------------------------------------------------------------------------
local FOLDER = wml.mod_folder
local FILES = { presets = FOLDER .. "/presets.ini", mine = FOLDER .. "/my_presets.ini",
                state = FOLDER .. "/camera.cfg", overlay = FOLDER .. "/overlay.txt" }
local PR = { list = {}, order = {}, mine = {}, name = nil, style = "zoom",
             zoom = 0, fov = 1, height = 1.7, shoulder = 0.6, note = "" }

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local t = f:read("a")
  f:close()
  return t
end

local function write_file(path, text)
  local f = io.open(path, "w")
  if not f then wml.log("could not write " .. path) return false end
  f:write(text)
  f:close()
  return true
end

local function add_preset(name, p, mine)
  if not (p.zoom and p.fov and p.height and p.shoulder) then
    wml.log("preset [" .. name .. "] is missing a value and was skipped")
    return
  end
  p.name = name
  p.style = p.style or "zoom"
  p.zoom = clamp(p.zoom, LIM.zoom[1], LIM.zoom[2])
  p.fov = clamp(p.fov, LIM.fov[1], LIM.fov[2])
  p.height = clamp(p.height, LIM.height[1], LIM.height[2])
  p.shoulder = clamp(p.shoulder, LIM.shoulder[1], LIM.shoulder[2])
  if not PR.list[name] then PR.order[#PR.order + 1] = name end
  PR.list[name] = p
  if mine then PR.mine[name] = true end
end

local function parse_presets(text, mine)
  if not text then return end
  local name, cur = nil, nil
  local function flush() if name and cur then add_preset(name, cur, mine) end end
  for raw in text:gmatch("[^\r\n]+") do
    local line = (raw:gsub("%s*[;#].*$", ""))
    local hdr = line:match("^%s*%[(.-)%]%s*$")
    if hdr then
      flush()
      name = hdr:match("^%s*(.-)%s*$")
      cur = (name ~= "") and {} or nil
    elseif cur then
      local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
      if k == "style" then
        cur.style = (v:lower() == "orbit") and "orbit" or "zoom"
      elseif k and (k == "zoom" or k == "fov" or k == "height" or k == "shoulder") then
        cur[k] = tonumber(v)
      end
    end
  end
  flush()
end

local function apply_preset(name)
  local p = PR.list[name]
  if not p then return false end
  PR.name, PR.style = name, p.style
  PR.zoom, PR.fov, PR.height, PR.shoulder = p.zoom, p.fov, p.height, p.shoulder
  return true
end

local function remove_preset(name)
  PR.list[name], PR.mine[name] = nil, nil
  for i, n in ipairs(PR.order) do if n == name then table.remove(PR.order, i) break end end
end

local function preset_block(p)
  return string.format("[%s]\nstyle = %s\nzoom = %.2f\nfov = %.2f\nheight = %.2f\nshoulder = %.2f\n\n",
                       p.name, p.style, p.zoom, p.fov, p.height, p.shoulder)
end

local function save_mine()
  local t = { "; Presets saved in game. Share one by copying its [block] into someone's presets.ini.\n\n" }
  for _, n in ipairs(PR.order) do
    if PR.mine[n] then t[#t + 1] = preset_block(PR.list[n]) end
  end
  write_file(FILES.mine, table.concat(t))
end

parse_presets(read_file(FILES.presets), false)
parse_presets(read_file(FILES.mine), true)
if #PR.order == 0 then
  add_preset("SR1", { style = "orbit", zoom = 0.0, fov = 0.60, height = 1.69, shoulder = 0.35 }, false)
end
if not apply_preset(S.start_preset) then apply_preset(PR.order[1]) end

-- camera.cfg: the live camera, shared with the Whompays Trainer's Camera page.
local CFG = { last = nil, poll_at = 0, dirty = false }

local function cfg_text()
  local t = { string.format("preset = %s\nzoom = %.2f\nfov = %.2f\nheight = %.2f\nshoulder = %.2f\n" ..
                            "slow_walk = %d\n",
                            PR.name, PR.zoom, PR.fov, PR.height, PR.shoulder,
                            on(S.slow_walk) and 1 or 0) }
  for _, n in ipairs(PR.order) do
    local p = PR.list[n]
    if PR.mine[n] and n:match("^custom%d+$") then
      t[#t + 1] = string.format("%s = %.2f %.2f %.2f %.2f\n", n, p.zoom, p.fov, p.height, p.shoulder)
    end
  end
  return table.concat(t)
end

local function apply_cfg(text)
  local vals, chosen = {}, nil
  for line in text:gmatch("[^\r\n]+") do
    local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if k == "preset" then chosen = v
    elseif k and k:match("^custom%d+$") then
      local z, f, h, s = v:match("^(-?[%d.]+)%s+([%d.]+)%s+([%d.]+)%s+(-?[%d.]+)$")
      local old = PR.list[k]
      if z and (not old or PR.mine[k]) then
        add_preset(k, { style = old and old.style, zoom = tonumber(z), fov = tonumber(f),
                        height = tonumber(h), shoulder = tonumber(s) }, true)
        CFG.mine_changed = true
      end
    elseif k then
      vals[k] = tonumber(v)
    end
  end
  if CFG.mine_changed then CFG.mine_changed = false save_mine() end
  if chosen and chosen ~= "" then apply_preset(chosen) end
  if vals.zoom then PR.zoom = clamp(vals.zoom, LIM.zoom[1], LIM.zoom[2]) end
  if vals.fov then PR.fov = clamp(vals.fov, LIM.fov[1], LIM.fov[2]) end
  if vals.height then PR.height = clamp(vals.height, LIM.height[1], LIM.height[2]) end
  if vals.shoulder then PR.shoulder = clamp(vals.shoulder, LIM.shoulder[1], LIM.shoulder[2]) end
  if vals.slow_walk then S.slow_walk = vals.slow_walk end
  CFG.last = text
end

local function save_cfg()
  local text = cfg_text()
  if write_file(FILES.state, text) then CFG.last = text end
  CFG.dirty = false
end

do
  local text = read_file(FILES.state)
  if text and text ~= "" then apply_cfg(text) end
end
wml.log(string.format("Fine Aim: %d presets, using %s", #PR.order, tostring(PR.name)))

-- ---------------------------------------------------------------------------
-- Live tuning keys
-- ---------------------------------------------------------------------------
local MODS = { CTRL = "CTRL", CONTROL = "CTRL", ALT = "ALT", SHIFT = "SHIFT" }

local function bind(name, default)
  local raw = setting(name, default)
  if raw == nil or raw == "" then return nil end
  local mod, key = nil, raw
  if type(raw) == "string" then
    local m, rest = raw:match("^%s*(%a+)%s*%+%s*(.-)%s*$")
    if m and MODS[m:upper()] then mod, key = MODS[m:upper()], rest end
    key = tonumber(key) or key
  end
  if not key_ok(key) then wml.log(name .. " is not a usable key; that action is off") return nil end
  pcall(wml.take_key, key)
  return { key = key, mod = mod }
end

local function held(b) return b ~= nil and (b.mod == nil or down(b.mod)) and down(b.key) end

local TUNE = { repeat_at = 0, hold = 0, fired = false, map = {} }
if S.tune_keys then
  local step = S.tune_step
  local function adj(field, d)
    return function()
      PR[field] = clamp(PR[field] + d, LIM[field][1], LIM[field][2])
      CFG.dirty = true
    end
  end
  for _, b in ipairs({
      { "key_zoom_in", "MINUS", adj("zoom", -step) },     { "key_zoom_out", "PLUS", adj("zoom", step) },
      { "key_fov_wide", "PAGEUP", adj("fov", step) },     { "key_fov_narrow", "PAGEDOWN", adj("fov", -step) },
      { "key_height_down", "HOME", adj("height", -0.1) }, { "key_height_up", "END", adj("height", 0.1) },
      { "key_shoulder_left", "CTRL+I", adj("shoulder", -0.1) },
      { "key_shoulder_right", "CTRL+O", adj("shoulder", 0.1) } }) do
    local k = bind(b[1], b[2])
    if k then TUNE.map[#TUNE.map + 1] = { k, b[3] } end
  end
  TUNE.reset = bind("key_preset_reset", "CTRL+J")
  TUNE.prev  = bind("key_preset_prev", "CTRL+K")
  TUNE.next  = bind("key_preset_next", "CTRL+Y")
  TUNE.save  = bind("key_preset_save", "CTRL+U")
  TUNE.clear = bind("key_preset_clear", "CTRL+G")
end

local function step_preset(d)
  local i = 1
  for k, n in ipairs(PR.order) do if n == PR.name then i = k break end end
  apply_preset(PR.order[((i - 1 + d) % #PR.order) + 1])
end

local function save_custom()
  local slot = tonumber((PR.name or ""):match("^custom(%d+)$"))
  if not (slot and PR.mine[PR.name]) then
    slot = nil
    for i = 1, 8 do if not PR.list["custom" .. i] then slot = i break end end
  end
  if not slot then PR.note = "all 8 custom slots are full" return end
  local name = "custom" .. slot
  remove_preset(name)
  add_preset(name, { style = PR.style, zoom = PR.zoom, fov = PR.fov, height = PR.height,
                     shoulder = PR.shoulder }, true)
  PR.name = name
  save_mine()
  PR.note = "saved as " .. name
end

local function clear_custom()
  local target = PR.mine[PR.name] and PR.name or nil
  if not target then
    for _, n in ipairs(PR.order) do if PR.mine[n] then target = n break end end
  end
  if not target then PR.note = "no saved presets to clear" return end
  remove_preset(target)
  save_mine()
  if PR.name == target then apply_preset(PR.order[1]) end
  PR.note = "cleared " .. target
end

local function tune_status()
  return string.format("Fine Aim [%s]  zoom %.2f  fov %.2f  height %.2f  shoulder %.2f%s",
                       tostring(PR.name), PR.zoom, PR.fov, PR.height, PR.shoulder,
                       PR.note ~= "" and ("  " .. PR.note) or "")
end

local function tune_frame()
  local any = false
  for _, e in ipairs(TUNE.map) do if held(e[1]) then any = true break end end
  local once = (held(TUNE.next) and 1) or (held(TUNE.prev) and -1) or (held(TUNE.reset) and 0)
               or (held(TUNE.save) and "save") or (held(TUNE.clear) and "clear")
  if not any and not once then TUNE.repeat_at, TUNE.fired = 0, false return end
  if once then
    if TUNE.fired then return end
    TUNE.fired = true
    if once == "save" then save_custom()
    elseif once == "clear" then clear_custom()
    elseif once == 0 then apply_preset(PR.name)
    else step_preset(once) end
    CFG.dirty, TUNE.hold = true, 180
    return
  end
  if st.frames < TUNE.repeat_at then return end
  TUNE.repeat_at = st.frames + 12
  for _, e in ipairs(TUNE.map) do if held(e[1]) then e[2]() end end
  TUNE.hold = 180
end

local OVERLAY = { last = nil }
local function show(text)
  if type(wml.overlay_text) == "function" then pcall(wml.overlay_text, text) return end
  if text == OVERLAY.last then return end
  OVERLAY.last = text
  write_file(FILES.overlay, text)
end

-- ---------------------------------------------------------------------------
-- State helpers
-- ---------------------------------------------------------------------------
local function in_vehicle() return VEHICLE[wml.read_u32(A.CAMERA_MODE)] == true end

local function seat_is_vehicle()
  local p = st.player
  if p == 0 then return false end
  local s = wml.read_u32(p + P_STATE) or 0
  if s == 9 or s == 12 then return false end
  local idx = (wml.read_u32(p + P_SEAT) or 0) & 0xFFFF
  if idx == 0 or idx >= 4096 then return false end
  local ob = wml.read_u32(A.OBJECTS + 12 + idx * 16) or 0
  return ob ~= 0 and (wml.read_u32(ob + 72) or 0) == 5
end

local function allowed()
  return wml.read_u32(A.CAMERA) == 0 and GAMEPLAY[wml.read_u32(A.CAMERA_MODE)] == true
end

local function menu_up()
  for _, a in ipairs(A.MENU_WORDS) do if (wml.read_u32(a) or 0) ~= 0 then return true end end
  return false
end

local function slow_now()
  if S.walk_key then return S.walk_on end
  return on(S.slow_walk)
end

local function aiming_now()
  if not S.aim_key or st.sprint_wins then return false end
  if not aims_with(st.equipped) or not allowed() or st.in_veh then return false end
  return down(S.aim_key)
end

local function raising_now()
  if not S.aim_key or not st.aim_latch or st.pause_open then return false end
  if st.equipped ~= nil and not aims_with(st.equipped) then return false end
  if st.seated then return true end
  return not st.sprint_wins and not st.hold_raise and allowed()
end

local function face_camera()
  local p = st.player
  if p == 0 then return end
  local fx, _, fz = read_vec(A.CAM_FWD)
  local flat = math.sqrt(fx * fx + fz * fz)
  if flat < 0.001 then return end
  fx, fz = fx / flat, fz / flat
  local r0x, r0y, r0z = read_vec(p + 32)
  local r1x, r1y, r1z = read_vec(p + 44)
  local r2x, r2y, r2z = read_vec(p + 56)
  if r1y < 0.9 then return end
  local cx, cy, cz = r1y * r2z - r1z * r2y, r1z * r2x - r1x * r2z, r1x * r2y - r1y * r2x
  local sign = (cx * r0x + cy * r0y + cz * r0z) >= 0 and 1 or -1
  write_vec(p + 32, sign * fz, 0, -sign * fx)
  write_vec(p + 44, 0, 1, 0)
  write_vec(p + 56, fx, 0, fz)
end

-- Vehicle raise: a raise expiry in the future plus the game's in-car raise bits.
-- The bits are OR-ed in, so reload and the rest of the flags word are left alone.
local VEH_RAISE_BITS = 0x88024120
local function vehicle_raise()
  local p = st.player
  if p == 0 then return end
  if st.veh_aim then
    wml.write_u32(p + P_EXPIRY, ((wml.read_u32(A.CLOCK) or 0) + 30000) & 0xFFFFFFFF)
    wml.write_u32(p + P_FLAGS, (wml.read_u32(p + P_FLAGS) or 0) | VEH_RAISE_BITS)
    st.veh_held = true
  elseif st.veh_held then
    wml.write_u32(p + P_EXPIRY, 0)
    st.veh_held = false
  end
end

-- ---------------------------------------------------------------------------
-- Aim cone
-- ---------------------------------------------------------------------------
local function cone_mult(ads)
  if st.seated then return ads and S.cone.vehicle_ads or S.cone.vehicle_hip end
  local s
  if st.move_state == 3 and not ads then s = "sprint"
  elseif st.speed > S.moving_speed then s = st.crouched and "crouch_move" or "move"
  else s = st.crouched and "crouch" or "stand" end
  if s ~= "sprint" then s = s .. (ads and "_ads" or "_hip") end
  if slow_now() and (S.walk_key or ads) then s = SLOWWALK[s] or s end
  return S.cone[s] or 1.0
end

-- ---------------------------------------------------------------------------
-- Per frame
-- ---------------------------------------------------------------------------
wml.on_frame(function()
  st.frames = st.frames + 1
  local p = wml.read_u32(A.PLAYER) or 0
  st.player = p
  local clock = wml.read_u32(A.CLOCK) or 0

  -- Paused or in a menu (frozen clock, or the game's own menu words).
  if clock ~= st.clock_last then st.clock_last, st.frozen = clock, 0 else st.frozen = st.frozen + 1 end
  st.pause_open = st.frozen >= S.pause_frames or menu_up()

  -- Seat, aim button latch.
  st.in_veh = in_vehicle()
  local was = st.seated
  st.seated = seat_is_vehicle()
  local rmb = down(S.aim_key)
  st.aim_latch = rmb

  -- Sprint against aim: whichever key went down last wins (on foot).
  local shift = down("SHIFT")
  if st.seated or st.in_veh then
    st.sprint_wins = false
  else
    if shift and not st.prev_shift and rmb then st.sprint_wins = true end
    if rmb and not st.prev_rmb then st.sprint_wins = false end
    if not shift then st.sprint_wins = false end
  end
  st.prev_shift, st.prev_rmb = shift, rmb

  -- Crouch, movement state, speed.
  local flags = p ~= 0 and (wml.read_u32(p + P_FLAGS) or 0) or 0
  st.crouched = (flags & CROUCH_BIT) ~= 0

  -- Crouch while moving. The game only starts a crouch when the left stick is
  -- centred (sub_8216A038: x*x + y*y must be under a threshold before it calls
  -- sub_82461F58), so pressing crouch on the move does nothing. On a press made
  -- while standing up, wait one frame for the game to act; if it did not crouch,
  -- FRAME_HOOK calls the game's own crouch function for it. A press made while
  -- crouched is the game's stand-up and is left alone.
  if S.crouch_moving then
    local cd = down(S.crouch_key)
    if cd and not st.crouch_key_prev and not st.crouched and not st.crouch_prev
       and not st.seated and not st.in_veh and not st.pause_open then
      st.crouch_at, st.crouch_until = st.frames + 1, st.frames + 4
    end
    if st.crouched then st.crouch_until = 0 end
    st.crouch_key_prev = cd
  end
  st.crouch_prev = st.crouched
  local target = st.crouched and (wml.read_f32(A.CROUCH_OFFSET) or 0.45) * S.crouch_scale or 0
  local dt = clamp((clock - st.last_frame_clock) / 1000, 0, 0.1)
  st.last_frame_clock = clock
  local k = 1 - math.exp(-dt * (target < st.crouch_now and 6 or 8))
  st.crouch_now = clamp(st.crouch_now + (target - st.crouch_now) * k, 0, 1.5)
  st.move_state = p ~= 0 and (wml.read_u32(p + P_MOVE) or 0) or 0

  if p ~= 0 then
    local x, z = wml.read_f32(p + 20), wml.read_f32(p + 28)
    if st.last_x and clock > st.last_clock then
      local v = math.sqrt((x - st.last_x) ^ 2 + (z - st.last_z) ^ 2) / ((clock - st.last_clock) / 1000)
      st.speed = st.speed + (v - st.speed) * 0.3
      if st.speed ~= st.speed or st.speed > 50 then st.speed = 0 end
    end
    if clock ~= st.last_clock then st.last_x, st.last_z, st.last_clock = x, z, clock end
  end

  -- Hold the raise while the game is still leaving a sprint.
  if rmb and not st.seated and not st.sprint_wins and S.raise_after_sprint and st.move_state == 3
     and st.sprint_wait < S.raise_wait then
    st.sprint_wait, st.hold_raise = st.sprint_wait + 1, true
  else
    st.hold_raise = false
    if not rmb then st.sprint_wait = 0 end
  end

  -- Melee off right mouse (on foot, guns only).
  if S.remap_melee then
    if st.pause_open then
      wml.take_key(RMB, false) wml.force_key(RMB, false)
    elseif st.in_veh then
      wml.take_key(RMB, false)
    elseif aims_with(st.equipped) then
      wml.take_key(RMB, true)
      wml.force_key(RMB, down(S.melee_key))
      st.rmb_hold = down(RMB)
    elseif st.rmb_hold and down(RMB) then
      wml.take_key(RMB, true) wml.force_key(RMB, false)
    else
      st.rmb_hold = false
      wml.take_key(RMB, false) wml.force_key(RMB, false)
    end
  end

  -- Aiming.
  local aiming = aiming_now() and not st.pause_open
  if st.pause_open then st.blend = 0 end
  if not aiming and st.blend > 0 and rmb then st.blend = 0 end
  st.aiming = aiming

  if S.fp_moves then
    if aiming then
      wml.write_u8(A.FP_FLAG, 1)
      st.fp_ours = true
    elseif st.fp_ours then
      if (wml.read_u8(A.FP_CONSOLE) or 0) == 0 then wml.write_u8(A.FP_FLAG, 0) end
      st.fp_ours = false
    end
  end

  if aiming ~= st.shift_taken then
    wml.take_key("SHIFT", aiming)
    st.shift_taken = aiming
  end

  local rate = aiming and S.aim_speed or (S.aim_return > 0 and S.aim_speed * S.aim_return or S.aim_speed)
  st.blend = st.blend + ((aiming and 1 or 0) - st.blend) * math.min(1.0, rate / 60)
  if st.blend < 0.002 then st.blend = 0 end

  -- Aiming from a vehicle: the gun raise, a light zoom, the vehicle cone.
  st.veh_aim = st.seated and raising_now()
  st.vblend = st.vblend + ((st.veh_aim and 1 or 0) - st.vblend) * math.min(1.0, rate / 60)
  if st.vblend < 0.002 then st.vblend = 0 end
  if st.equipped and aims_with(st.equipped) then st.last_gun = st.equipped end

  -- Hip fire: face the shot for a moment.
  if down(LMB) and aims_with(st.equipped) and not st.seated and not st.pause_open and not aiming then
    st.hip_until = clock + S.hip_face_ms
  end
  st.hip_fire = S.hip_face_ms > 0 and clock < st.hip_until and not st.seated and not aiming

  -- Shouldered walk at speed: stretch the game's own step while aiming in slow walk.
  if S.aim_walk_speed > 1 and aiming and st.fp_ours and slow_now() and p ~= 0 and not st.crouched then
    local x, z = wml.read_f32(p + 20), wml.read_f32(p + 28)
    if st.ws_x then
      local dx, dz = x - st.ws_x, z - st.ws_z
      local d = math.sqrt(dx * dx + dz * dz)
      if d > 0.002 and d < 0.2 then
        x, z = x + dx * (S.aim_walk_speed - 1), z + dz * (S.aim_walk_speed - 1)
        wml.write_f32(p + 20, x)
        wml.write_f32(p + 28, z)
      end
    end
    st.ws_x, st.ws_z = x, z
  else
    st.ws_x, st.ws_z = nil, nil
  end

  -- Crosshair size: guns only. Handles are re-read twice a second (they load with the HUD).
  st.ret_tick = st.ret_tick + 1
  if st.ret_tick % 30 == 1 then
    local changed = false
    for i = RETICLE_FIRST, RETICLE_LAST do
      local h = wml.read_u32(A.HUD_BITMAPS + i * 8 + 4) or 0xFFFFFFFF
      if st.ret_handles[i] ~= h then st.ret_handles[i], changed = h, true end
    end
    if changed then
      st.ret_set = {}
      for i = RETICLE_FIRST, RETICLE_LAST do
        local h = st.ret_handles[i]
        if h ~= 0xFFFFFFFF and h ~= 0 then st.ret_set[h] = true end
      end
    end
  end
  local size = 1.0
  local eq = st.equipped or (st.seated and st.last_gun) or nil
  local e = eq and W.by_name[eq]
  if e and e.cone and (aims_with(eq) or eq == "sniper_rifle") then
    if S.cone_model and S.reticle_cone then
      local m = cone_mult(aiming or st.veh_aim)
      size = m > 1 and 1 + (m - 1) * S.reticle_grow or 1 - (1 - m) * S.reticle_shrink
    else
      size = 1 - math.max(st.blend, st.vblend) * (1 - S.reticle_aim)
    end
  end
  st.ret_now = st.ret_now + (size - st.ret_now) * 0.2
  if math.abs(st.ret_now - size) < 0.002 then st.ret_now = size end

  -- Walk toggle key.
  if S.walk_key then
    local d = down(S.walk_key)
    if d and not st.walk_prev then S.walk_on = not S.walk_on end
    st.walk_prev = d
  end

  vehicle_raise()

  -- Shared camera file and tuning keys.
  if st.frames >= CFG.poll_at then
    CFG.poll_at = st.frames + 60
    local text = read_file(FILES.state)
    if text and text ~= "" and text ~= CFG.last then apply_cfg(text) TUNE.hold = 180 end
  end
  if S.tune_keys then tune_frame() end
  if TUNE.hold > 0 then
    TUNE.hold = TUNE.hold - 1
    if TUNE.hold == 0 then PR.note = "" end
  end
  if CFG.dirty and TUNE.hold == 0 then save_cfg() end
  if st.frames % 6 == 0 then show((TUNE.hold > 0 or CFG.dirty) and tune_status() or "") end
end)

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------

-- Weapon raise, re-armed every frame while right mouse is held (on foot).
wml.hook(A.FRAME_HOOK, function(ctx)
  st.equipped = resolve_equipped()
  ctx:call_original()
  local p = st.player
  if st.crouch_until > 0 and p ~= 0 and st.frames >= st.crouch_at then
    if st.frames > st.crouch_until or st.seated then
      st.crouch_until = 0
    elseif ((wml.read_u32(p + P_FLAGS) or 0) & CROUCH_BIT) == 0 then
      st.crouch_until = 0
      local r3 = ctx:r(3)
      ctx:set_r(3, p)
      pcall(function() ctx:call(A.CROUCH_FN) end)
      ctx:set_r(3, r3)
      st.crouch_logs = (st.crouch_logs or 0) + 1
      if st.crouch_logs <= 5 then
        local ok = ((wml.read_u32(p + P_FLAGS) or 0) & CROUCH_BIT) ~= 0
        wml.log("crouch on the move: " .. (ok and "crouched" or "the game refused"))
      end
    else
      st.crouch_until = 0
    end
  end
  if p == 0 or not S.aim_key then st.armed = false return end
  if raising_now() then
    if st.seated then return end
    local r3, r4, r5 = ctx:r(3), ctx:r(4), ctx:r(5)
    ctx:set_r(3, p) ctx:set_r(4, 1) ctx:set_r(5, S.raise_hold_ms)
    pcall(function() ctx:call(A.RAISE_FN) end)
    ctx:set_r(3, r3) ctx:set_r(4, r4) ctx:set_r(5, r5)
    st.armed = true
  elseif st.armed then
    local r3, r4, r5 = ctx:r(3), ctx:r(4), ctx:r(5)
    ctx:set_r(3, p) ctx:set_r(4, 0) ctx:set_r(5, 0)
    pcall(function() ctx:call(A.RAISE_FN) end)
    ctx:set_r(3, r3) ctx:set_r(4, r4) ctx:set_r(5, r5)
    st.armed = false
  end
end)

-- The first-person flag is global; keep it on the player only.
local function shield(ctx, reg, hide_from_player)
  if st.win then
    wml.write_u8(A.FP_FLAG, st.win_saved)
    ctx:call_original()
    wml.write_u8(A.FP_FLAG, st.win_ours)
  elseif st.fp_ours and (hide_from_player or ctx:r(reg) ~= st.player) then
    wml.write_u8(A.FP_FLAG, 0)
    ctx:call_original()
    wml.write_u8(A.FP_FLAG, 1)
  else
    ctx:call_original()
  end
end

-- Movement: the slow walk. With the walk toggle, the player's flag follows the toggle.
wml.hook(A.MOVE_FN, function(ctx)
  if st.win or not S.walk_key or ctx:r(3) ~= st.player then
    if st.win then ctx:call_original() return end
    shield(ctx, 3, not slow_now())
    return
  end
  local cur = wml.read_u8(A.FP_FLAG) or 0
  local want = S.walk_on and 1 or 0
  if cur == want then ctx:call_original() return end
  st.win, st.win_saved, st.win_ours = true, cur, want
  wml.write_u8(A.FP_FLAG, want)
  ctx:call_original()
  wml.write_u8(A.FP_FLAG, cur)
  st.win = false
end)

wml.hook(A.POSE_FN, function(ctx) shield(ctx, 3, false) end)

-- Locomotion: strafe while hip firing.
wml.hook(A.LOCO_FN, function(ctx)
  if st.hip_fire and not st.win and ctx:r(3) == st.player and (wml.read_u8(A.FP_FLAG) or 0) == 0 then
    wml.write_u8(A.FP_FLAG, 1)
    ctx:call_original()
    wml.write_u8(A.FP_FLAG, 0)
  elseif st.win then
    wml.write_u8(A.FP_FLAG, st.win_saved)
    ctx:call_original()
    wml.write_u8(A.FP_FLAG, st.win_ours)
  else
    ctx:call_original()
  end
end)

-- Weapon cone: Fine Aim's table instead of the game's multipliers (player only).
wml.hook(A.SPREAD_FN, function(ctx)
  local mine, a, b = ctx:r(7) == st.player, ctx:r(3), ctx:r(4)
  shield(ctx, 7, false)
  local eq = st.equipped or (st.seated and st.last_gun) or nil
  if mine and S.cone_model and a ~= 0 and b ~= 0 and eq then
    local e = W.by_name[eq]
    if e and e.cone then
      local m = cone_mult(st.aiming or st.veh_aim)
      wml.write_f32(a, e.min * m)
      wml.write_f32(b, e.max * m)
    end
  end
end)

-- Crosshair: scale only the reticle bitmaps.
wml.hook(A.DRAW_BITMAP, function(ctx)
  if st.ret_now ~= 1 and st.ret_set[ctx:r(3)] then ctx:set_f(4, ctx:f(4) * st.ret_now) end
  ctx:call_original()
end)

-- Camera placement and field of view.
local function orbit_target(px, py, pz, ux, uy, uz)
  local rx, ry, rz = read_vec(A.CAM_RIGHT)
  local vx, vy, vz = read_vec(A.CAM_UP)
  local fx, fy, fz = read_vec(A.CAM_FWD)
  local pitch = clamp(math.asin(clamp(-fy, -1, 1)), -PITCH_MAX, PITCH_MAX)
  local back, up = ORBIT_DIST, ORBIT_UP
  if pitch < 0 then
    local t = (pitch + HALF_PI) / HALF_PI - 1
    back = back + 0.4 * t * t * t
  elseif pitch > 0 then
    local t = (HALF_PI - pitch) / HALF_PI - 1
    up = up + 0.18 * t * t
  end
  back = back * 2 ^ (PR.zoom / 2)
  local eye = PR.height - ORBIT_UP - st.crouch_now
  local ex, ey, ez = px + ux * eye, py + uy * eye, pz + uz * eye
  local sh = PR.shoulder
  return ex + rx * sh + vx * up - fx * back, ey + ry * sh + vy * up - fy * back, ez + rz * sh + vz * up - fz * back
end

wml.hook(A.CAMERA_UPDATE, function(ctx)
  if st.cam_saved then
    local x, y, z = read_vec(A.CAM_POS)
    local w, sp = st.written_pos, st.saved_pos
    if math.abs(x - w[1]) + math.abs(y - w[2]) + math.abs(z - w[3]) < 0.5 then
      write_vec(A.CAM_POS, sp[1], sp[2], sp[3])
    end
    st.cam_saved = false
  end

  ctx:call_original()

  local blend = st.blend
  local active = blend > 0 and (st.aiming or not down(S.aim_key)) and not st.pause_open
  local p = st.player
  if active and p ~= 0 then
    local px, py, pz = read_vec(p + 20)
    local ux, uy, uz = read_vec(p + 44)
    if not (uy > 0.5 and uy < 1.5) then ux, uy, uz = 0, 1, 0 end
    local ox, oy, oz = px + ux * PIVOT_H, py + uy * PIVOT_H, pz + uz * PIVOT_H
    local cx, cy, cz = read_vec(A.CAM_POS)
    local dx, dy, dz = cx - ox, cy - oy, cz - oz
    if dx * dx + dy * dy + dz * dz < 1600 then
      local nx, ny, nz
      if PR.style == "orbit" then
        local tx, ty, tz = orbit_target(px, py, pz, ux, uy, uz)
        nx, ny, nz = cx + (tx - cx) * blend, cy + (ty - cy) * blend, cz + (tz - cz) * blend
      else
        local f, sx = 2 ^ (PR.zoom * blend / 2), PR.shoulder * blend
        local rx, _, rz = read_vec(A.CAM_RIGHT)
        nx, nz = ox + dx * f + rx * sx, oz + dz * f + rz * sx
        local want_y = py + uy * (PR.height - st.crouch_now) + AIM_LIFT
        ny = cy + (want_y - cy) * math.min(1.0, blend * HEIGHT_RATE)
      end
      write_vec(A.CAM_POS, nx, ny, nz)
      local sp, w = st.saved_pos, st.written_pos
      sp[1], sp[2], sp[3], w[1], w[2], w[3] = cx, cy, cz, nx, ny, nz
      st.cam_saved = true
    end
  end

  if (active and st.aiming) or (st.hip_fire and not st.pause_open) then face_camera() end

  local vb = (not st.pause_open) and st.vblend or 0
  if active or vb > 0 then
    if not st.fov_written then st.fov_base = wml.read_f32(A.CAM_FOV) end
    local f = active and (1 - blend * (1 - PR.fov)) or (1 - vb * (1 - S.vehicle_fov))
    wml.write_f32(A.CAM_FOV, st.fov_base * f)
    st.fov_written = true
  elseif st.fov_written then
    wml.write_f32(A.CAM_FOV, st.fov_base)
    st.fov_written = false
  end
end)

wml.log("Fine Aim ready")
