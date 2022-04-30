--[[ DCS-ScratchpadPlus
Welcome to DCS Scratchpad Plus. 
This is an extention on the original DCS-Scratchpad, which can be found here:
https://forum.dcs.world/topic/256390-stopwatch-overlay-for-vr-like-srs-or-scratchpad/

Options:
Display Game Time
Display Stopwatch
Display Real Time
Game Time Color Warnings based on time
Custom Colors for each timer (red, green, yellow)

--]]


local base = _G

--package.path  = package.path..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'

package.path  = package.path..";.\\LuaSocket\\?.lua;"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

local JSON = loadfile("Scripts\\JSON.lua")()

module("srs_stopwatch")

local require           = base.require
local os                = base.os
local io                = base.io
local table             = base.table
local string            = base.string
local math              = base.math
local assert            = base.assert
local pairs             = base.pairs

local lfs               = require('lfs')
local socket            = require("socket") 
local net               = require('net')
local DCS               = require("DCS") 
local U                 = require('me_utilities')
local Skin              = require('Skin')
local Gui               = require('dxgui')
local DialogLoader      = require('DialogLoader')
local Static            = require('Static')
local Tools             = require('tools')


local _modes = {     
    hidden = "hidden",
    minimum = "minimum",
    minimum_vol =  "minimum_vol",
    full = "full",
}

local _isWindowCreated = false
local _listenSocket = {}
local _radioState = {}
local _listStatics = {} -- placeholder objects
local _listMessages = {} -- data

local WIDTH = 110
local HEIGHT = 80

local _lastReceived = 0

local _offset = 0
local _utcOffset = 0
local _greenText = {}
local _yellowText = {}
local _redText = {}
local skinGT

local stopwatchOverlay = { 
    connection = nil,
    logFile = io.open(lfs.writedir()..[[Logs\DCS-Stopwatch.log]], "w")
}

function stopwatchOverlay.loadConfiguration()
    stopwatchOverlay.log("Loading config file...")
    local tbl = Tools.safeDoFile(lfs.writedir() .. 'Config/StopwatchConfig.lua', false)
    if (tbl and tbl.config) then
        stopwatchOverlay.log("Configuration exists...")
        stopwatchOverlay.config = tbl.config
    else
        stopwatchOverlay.log("Configuration not found, creating defaults...")
        stopwatchOverlay.config = {
            mode = "full",
            restoreAfterRestart = true,
            hotkey = "Ctrl+Shift+escape",
            resetHotkey = "Ctrl+Shift+space",
            windowPosition = { x = 200, y = 200 }
        }
        stopwatchOverlay.saveConfiguration()
    end
end

function stopwatchOverlay.saveConfiguration()
    U.saveInFile(stopwatchOverlay.config, 'config', lfs.writedir() .. 'Config/StopwatchConfig.lua')
end

function stopwatchOverlay.log(str)
    if not str then 
        return
    end

    if stopwatchOverlay.logFile then
        stopwatchOverlay.logFile:write("["..os.date("%H:%M:%S").."] "..str.."\r\n")
        stopwatchOverlay.logFile:flush()
    end
end

function formatTime(time)
    local seconds = math.floor(time) % 60
    local minutes = math.floor(time / 60) % 60
    local hours = math.floor(time / (60 * 60)) % 24

    return string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) .. ":" .. string.format("%02d", seconds)
	
end    

function stopwatchOverlay.paint()
    _listMessages = {}
    local offset = 0
   
    for k,v in pairs(_listStatics) do
        v:setText("")
    end

    local curStatic = 1
    offset = 10 -- 10 offset from top

    table.insert(_listMessages, {
        message = "SW " .. (formatTime(math.floor(DCS.getRealTime() - _offset))), 
        skin=_greenText, 
        height = 20 
    })
	
	function setGameTimeColor()
		-- enter times in minutes
		-- red must be more than yellow
		skinGT = _greenText
		if DCS.getRealTime() > minutesToSeconds(5) then
			skinGT = _redText -- red
		elseif DCS.getRealTime() > minutesToSeconds(3) then
			skinGT = _yellowText -- yellow
		end
		return skinGT
	end
	
	function minutesToSeconds(minutes)
		seconds = minutes * 60
		return seconds
	end
	

	table.insert(_listMessages, {
        message = "GT " .. (formatTime(math.floor(DCS.getRealTime()))), 
		--message = DCS.getRealTime(), -- debug
        skin= setGameTimeColor(), 
        height = 20 
    })

	table.insert(_listMessages, {
        --message = formatTime(os.time()), -- default way to do it
		message = ("RT " .. os.date("%H:%M:%S")),
        skin=_greenText, 
        height = 20 
    })
	
    for _i,_msg in pairs(_listMessages) do

        if(_msg~=nil and _msg.message ~= nil and  _listStatics[curStatic] ~= nil ) then
            _listStatics[curStatic]:setSkin(_msg.skin)
            _listStatics[curStatic]:setBounds(10,offset,WIDTH-10,_msg.height)
            _listStatics[curStatic]:setText(_msg.message)

            --10 padding
            offset = offset + 15 -- consider making this changable. from 10 to 20
            curStatic = curStatic + 1
        end

    end

end

