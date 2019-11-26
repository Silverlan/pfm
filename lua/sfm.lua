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

sfm.source_units_to_pragma_units = function(units) return units end

sfm.convert_source_position_to_pragma = function(pos)
	return Vector(pos.x,pos.z,-pos.y)
end

sfm.convert_source_rotation_to_pragma = function(rot)
	return Quaternion(rot.w,rot.x,-rot.z,rot.y)
end

sfm.convert_source_normal_to_pragma = function(n)
	return Vector(n.x,-n.z,n.y)
end

-- Note: For some reason animation set positions require a different
-- conversion, I'm not sure why.
sfm.convert_source_anim_set_position_to_pragma = function(pos)
	return Vector(pos.x,-pos.z,pos.y)
end

sfm.convert_source_anim_set_rotation_to_pragma = function(rot)
	return sfm.convert_source_rotation_to_pragma(rot)
end

-- "transform" transforms (which specify the animation set's actual position/rotation) are another special case
sfm.convert_source_transform_position_to_pragma = function(pos)
	return sfm.convert_source_position_to_pragma(pos)
end

sfm.convert_source_transform_rotation_to_pragma = function(rot)
	rot = Quaternion(rot.w,rot.y,rot.z,rot.x)
	return rot
end

sfm.convert_source_transform_rotation_to_pragma_special = function(actor,rot)
	local specialActors = {
		["hat_kid_smug_dance_GameModel"] = true,
		["hat_kid_base_hat1"] = true,
		["skydome_realistic_v5_GameModel"] = true,
		["hat_kid_base_hat1"] = true,
		["hat_kid_smug_dance1"] = true,
		["bow_kid_GameModel"] = true,
		["mustache_girl_GameModel"] = true,
		["mafia_dude_GameModel"] = true,
		["mafia_dude2"] = true,
		["seal_GameModel"] = true,
		["captain_walrus_GameModel"] = true,
		["seal2"] = true,
		["snatcher_GameModel"] = true,
		["cuddle_team_leader_GameModel"] = true,
		["jonesy_GameModel"] = true
	}
	if(actor ~= nil) then
		if(actor:GetName() == "skydome_realistic_v5_GameModel") then return EulerAngles(180,0,0):ToQuaternion() *rot end
		if(specialActors[actor:GetName()] == true) then
			return sfm.convert_source_transform_rotation_to_pragma(rot)
		end
	end
	return sfm.convert_source_transform_rotation_to_pragma2(rot)
end

local rot90Yaw = EulerAngles(0,90,0):ToQuaternion()
sfm.convert_source_transform_rotation_to_pragma2 = function(rot)
	rot = rot90Yaw *Quaternion(rot.w,rot.y,rot.z,rot.x)
	return rot
end

-- root bones are yet another special case. Note that these assume that sfm.convert_source_position_to_pragma/sfm.convert_source_rotation_to_pragma have already been called
sfm.convert_source_root_bone_position_to_pragma = function(pos)
	return Vector(pos.x,-pos.y,-pos.z)
end

local rot180Pitch = EulerAngles(180,0,0):ToQuaternion()
sfm.convert_source_root_bone_rotation_to_pragma = function(rot)
	return rot180Pitch *rot
end

sfm.convert_source_global_rotation_to_pragma = function(rot)
	return Quaternion(rot.w,rot.x,rot.z,-rot.y)
end

include("sfm/project.lua")

sfm.import_scene = function(fpath)
	local f = file.open(fpath,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then return end
	local dmxData = dmx.load(f)
	f:Close()
	if(dmxData == false) then return end
	return sfm.Project(dmxData)
end
