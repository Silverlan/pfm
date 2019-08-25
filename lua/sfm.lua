local r = engine.load_library("pr_dmx")
if(r ~= true) then
	print("WARNING: An error occured trying to load the 'pr_dmx' module: ",r)
	return
end

sfm = sfm or {}
include("sfm/scene.lua")

sfm.import_scene = function(fpath)
	local f = file.open(fpath,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return end
	local dmxData = dmx.load(f)
	f:Close()
	if(dmxData == false) then return end
	return sfm.Scene(dmxData)
end
