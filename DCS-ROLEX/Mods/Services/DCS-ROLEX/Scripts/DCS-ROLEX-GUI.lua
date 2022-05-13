--[[ DCS-ROLEX
Welcome to DCS Relatively Obvious Little Epoch eXtension. 
This is modified from the original DCS-Scratchpad, which can be found here:
https://forum.dcs.world/topic/256390-stopwatch-overlay-for-vr-like-srs-or-scratchpad/

Wishlist:
Changeable Font Size
--]]

local version = "1.0"

net.log("Loading - DCS-ROLEX - Bailey: " .. version)

local base = _G

package.path  = package.path..";"..'.\\Scripts\\?.lua;'.. '.\\Scripts\\UI\\?.lua;'

local JSON = loadfile("Scripts\\JSON.lua")()

module("dcs_rolex")

local require           = base.require
local os                = base.os
local io                = base.io
local table             = base.table
local string            = base.string
local math              = base.math
local assert            = base.assert
local pairs             = base.pairs

local lfs               = require('lfs')
local net               = require('net')
local DCS               = require("DCS") 
local U                 = require('me_utilities')
local Skin              = require('Skin')
local Gui               = require('dxgui')
local DialogLoader      = require('DialogLoader')
local Static            = require('Static')
local Tools             = require('tools')
local OptionsData		= require('Options.Data')
local Terrain 			= require('terrain')

local _modes = {     
    hidden = "hidden",
    minimum = "minimum",
    minimum_vol =  "minimum_vol",
    full = "full",
}

local _isWindowCreated = false
--local _radioState = {}
local _listStatics = {} -- placeholder objects
local _listMessages = {} -- data

local WIDTH = 110
local HEIGHT = 120

--local _lastReceived = 0

local _offsetDcsRealTime = 0

local _greenText = {}
local _yellowText = {}
local _redText = {}
local _whiteText = {}
local _blueText = {}
local _magentaText = {}
local _cyanText = {}
local _orangeText = {}
local _blackText = {}
--local skinGT

local missionStartTime = -1 -- seconds
local dcsLocalTime = 0 -- formated for export
local dcsUtcTime = 0
local isInMission = false
local utcOffset = 0

local rolexOverlay = { 
    --connection = nil,
    logFile = io.open(lfs.writedir()..[[Logs\DCS-ROLEX.log]], "w")
}

function rolexOverlay.loadConfiguration()
    rolexOverlay.log("Loading config file...")
    local tbl = Tools.safeDoFile(lfs.writedir() .. 'Config/rolexConfig.lua', false)
    if (tbl and tbl.config) then
        rolexOverlay.log("Configuration exists...")
        rolexOverlay.config = tbl.config
    else
        rolexOverlay.log("Configuration not found, creating defaults...")
        rolexOverlay.config = {
            mode = "full",
            restoreAfterRestart = true,
            hotkey = "Ctrl+Shift+F8",
            resetHotkey = "Ctrl+Shift+space",
            windowPosition = { x = 200, y = 200 }
        }
        rolexOverlay.saveConfiguration()
    end
end

function rolexOverlay.saveConfiguration()
    U.saveInFile(rolexOverlay.config, 'config', lfs.writedir() .. 'Config/rolexConfig.lua')
end

function rolexOverlay.log(str)
    if not str then 
        return
    end

    if rolexOverlay.logFile then
        rolexOverlay.logFile:write("["..os.date("%H:%M:%S").."] "..str.."\r\n")
        rolexOverlay.logFile:flush()
    end
end

function formatTime(time)
    local seconds = math.floor(time) % 60
    local minutes = math.floor(time / 60) % 60
    local hours = math.floor(time / (60 * 60)) % 24

    return string.format("%02d", hours) .. ":" .. string.format("%02d", minutes) .. ":" .. string.format("%02d", seconds)
	
end    

