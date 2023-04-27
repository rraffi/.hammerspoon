-- Load Extensions
local application = hs.application
local window = hs.window
local hotkey = hs.hotkey
local keycodes = hs.keycodes
local fnutils = hs.fnutils
local alert = hs.alert
local screen = hs.screen
local grid = hs.grid
local hints = hs.hints
local appfinder = hs.appfinder
local spaces = hs.spaces

local mashDefinitions = nil
local hyperDefinitions = nil
local extraMashDefinitions = nil
local mash = nil
local hyperMash = nil
local extraMash = nil
local myApps =  nil
local myScreens = nil

-- predefined grid cells
local gomiddle = nil
local goleft = nil
local goright = nil
local gobig = nil
local goRightTwoThird = nil
local goRightThird = nil
local goLeftTwoThird = nil
local goLeftThird = nil
local goTop = nil
local goBottom = nil

window.animationDuration = 0.1

local functionNames = {}
function registerFunctionName(fn, name)
    functionNames[fn] = name
end

function getFunctionName(fn)
    return functionNames[fn]
end

local gridset = function(frame)
	return function()
		local win = window.focusedWindow()
		if win then
			grid.set(win, frame, win:screen())
		else
			alert.show("No focused window.")
		end
	end
end

auxWin = nil
function saveFocus()
  auxWin = window.focusedwindow()
  alert.show("Window '" .. auxWin:title() .. "' saved.")
end
function focusSaved()
  if auxWin then
    auxWin:focus()
  end
end

local hotkeys = {}

function createHotkeys(modifierKeys, definitions)
    for i, def in ipairs(definitions) do
--        if string.len(key) == 2 and string.sub(key,2,2) == "c" then
--            mod = {"cmd"}
--        end

        local hotKeyDef = def[1]
        for key, fun in pairs(hotKeyDef) do
            local hk = hotkey.new(modifierKeys, string.sub(key,1,1), fun)
            table.insert(hotkeys, hk)
            hk:enable()
        end
    end
end

function rebindHotkeys()
  for i, hk in ipairs(hotkeys) do
    hk:disable()
  end
  hotkeys = {}
  createHotkeys()
  alert.show("Rebound Hotkeys")
end

-- Moves a window (win) to a specific cell(place[2]) on a particular screenid(place[1])
function applyPlace(win, place)
  local scrID = place[1]
  local scr = getScreenUsingId(scrID)
  if not scr then
      scr = getScreenUsingId(myScreens.MacbookScreen)
  end
  grid.set(win, place[2], scr)
end

-- Iterates over myApps and applying the associated default layout
function applyDefaultLayouts()
  return function()
      alert.show("Applying Default Layout")
      for i, myApp in ipairs(myApps) do
          local app = appfinder.app_from_name(myApp.name)
          applyLayoutForApp(app, myApp.layout)
      end
  end
end

-- Applies the given layout to anApp
-- anApp should be a valid hammerspoon.application instance
-- layout should be a table with two values a screen id and table with x,y,w,h dimensions
function applyLayoutForApp(anApp, layout)
    if not anApp then return end

    for i, win in ipairs(anApp:allwindows()) do
        applyPlace(win, layout)
    end
end

-- Looks at the focused application and checks for a default layout and applies it
-- if no default layout is defined then gomiddle is applied on the current screen
function applyDefaultLayoutForFocusedApp()
    return function()
        local activeApp = window.focusedwindow():application()
        if activeApp then
            for i, myApp in ipairs(myApps) do
                if myApp.name == activeApp:title() then
                    applyLayoutForApp(activeApp, myApp.layout)
                    return
                end
            end
            applyLayoutForApp(activeApp, { window.focusedwindow():screen():id(), gomiddle })
        end
    end

end

function launchDefaultApps()
    return function()
        for i, app in ipairs(myApps) do
            if app.isDefault then
                application.launchorfocus(app.name)
            end
        end
    end
end

function getScreenUsingId(anId)
    for i, scr in ipairs(screen:allscreens()) do
        if (scr:id() == anId) then
            return scr
        end
    end
    return nil
end