function stopwatchOverlay.createWindow()
    window = DialogLoader.spawnDialogFromFile(lfs.writedir() .. 'Mods\\Tech\\DCS-Stopwatch\\UI\\DCS-Stopwatch.dlg', cdata)

    box         = window.Box
    pNoVisible  = window.pNoVisible --PlaceHolder - Not Visible
   -- pDown       = box.pDown

    window:addHotKeyCallback(stopwatchOverlay.config.hotkey, stopwatchOverlay.onHotkey)
    window:addHotKeyCallback(stopwatchOverlay.config.resetHotkey, function()
        _offset = DCS.getRealTime()
    end)
    
    window:setVisible(true) -- if you make the window invisible, its destroyed
    
    skinModeFull = pNoVisible.windowModeFull:getSkin()
    skinMinimum = pNoVisible.windowModeMin:getSkin()

    _greenText = pNoVisible.eGreenText:getSkin()
    _yellowText = pNoVisible.eYellowText:getSkin()
	_redText = pNoVisible.eRedText:getSkin()
    
    _listStatics = {}
    
    for i = 1, 6 do
        local staticNew = Static.new()
        table.insert(_listStatics, staticNew)
        box:insertWidget(staticNew)
    end

    w, h = Gui.GetWindowSize()
            
    stopwatchOverlay.resize(w, h)
    
    local enabled = true --base.OptionsData.getPlugin("DCS-SRS","stopwatchOverlayEnabled")

    if enabled then

        if _modes.hidden == stopwatchOverlay.config.mode then
            -- set to minimum
            stopwatchOverlay.setMode(_modes.minimum)
        else
            stopwatchOverlay.setMode(stopwatchOverlay.config.mode) 
        end

    else
        stopwatchOverlay.setMode(_modes.hidden)
    end

    --client = socket.connect("worldtimeapi.org", 80)
    --client:send("GET /api/timezone/Etc/UTC HTTP/1.0\r\nHost: worldtimeapi.org\r\n\r\n")
    --while true do
    --  s, status, partial = client:receive('*a')
    --  _utcOffset = s
    --  if status == "closed" then 
    --    break 
    --  end
    --end
    --client:close()
   
    window:addPositionCallback(stopwatchOverlay.positionCallback)     
    stopwatchOverlay.positionCallback()

    _isWindowCreated = true
end


function stopwatchOverlay.setMode(mode)
    stopwatchOverlay.log("setMode called "..mode)
    stopwatchOverlay.config.mode = mode 
    
    if window == nil then
        return
    end
    
    if stopwatchOverlay.config.mode == _modes.hidden then

        box:setVisible(false)
   --     pDown:setVisible(false)
        window:setSize(0,0) -- Make it tiny!
        window:setHasCursor(false) -- hide cursor

        window:setSkin(Skin.windowSkinChatMin())

    else
        box:setVisible(true)
        window:setSize(WIDTH, HEIGHT)

        if stopwatchOverlay.config.mode == _modes.minimum or stopwatchOverlay.config.mode == _modes.minimum_vol then

            box:setSkin(skinMinimum)

         --   pDown:setVisible(false)

            window:setSkin(Skin.windowSkinChatMin())

            window:setHasCursor(false) -- hide cursor


            --  DCS.banMouse(false)
        end
        
        if stopwatchOverlay.config.mode == _modes.full then
            box:setSkin(skinModeFull)

            box:setVisible(true)
           -- pDown:setVisible(true)

            window:setSkin(Skin.windowSkinChatWrite())

            window:setHasCursor(true) -- show cursor
        end    
    end

    window:setVisible(true) -- if you make the window invisible, its destroyed
    stopwatchOverlay.saveConfiguration()
    stopwatchOverlay.paint()
end

function stopwatchOverlay.getMode()
    return stopwatchOverlay.config.mode
end

function stopwatchOverlay.onHotkey()
    if (stopwatchOverlay.getMode() == _modes.full) then
        stopwatchOverlay.setMode(_modes.minimum)
    elseif (stopwatchOverlay.getMode() == _modes.minimum) then
        --stopwatchOverlay.setMode(_modes.minimum_vol)
    --elseif (stopwatchOverlay.getMode() == _modes.minimum_vol) then
        stopwatchOverlay.setMode(_modes.hidden)
    else
        stopwatchOverlay.setMode(_modes.full)
    end 
end

function stopwatchOverlay.resize(w, h)
    window:setBounds(stopwatchOverlay.config.windowPosition.x, stopwatchOverlay.config.windowPosition.y, WIDTH, HEIGHT)
    box:setBounds(0, 0, WIDTH, HEIGHT)
end

function stopwatchOverlay.positionCallback()
    local x, y = window:getPosition()

    x = math.max(math.min(x, w-WIDTH), 0)
    y = math.max(math.min(y, h-HEIGHT), 0)

    window:setPosition(x, y)

    stopwatchOverlay.config.windowPosition = { x = x, y = y }
    stopwatchOverlay.saveConfiguration()
end

function stopwatchOverlay.onSimulationFrame()

    if not base.OptionsData then
        --stopwatchOverlay.log("NO Options Data")
        return
    end

    if stopwatchOverlay.config == nil then
        stopwatchOverlay.loadConfiguration()
    end

    if not window then

        if _isWindowCreated == false then
            stopwatchOverlay.createWindow()
        end
    else
        stopwatchOverlay.paint()
    end    
end 

DCS.setUserCallbacks(stopwatchOverlay)