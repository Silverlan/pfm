--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local r = engine.load_library("pr_dmx")
if(r ~= true) then
	print("WARNING: An error occured trying to load the 'pr_dmx' module: ",r)
	return
end

sfm = sfm or {}

sfm.convert_source_position_to_pragma = function(pos)
	return Vector(pos.x,pos.z,-pos.y)
end

sfm.convert_source_rotation_to_pragma = function(rot)
	return Quaternion(rot.w,rot.x,-rot.z,rot.y)
end

sfm.convert_source_normal_to_pragma = function(n)
	return Vector(n.x,-n.z,n.y)
end

-- Note: For some reason animation set root bone positions require a different
-- conversion, I'm not sure why.
sfm.convert_source_anim_set_position_to_pragma = function(pos)
	return Vector(pos.x,-pos.z,pos.y)
end

sfm.convert_source_anim_set_rotation_to_pragma = function(rot)
	return sfm.convert_source_rotation_to_pragma(rot)
end

include("sfm/scene.lua")

sfm.import_scene = function(fpath)
	local f = file.open(fpath,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return end
	local dmxData = dmx.load(f)
	f:Close()
	if(dmxData == false) then return end
	return sfm.Scene(dmxData)
end