function moveActiveWindow(direction)
    return function()
        local activeWindow = window.focusedwindow()
        local toScrn = nil
        if direction == "n" then
            toScrn = activeWindow:screen():tonorth()
        elseif direction == "s" then
            toScrn = activeWindow:screen():tosouth()
        elseif direction == "e" then
            toScrn = activeWindow:screen():toeast()
        elseif direction == "w" then
            toScrn = activeWindow:screen():towest()
        else
            return
        end
        if toScrn then
            applyPlace(activeWindow, { toScrn:id(), gomiddle })
        end
    end
end

function displayHotkeyHints(modKeyType)
    return function()
        local keyTable = nil
        if modKeyType == "mash" then
            keyTable = mashDefinitions
        elseif modKeyType == "extra" then
            keyTable = extraMashDefinitions
        elseif modKeyType == "hyper" then
            keyTable = hyperDefinitions
        else
            return
        end

        local hintText = ""
        for i, def in ipairs(keyTable) do
            local desc = def[2]
            local hk = nil
            for key, fun in pairs(def[1]) do
                hk = key
            end
            local line = string.format("%s\t = %s", hk, desc)
            hintText = hintText .. line .. "\n"
        end
        alert.show(hintText, 5)
    end

end

function killAllApplications()
    return function()
        for i, a in ipairs(application.runningapplications()) do
            local title = a:title()
            if title == "Dock"
                    or title == "Finder"
                    or title == "Alfred 2"
                    or title == "Hammerspoon"
                    or title == "loginwindow"
                    or title == "Notification Center"
                    or title == "CoreServicesUIAgent"
                    or title == "Little Snitch Agent"
                    or title == "Little Snitch Network Monitor"
                    or title == "Keychain Circle Notification"
                    or title == "SystemUIServer" then
                -- do nothing
            else
                a:kill()
            end
        end
    end
end

function test()
    return function()
        alert.show("test")
--        displayHotkeyHints()(mash)
    end
end

function init()
  createHotkeys(mash, mashDefinitions)
  createHotkeys(extraMash, extraMashDefinitions)
  createHotkeys(hyperMash, hyperDefinitions)
  keycodes.inputSourceChanged(rebindHotkeys)
  alert.show("Hammerspoon, at your service.")
end

-- Actual config =================================

-- define modifier combos
mash = { "alt", "shift" }
extraMash = { "ctrl", "cmd", "shift" }
hyperMash = { "ctrl", "alt", "cmd", "shift" }

-- Set grid size.
grid.GRIDWIDTH  = 6
grid.GRIDHEIGHT = 8
grid.MARGINX = 0
grid.MARGINY = 0
local gw = grid.GRIDWIDTH
local gh = grid.GRIDHEIGHT

gomiddle =          {x = 1,         y = 1,      w = 4,          h = 6       }
goleft =            {x = 0,         y = 0,      w = gw/2,       h = gh      }
goright =           {x = gw/2,      y = 0,      w = gw/2,       h = gh      }
gobig =             {x = 0,         y = 0,      w = gw,         h = gh      }
goRightTwoThird =   {x = gw/3,      y = 0,      w = (gw*2)/3,   h = gh      }
goRightThird =      {x = (gw*2)/3,  y = 0,      w = gw/3,       h = gh      }
goMiddleThird =     {x = gw/3,      y = 0,      w = gw/3,       h = gh      }
goLeftTwoThird =    {x = 0,         y = 0,      w = (gw*2)/3,   h = gh      }
goLeftThird =       {x = 0,         y = 0,      w = gw/3,       h = gh      }
goTop =             {x = 0,         y = 0,      w = gw,         h = gh/2    }
goBottom =          {x = 0,         y = gh/2,   w = gw,         h = gh/2    }
goUpperLeft =       {x = 0,         y = 0,      w = gw/2,       h = gh/2    }
goLowerLeft =       {x = 0,         y = gh/2,   w = gw/2,       h = gh/2    }
goUpperRight =      {x = gw/2,  y = 0,      w = gw/2,       h = gh/2    }
goLowerRight =      {x = gw/2,  y = gh/2,   w = gw/2,       h = gh/2    }
goUpperMiddle =     {x = gw/3,      y = 0,      w = gw/3,       h = gh/2    }
goLowerMiddle =     {x = gw/3,      y = gh/2,   w = gw/3,       h = gh/2    }
goVertTopThird =        {x = 0,         y = 0,      w = gw,         h = gh/3    }
goVertMiddleThird =     {x = 0,         y = gh/3,      w = gw,         h = gh/3    }
goVertBottomThird =     {x = 0,         y = (gh*2)/3,      w = gw,         h = gh/3    }
goVertTopTwoThird =     {x = 0,      y = 0,      w = gw,   h = (gh*2)/3      }
goVertBottomTwoThird =  {x = 0,      y = gh/3,      w = gw,   h = (gh*2)/3      }
goLeftFifth =           {x = 0,      y = 0,      w = 5,   h = gh      }
goRightFifth =          {x = 1,      y = 0,      w = gw,   h = gh      } 



