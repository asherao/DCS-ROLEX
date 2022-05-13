status, result =  pcall(function() local dcsSr=require('lfs');dofile(dcsSr.writedir()..[[Mods\Services\DCS-ROLEX\Scripts\DCS-ROLEX-GUI.lua]]); end,nil) 
 if not status then
 	net.log(result)
 end