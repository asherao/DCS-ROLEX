local DbOption  = require('Options.DbOption')
local i18n      = require('i18n')
local oms       = require('optionsModsScripts')
--local Range     = DbOption.Range -- allows scroll bars to be used

--these are saved in DCS\Config\options.lua by DCS itself

local colorOptions = {
					DbOption.Item(_('Green')):Value(0),
					DbOption.Item(_('Yellow')):Value(1),
					DbOption.Item(_('Red')):Value(2),
					DbOption.Item(_('White')):Value(3),
					DbOption.Item(_('Blue')):Value(4),
					DbOption.Item(_('Magenta')):Value(5),
					DbOption.Item(_('Cyan')):Value(6),
					DbOption.Item(_('Orange')):Value(7),
					DbOption.Item(_('Black')):Value(8),
					}

return {

stopwatch = DbOption.new():setValue(true):checkbox(),
gameTime = DbOption.new():setValue(true):checkbox(),
realLocal = DbOption.new():setValue(true):checkbox(),
realZulu = DbOption.new():setValue(true):checkbox(),
gameLocal = DbOption.new():setValue(true):checkbox(),
gameZulu = DbOption.new():setValue(true):checkbox(),

stopwatchCautionMinutes = DbOption.new():setValue("2"):editbox(),
stopwatchWarningMinutes = DbOption.new():setValue("3"):editbox(),

gameTimeCautionMinutes = DbOption.new():setValue("4"):editbox(),
gameTimeWarningMinutes = DbOption.new():setValue("5"):editbox(),

stopwatchDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		
														
stopwatchCautionColor	= DbOption.new():setValue(1):combo(colorOptions),		

stopwatchWarningColor	= DbOption.new():setValue(2):combo(colorOptions),		
														
gameTimeDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		
														
gameTimeCautionColor	= DbOption.new():setValue(1):combo(colorOptions),		

gameTimeWarningColor	= DbOption.new():setValue(2):combo(colorOptions),		

totalGameTimeDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		
														
totalGameTimeCautionColor	= DbOption.new():setValue(1):combo(colorOptions),		

totalGameTimeWarningColor	= DbOption.new():setValue(2):combo(colorOptions),		

totalFlightTimeDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		
														
totalFlightTimeCautionColor	= DbOption.new():setValue(1):combo(colorOptions),		

totalFlightTimeWarningColor	= DbOption.new():setValue(2):combo(colorOptions),		

totalMissionTimeDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		
														
totalMissionTimeCautionColor	= DbOption.new():setValue(1):combo(colorOptions),		

totalMissionTimeWarningColor	= DbOption.new():setValue(2):combo(colorOptions),		

realLocalDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		

realZuluDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		

gameLocalDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),		

gameZuluDefaultColor	= DbOption.new():setValue(0):combo(colorOptions),											
}