function rolexOverlay.paint()
    _listMessages = {}
    local offset = 0
   
    for k,v in pairs(_listStatics) do
        v:setText("")
    end

    local curStatic = 1
    offset = 10 -- 10 offset from top
	
	local isShow = OptionsData.getPlugin("DCS-ROLEX","stopwatch") -- read the value from options lua
		if isShow then -- if it is true, put it in the table list
    table.insert(_listMessages, {
        message = "SW " .. (formatTime(math.floor(DCS.getRealTime() - _offsetDcsRealTime))), 
        skin = setTextColor("stopwatch"), 
        height = 20 
    })
	end
	
	local isShow = OptionsData.getPlugin("DCS-ROLEX","gameTime")
	if isShow then
		table.insert(_listMessages, {
			-- ST session time ir GT game time or PT play time
			message = "GT " .. (formatTime(math.floor(DCS.getRealTime()))), 
			--message = DCS.getRealTime(), -- debug
			skin = setTextColor("gameTime"),
			height = 20 
		})
	end

	local isShow = OptionsData.getPlugin("DCS-ROLEX","realLocal")
	if isShow then
	table.insert(_listMessages, {
        --message = formatTime(os.time()), -- default way to do it
		message = ("RL " .. os.date("%H:%M:%S")), -- Real Local Time
        skin = setTextColor("realLocal"),
        height = 20 
    })
	end
	
	local isShow = OptionsData.getPlugin("DCS-ROLEX","realZulu")
	if isShow then
	table.insert(_listMessages, {
		message = ("RZ " .. os.date("!%H:%M:%S")), -- ! for zulu/UTC, real zulu time
        skin = setTextColor("realZulu"),
        height = 20 
    })
	end
	
	-- game local time
	local isShow = OptionsData.getPlugin("DCS-ROLEX","gameLocal")
	if isShow then
	table.insert(_listMessages, {
		message = ("GL " .. dcsLocalTime), 
		skin = setTextColor("gameLocal"),
        height = 20 
    })
	end
	
	-- game UTC zulu time 
	-- use "get_absolute_model_time()"?
	local isShow = OptionsData.getPlugin("DCS-ROLEX","gameZulu")
	if isShow then
	table.insert(_listMessages, {
		message = ("GZ " .. dcsUtcTime), 
        skin = setTextColor("gameZulu"),
        height = 20 
    })
	end
	
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
	
function setTextColor(whichTime)

	if whichTime == "stopwatch" then
		if DCS.getRealTime() - _offsetDcsRealTime > minutesToSeconds(OptionsData.getPlugin("DCS-ROLEX","stopwatchWarningMinutes")) then -- warning
			skinColor = numbersToColors("stopwatchWarningColor")
		elseif DCS.getRealTime() - _offsetDcsRealTime > minutesToSeconds(OptionsData.getPlugin("DCS-ROLEX","stopwatchCautionMinutes")) then -- caution
			skinColor = numbersToColors("stopwatchCautionColor")
		else
			skinColor = numbersToColors("stopwatchDefaultColor")
		end
	end
	
	if whichTime == "gameTime" then
	-- setting the default state
		if DCS.getRealTime() > minutesToSeconds(OptionsData.getPlugin("DCS-ROLEX","gameTimeWarningMinutes")) then -- warning
			skinColor = numbersToColors("gameTimeWarningColor")
		elseif DCS.getRealTime() > minutesToSeconds(OptionsData.getPlugin("DCS-ROLEX","gameTimeCautionMinutes")) then -- caution
			skinColor = numbersToColors("gameTimeCautionColor")
		else
			skinColor = numbersToColors("gameTimeDefaultColor")
		end
	end
	
	if whichTime == "realLocal" then
		skinColor = numbersToColors("realLocalDefaultColor")
	end
	
	if whichTime == "realZulu" then
		skinColor = numbersToColors("realZuluDefaultColor")
	end
	
	if whichTime == "gameLocal" then
		skinColor = numbersToColors("gameLocalDefaultColor")
	end
	
	if whichTime == "gameZulu" then
		skinColor = numbersToColors("gameZuluDefaultColor")
	end
	
	return skinColor
end
	