-- mash mashDefinitions should be used to affect a single application at a time
mashDefinitions = {
    { { ["["] = saveFocus },                        "Remember current window" },
    { { ["]"] = focusSaved },                       "Give focus to window with saved focus" },

    { { a = gridset(goLeftThird) },                 "Grid: Left Third" },
    { { q = gridset(goUpperLeft) },                 "Grid: Upper Left Corrner"},
    { { z = gridset(goLowerLeft) },                 "Grid: Lower Left Corrner"},
    { { e = gridset(goUpperRight) },                "Grid: Upper Right Corrner"},
    { { c = gridset(goLowerRight) },                "Grid: Lower Right Corrner"},
    { { w = gridset(goUpperMiddle) },               "Grid: Upper Middle"},
    { { x = gridset(goLowerMiddle) },               "Grid: Lower Middle"},
    { { s = gridset(goMiddleThird) },               "Grid: Middle Third" },
    { { d = gridset(goRightThird) },                "Grid: Right Third" },
    { { f = gridset(goLeftTwoThird) },              "Grid: Left Two Thirds" },
    { { g = gridset(goRightTwoThird) },             "Grid: Right Two Thirds" },

    { { j = gridset(goleft) },                      "Grid: Left Half" },
    { { k = gridset(goright) },                     "Grid: Right Half" },
    { { i = gridset(goTop) },                       "Grid: Top Half" },
    { { m = gridset(goBottom) },                    "Grid: Bottom Half" },

    { { y = gridset(goVertTopThird) },              "Grid: Vertical Top Third" },
    { { h = gridset(goVertMiddleThird) },           "Grid: Vertical Middle Third" },
    { { n = gridset(goVertBottomThird) },           "Grid: Vertical Bottom Third" },
    { { t = gridset(goVertTopTwoThird) },           "Grid: Vertical Bottom Third" },
    { { u = gridset(goVertBottomTwoThird) },           "Grid: Vertical Bottom Third" },

    { { [","] = gridset(gobig) },                   "Grid: Fullscreen" },
    { { ["."] = gridset(gomiddle) },                    "Grid: Center" },
    -- { { n = moveActiveWindow("n") },                "Move window North" },
    -- { { s = moveActiveWindow("s") },                "Move window South" },
    -- { { e = moveActiveWindow("e") },                "Move window East" },
    -- { { w = moveActiveWindow("w") },                "Move window West" },
    -- { { d = applyDefaultLayoutForFocusedApp() },    "Apply default layout" },
    { { ["l"] = gridset(goLeftFifth) },                    "Grid: Left Five Sixths" },
    { { [";"] = gridset(goRightFifth) },                    "Grid: Right Five Sixths" },
    { { ["/"] = displayHotkeyHints("mash") },           "Display Hotkey Hints for mod" },
}

-- Use hyper for anything that affects more than one app
hyperDefinitions = {
    { { r = hs.reload } ,              "Reload Hammerspoon Config" },
    { { l = launchDefaultApps() },          "Launch Default Applications" },
    { { ["1"] = applyDefaultLayouts() },    "Apply default layout to open applications" },
    { { o = print() }, "ArrangeDesktop: Use Office arragement" },
    { { q = killAllApplications() },        "Kills all applications" },
    { { h = displayHotkeyHints("hyper") },  "Display Hotkey Hints for hyper mod" },
}

