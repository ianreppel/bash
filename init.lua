--[[
Custom key bindings defined in this file

Ctrl + Alt + Cmd + ...
  *) C       open/focus Google Chrome
  *) J       open/focus IntelliJ IDEA
  *) K       window hints (right middle finger)
  *) L       lock screen
  *) S       open/focus Slack
  *) T       open/focus Sublime Text
  *) Ö       layout selector (right pinky, for SWE keyboard)
  *) Left    toggle window left 50%, 65%, 35%
  *) .       toggle window maximized, centred, chat (tiny)
  *) Right   toggle window right 50%, 65%, 35%
  *) Up      toggle window top 50% full/left/right
  *) Down    toggle window bottom 50% full/left/right
Alt + Tab    switch applications (incl. minimized ones)
Ctrl + Cmd + ...
  *) Left    move to display on the left
  *) Right   move to display on the right
Cmd + Alt + ...
  *) K       display current rack (right middle finger)
  *) P       toggle play/pause
  *) Left    previous track
  *) right   next track
  *) Up      volume up
  *) Down    volume down
--]]

---------------------------------------------------------------------------------------------------
-- Set up
---------------------------------------------------------------------------------------------------

-- Modifier keys
local hyper = { "Ctrl", "Alt", "Cmd" }
local move = { "Ctrl", "Cmd "}
local music = { "Alt", "Cmd"}

-- Screen identifiers
local macScreen = "Color LCD"
local largeScreen = "DELL U2715H"

hs.window.animationDuration = 0

---------------------------------------------------------------------------------------------------
-- Reload configuration and key binding functions
---------------------------------------------------------------------------------------------------

function reloadConfig(files)
  local doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
    hs.alert.show("Configuration reloaded")
  end
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

function bindKey(mod, key, fn)
  hs.hotkey.bind(mod, key, fn)
end

---------------------------------------------------------------------------------------------------
-- Display positions
---------------------------------------------------------------------------------------------------

positions = {
  maximized = hs.layout.maximized,
  centred = {x=0.15, y=0.15, w=0.7, h=0.7},

  left35 = {x=0, y=0, w=0.35, h=1},
  left50 = hs.layout.left50,
  left65 = {x=0, y=0, w=0.65, h=1},

  right35 = {x=0.65, y=0, w=0.35, h=1},
  right50 = hs.layout.right50,
  right65 = {x=0.35, y=0, w=0.65, h=1},

  upper50 =        {x=0.00, y=0, w=1.00, h=0.5}, 
  upper50Left35 =  {x=0.00, y=0, w=0.35, h=0.5},
  upper50Left50 =  {x=0.00, y=0, w=0.50, h=0.5},
  upper50Left65 =  {x=0.00, y=0, w=0.65, h=0.5},
  upper50Right35 = {x=0.65, y=0, w=0.35, h=0.5},
  upper50Right50 = {x=0.50, y=0, w=0.50, h=0.5},
  upper50Right65 = {x=0.35, y=0, w=0.65, h=0.5},

  lower50 =        {x=0.00, y=0.5, w=1.00, h=0.5},
  lower50Left35 =  {x=0.00, y=0.5, w=0.35, h=0.5},
  lower50Left50 =  {x=0.00, y=0.5, w=0.50, h=0.5},
  lower50Left65 =  {x=0.00, y=0.5, w=0.65, h=0.5},
  lower50Right35 = {x=0.65, y=0.5, w=0.35, h=0.5},
  lower50Right50 = {x=0.50, y=0.5, w=0.50, h=0.5},
  lower50Right65 = {x=0.35, y=0.5, w=0.65, h=0.5},

  chat = {x=0.7, y=0.6, w=0.3, h=0.4}
}

---------------------------------------------------------------------------------------------------
-- Layouts: choose single (multi) when one (more than one) display
---------------------------------------------------------------------------------------------------

layouts = {
  {
    name="Development",
    description="IntelliJ, Sublime, Chrome (and Slack)",
    single={
      {"Google Chrome", nil, macScreen, positions.upper50Left50, nil, nil},
      {"Sublime Text", nil, macScreen, positions.lower50Left50, nil, nil},
      {"IntelliJ IDEA", nil, macScreen, positions.right50, nil, nil},
    },
    multi={
      {"Google Chrome", nil, macScreen, positions.left50, nil, nil},
      {"Slack", nil, macScreen, positions.right50, nil, nil},
      {"Sublime Text", nil, largeScreen, positions.left35, nil, nil},
      {"IntelliJ IDEA", nil, largeScreen, positions.right65, nil, nil},
    }
  },
  {
    name="Focused development",
    description="IntelliJ, Chrome and Slack",
    single={
      {"Google Chrome", nil, macScreen, positions.upper50Left50, nil, nil},
      {"Slack", nil, macScreen, positions.lower50Left50, nil, nil},
      {"IntelliJ IDEA", nil, macScreen, positions.right50, nil, nil},
    },
    multi={
      {"Google Chrome", nil, macScreen, positions.left50, nil, nil},
      {"Slack",   nil, macScreen, positions.right50, nil, nil},
      {"IntelliJ IDEA", nil, largeScreen, positions.maximized, nil, nil},
    }
  }
}