function numbersToColors(optionLuaRequest)
	--[[ Colors
	DbOption.Item(_('Green')):Value(0),
	DbOption.Item(_('Yellow')):Value(1),
	DbOption.Item(_('Red')):Value(2),
	DbOption.Item(_('White')):Value(3),
	DbOption.Item(_('Blue')):Value(4),
	DbOption.Item(_('Magenta')):Value(5),
	DbOption.Item(_('Cyan')):Value(6),
	DbOption.Item(_('Orange')):Value(7),
	--]]
	local optionLuaValue = OptionsData.getPlugin("DCS-ROLEX",optionLuaRequest)
	if optionLuaValue == 0 then
		skinColor = _greenText
	elseif optionLuaValue == 1 then
		skinColor = _yellowText
	elseif optionLuaValue == 2 then
		skinColor = _redText
	elseif optionLuaValue == 3 then
		skinColor = _whiteText
	elseif optionLuaValue == 4 then
		skinColor = _blueText
	elseif optionLuaValue == 5 then
		skinColor = _magentaText
	elseif optionLuaValue == 6 then
		skinColor = _cyanText
	elseif optionLuaValue == 7 then
		skinColor = _orangeText
	elseif optionLuaValue == 8 then
		skinColor = _blackText
	else
		skinColor = _greenText
	
	end
	return skinColor
end

function minutesToSeconds(minutes)
	-- covers the case the the user pressed backspace 
	-- to clear the minutes box in special options
	if minutes == "" then return 0 end
	-- covers normal cases where there is a decimal number
	seconds = minutes * 60
	return seconds
end

function rolexOverlay.createWindow()
    window = DialogLoader.spawnDialogFromFile(lfs.writedir() .. 'Mods\\Services\\DCS-ROLEX\\UI\\DCS-ROLEX.dlg', cdata)

    box         = window.Box
    pNoVisible  = window.pNoVisible --PlaceHolder - Not Visible
   -- pDown       = box.pDown

    window:addHotKeyCallback(rolexOverlay.config.hotkey, rolexOverlay.onHotkey)
    window:addHotKeyCallback(rolexOverlay.config.resetHotkey, function()
        _offsetDcsRealTime = DCS.getRealTime()
    end)
    
    window:setVisible(true) -- if you make the window invisible, its destroyed
    
    skinModeFull = pNoVisible.windowModeFull:getSkin()
    skinMinimum = pNoVisible.windowModeMin:getSkin()

	-- text colors
    _greenText 		= pNoVisible.eGreenText:getSkin()
    _yellowText 	= pNoVisible.eYellowText:getSkin()
	_redText 		= pNoVisible.eRedText:getSkin()
	_whiteText 		= pNoVisible.eWhiteText:getSkin()
	_blueText 		= pNoVisible.eBlueText:getSkin()
	_magentaText 	= pNoVisible.eMagentaText:getSkin()
	_cyanText 		= pNoVisible.eCyanText:getSkin()
	_orangeText 	= pNoVisible.eOrangeText:getSkin()
	_blackText 		= pNoVisible.eBlackText:getSkin()
	
    _listStatics = {}
    
    for i = 1, 6 do
        local staticNew = Static.new()
        table.insert(_listStatics, staticNew)
        box:insertWidget(staticNew)
    end

    w, h = Gui.GetWindowSize()
            
    rolexOverlay.resize(w, h)
    
    local enabled = true --base.OptionsData.getPlugin("DCS-SRS","rolexOverlayEnabled")

    if enabled then

        if _modes.hidden == rolexOverlay.config.mode then
            -- set to minimum
            rolexOverlay.setMode(_modes.minimum)
        else
            rolexOverlay.setMode(rolexOverlay.config.mode) 
        end

    else
        rolexOverlay.setMode(_modes.hidden)
    end
   
    window:addPositionCallback(rolexOverlay.positionCallback)     
    rolexOverlay.positionCallback()

    _isWindowCreated = true
end