extraMashDefinitions = {
    { { h = displayHotkeyHints("extra") },  "Display Hotkey Hints for extra mod" },
}

myScreens = {
    -- MacbookScreen = 69731906, -- Built in Macbook screen
    DellS3220DGF = 724854235, -- Left
    SideCarIpad = 4128833, -- Middle
    -- AsusVS238 = 440930809, -- Right
}

myApps =  {
    -- Apps that I always want to be running
    { name = "Firefox",                 layout = {myScreens.AsusVS247, goRightTwoThird},    isDefault = false, hotKey = "f" },
    { name = "AppCode",                 layout = {myScreens.AsusVS239, gobig},              isDefault = true, hotKey = "a" },
    { name = "Skype",                   layout = {myScreens.AsusVS238, goBottom},           isDefault = true, hotKey = "k" },
    { name = "Microsoft Outlook",       layout = {myScreens.AsusVS238, goTop},              isDefault = true, hotKey = "o" },
    -- { name = "Sublime Text",            layout = {myScreens.MacbookScreen, gobig},          isDefault = true, hotKey = "s" },
    { name = "IDCLimeChat",             layout = {myScreens.AsusVS238, goBottom},           isDefault = true, hotKey = "l" },
    { name = "Finder",                  layout = {myScreens.AsusVS247, goLeftThird},        isDefault = true, hotKey = "e" },
    { name = "Terminal",                layout = {myScreens.MacbookScreen, gobig},          isDefault = true, hotKey = "t" },

    -- Other apps that I want to have specific layout for even though they dont get launched by default
    { name = "Slack",                   layout = {myScreens.SideCarIpad, gobig},            isDefault = false, hotKey = "s" },
    { name = "Sourcetree",              layout = {myScreens.DellS3220DGF, gobig},           isDefault = false, hotKey = "g" },
    { name = "Xcode-13.2.1.app",        layout = {myScreens.DellS3220DGF, gobig},           isDefault = false, hotKey = "x" },
    { name = "Visual Studio Code",      layout = {myScreens.DellS3220DGF, gobig},           isDefault = false, hotKey = "v" },
    { name = "iTerm",                   layout = {myScreens.DellS3220DGF, gobig},           isDefault = false, hotKey = "z" },
    { name = "Google Chrome",           layout = {myScreens.DellS3220DGF, gobig},           isDefault = false, hotKey = "c" },
    { name = "Zoom.us",                 layout = {myScreens.DellS3220DGF, gobig},        isDefault = false, hotKey = "m" },
}
fnutils.each(myApps, function(myApp)
    local fn = function ()
        application.launchOrFocus(myApp.name)
    end

    local hk = {}
    hk[myApp.hotKey] = fn
    local desc = "Open " .. myApp.name
    local def = { hk, desc }

    table.insert(extraMashDefinitions, def)
end)

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

-- print(" ======== DEBUG =========")
-- spoonAd = hs.loadSpoon("ArrangeDesktop")
-- hs.application.enableSpotlightForNameSearches(true)
-- -- for k,v in pairs(spoonAd) do
-- --     print(k, v)
-- -- end

-- -- for k,v in pairs(spoonAd._loadConfiguration()["Office"]) do
-- --     print(k, v)
-- -- end

-- -- spoonAd.arrange(spoonAd._loadConfiguration())
-- -- print(spoonAd.arrangements)
-- -- for k,v in pairs(spoonAd.arrangements) do
-- --     print("Hello")
-- --     print(k, v)
-- -- end

-- -- spoonAd:arrange(spoonAd._loadConfiguration())

-- if spoonAd ~= nil then
--     -- for k,v in pairs(spoonAd.arragement) do
--     --     print(k, v)
--     -- end
--     -- spoonAd:createArrangement()
--     spoonAd.arrangements = spoonAd:_loadConfiguration()
--     -- spoonAd:arrange("Laptop")
--     print(#spoonAd)
--     print("hello")
-- end

init()