currentLayout = null

function launchApps(arrangement, layout)
  for _, app in pairs(layout[arrangement]) do
    hs.application.launchOrFocus(app[1])
  end
end

function applyLayout(layout)
  local screens = #hs.screen.allScreens()

  local arrangement = layout.single
  if layout.multi and screens > 1 then
    arrangement = layout.multi
  end

  currentLayout = layout
  hs.layout.apply(arrangement, function(windowTitle, layoutWindowTitle)
    return string.sub(windowTitle, 1, string.len(layoutWindowTitle)) == layoutWindowTitle
  end)
end

layoutChooser = hs.chooser.new(function(selection)
  if not selection then return end
  
  local arrangement = "single"
  if #hs.screen.allScreens() > 1 then
    arrangement = "multi"
  end
  launchApps(arrangement, layouts[selection.index]) 
  applyLayout(layouts[selection.index])
end)
i = 0
layoutChooser:choices(hs.fnutils.imap(layouts, function(layout)
  i = i + 1

  return {
    index=i,
    text=layout.name,
    subText=layout.description
  }
end))
layoutChooser:rows(#layouts)
layoutChooser:width(20)
layoutChooser:subTextColor({red=0, green=0, blue=0, alpha=0.4})

hs.screen.watcher.new(function()
  if not currentLayout then return end

  applyLayout(currentLayout)
end):start()

---------------------------------------------------------------------------------------------------
-- Grid with hotkeys: modifiers for top/bottom left (right) includes left (right)
---------------------------------------------------------------------------------------------------

grid = {
  {mod=hyper, key="Left", units={positions.left50, positions.left65, positions.left35}},
  {mod=hyper, key=".", units={positions.maximized, positions.centred, positions.chat}},
  {mod=hyper, key="Right", units={positions.right50, positions.right65, positions.right35}},
  {mod=hyper, key="Up", units={positions.upper50, positions.upper50Left50, positions.upper50Right50, 
    positions.upper50Left35, positions.upper50Right35, positions.upper50Left65, positions.upper50Right65}},
  {mod=hyper, key="Down", units={positions.lower50, positions.lower50Left50, positions.lower50Right50,
    positions.lower50Left35, positions.lower50Right35, positions.lower50Left65, positions.lower50Right65}},
}
hs.fnutils.each(grid, function(entry)
  bindKey(entry.mod, entry.key, function()
    local units = entry.units
    local screen = hs.screen.mainScreen()
    local window = hs.window.focusedWindow()
    local windowGeo = window:frame()

    local index = 0
    hs.fnutils.find(units, function(unit)
      index = index + 1

      local geo = hs.geometry.new(unit):fromUnitRect(screen:frame()):floor()
      return windowGeo:equals(geo)
    end)
    if index == #units then index = 0 end

    currentLayout = null
    window:moveToUnit(units[index + 1])
  end)
end)

---------------------------------------------------------------------------------------------------
-- Custom bindings for screen locking, launching/focussing apps, and controlling Spotify
---------------------------------------------------------------------------------------------------

bindKey(hyper, "c", function() hs.application.launchOrFocus("Google Chrome") end)
bindKey(hyper, "j", function() hs.application.launchOrFocus("IntelliJ IDEA") end)
bindKey(hyper, "k", function() hs.hints.windowHints() end)
bindKey(hyper, "l", function() hs.caffeinate.startScreensaver() end)
bindKey(hyper, "s", function() hs.application.launchOrFocus("Slack") end)
bindKey(hyper, "t", function() hs.application.launchOrFocus("Sublime Text") end)
bindKey(hyper, "ö", function() layoutChooser:show() end)

switcher = hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter{})
bindKey("Alt", "Tab", function() switcher:next() end)

bindKey(move, "Left", function() hs.window.focusedWindow():moveOneScreenWest() end)
bindKey(move, "Right", function() hs.window.focusedWindow():moveOneScreenEast() end)

bindKey(music, "k", function() hs.spotify.displayCurrentTrack() end)
bindKey(music, "p", function() hs.spotify.playpause() end)
bindKey(music, "Left", function() hs.spotify.previous() end)
bindKey(music, "Right", function() hs.spotify.next() end)
bindKey(music, "Up", function() hs.spotify.volumeUp() end)
bindKey(music, "Down", function() hs.spotify.volumeDown() end)