function rolexOverlay.setMode(mode)
    rolexOverlay.log("setMode called: "..mode)
    rolexOverlay.config.mode = mode 
    
    if window == nil then
        return
    end
    
    if rolexOverlay.config.mode == _modes.hidden then

        box:setVisible(false)
   --     pDown:setVisible(false)
        window:setSize(0,0) -- Make it tiny!
        window:setHasCursor(false) -- hide cursor

        window:setSkin(Skin.windowSkinChatMin())

    else
        box:setVisible(true)
        window:setSize(WIDTH, HEIGHT)

        if rolexOverlay.config.mode == _modes.minimum or rolexOverlay.config.mode == _modes.minimum_vol then

            box:setSkin(skinMinimum)

         --   pDown:setVisible(false)

            window:setSkin(Skin.windowSkinChatMin())

            window:setHasCursor(false) -- hide cursor

            --  DCS.banMouse(false)
        end
        
        if rolexOverlay.config.mode == _modes.full then
            box:setSkin(skinModeFull)

            box:setVisible(true)
           -- pDown:setVisible(true)

            window:setSkin(Skin.windowSkinChatWrite())

            window:setHasCursor(true) -- show cursor
        end    
    end

    window:setVisible(true) -- if you make the window invisible, its destroyed
    rolexOverlay.saveConfiguration()
    rolexOverlay.paint()
end

function rolexOverlay.getMode()
    return rolexOverlay.config.mode
end

function rolexOverlay.onHotkey()
    if (rolexOverlay.getMode() == _modes.full) then
        rolexOverlay.setMode(_modes.minimum)
    elseif (rolexOverlay.getMode() == _modes.minimum) then
        --rolexOverlay.setMode(_modes.minimum_vol)
    --elseif (rolexOverlay.getMode() == _modes.minimum_vol) then
        rolexOverlay.setMode(_modes.hidden)
    else
        rolexOverlay.setMode(_modes.full)
    end 
end

function rolexOverlay.resize(w, h)
    window:setBounds(rolexOverlay.config.windowPosition.x, rolexOverlay.config.windowPosition.y, WIDTH, HEIGHT)
    box:setBounds(0, 0, WIDTH, HEIGHT)
end

function rolexOverlay.positionCallback()
    local x, y = window:getPosition()

    x = math.max(math.min(x, w-WIDTH), 0)
    y = math.max(math.min(y, h-HEIGHT), 0)

    window:setPosition(x, y)

    rolexOverlay.config.windowPosition = { x = x, y = y }
    rolexOverlay.saveConfiguration()
end

function rolexOverlay.onSimulationFrame()

    if not base.OptionsData then
        --rolexOverlay.log("NO Options Data")
        return
    end

    if rolexOverlay.config == nil then
        rolexOverlay.loadConfiguration()
    end

    if not window then

        if _isWindowCreated == false then
            rolexOverlay.createWindow()
        end
    else
        rolexOverlay.paint()
    end  

	-- this could be placed somewhere :smarter"
	if missionStartTime >= 0 and isInMission == true then -- 86399 is the max time
		dcsLocalTime = formatTime(missionStartTime + DCS.getModelTime())
		
		-- compute UTC time 
		--[[ Version 2 of getting the map name and timezone
		local mapName = Terrain.GetTerrainConfig("id") -- gets the map name
		local SummerTimeDelta = Terrain.GetTerrainConfig('SummerTimeDelta') -- gets the map timezone. Caucasus is positive
		rolexOverlay.log('mapName: ' .. mapName)
		rolexOverlay.log('SummerTimeDelta: ' .. SummerTimeDelta)
		--]]
		
		--[[ Version 1 way of getting the map name
		local missiontheatre = {}
		missiontheatre = DCS.getCurrentMission()
		local mapName = missiontheatre.mission.theatre
		--print_message_to_user(mapName)
		--]]
		
		dcsUtcTime = formatTime(missionStartTime + DCS.getModelTime() + utcOffset)
	else -- not in a mission, so blank out the times
		dcsLocalTime = '--:--:--'
		dcsUtcTime = '--:--:--'
	end
end 

function rolexOverlay.onMissionLoadEnd()
	isInMission = true -- because the load is finished

	local missionStartInSeconds = {}
	missionStartInSeconds = DCS.getCurrentMission() -- reads the mission miz
	missionStartTime = missionStartInSeconds.mission.start_time -- gets the start time of the mission. 
	
	utcOffset = -1 * Terrain.GetTerrainConfig('SummerTimeDelta') * 3600 -- eg -1 * 4 * 3600 (for seconds to get hours)
end

function rolexOverlay.onSimulationStop()
	isInMission = false
	missionStartTime = -1 -- resets the logic
end

DCS.setUserCallbacks(rolexOverlay)

net.log("Loaded - DCS-ROLEX - Bailey: " .. version)