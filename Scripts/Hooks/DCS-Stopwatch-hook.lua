status, result =  pcall(function() local dcsSr=require('lfs');dofile(dcsSr.writedir()..[[Mods\Tech\DCS-Stopwatch\Scripts\DCS-Stopwatch-OverlayGameGUI.lua]]); end,nil) 
 if not status then
 	net.log(result)
 end