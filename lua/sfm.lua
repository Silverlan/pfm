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

sfm.ASPECT_RATIO = 16.0 /9.0

sfm.source_units_to_pragma_units = function(units) return units end

-- TODO: Clean this code up
sfm.convert_source_position_to_pragma = function(pos)
	pos = Vector(pos.x,pos.z,-pos.y)
	pos:Rotate(EulerAngles(0,-90,0):ToQuaternion())
	return pos
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
	return sfm.convert_source_transform_rotation_to_pragma2(rot)
end

sfm.convert_source_transform_rotation_to_pragma2 = function(rot)
	return sfm.convert_source_transform_rotation_to_pragma(rot)
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

-- Constraint target offsets and rotation offsets are YET another special case.
sfm.convert_source_constraint_target_offset_to_pragma = function(pos)
	return Vector(pos.y,pos.z,pos.x)
end

sfm.convert_source_constraint_target_rotation_offset_to_pragma = function(rot)
	return sfm.convert_source_rotation_to_pragma(rot)
end

sfm.convert_source_fov_to_pragma = function(fov)
	-- The fov values specified in SFM sessions do not match expected
	-- horizontal/vertical/diagonal fov values or focus lengths.
	-- After some experimentation it has been determined that they can
	-- be translated to horizontal degree values by multiplying them
	-- by a factor of ~1.75, but I'm not sure why that is, or what
	-- they actually represent.
	-- The translation table below contains translation values that were determined by hand,
	-- they are not 100% accurate, but the result is close enough for most cases.
	local translationTable = {
		--[[{
			sfm = 7.5,
			deg = 5.0
		},
		{
			sfm = 15,
			deg = 10
		},
		{
			sfm = 22.8,
			deg = 15
		},
		{
			sfm = 30.5799999237,
			deg = 20
		},
		{
			sfm = 64.1999969482,
			deg = 40
		},
		{
			sfm = 116.0500030518,
			deg = 65
		},
		{
			sfm = 128.08,
			deg = 70
		},
		{
			sfm = 140.5,
			deg = 75
		}]]
		{
			sfm = 0.0,
			deg = 0.0
		},
		{
			sfm = 6.9600000381,
			deg = 9.25
		},
		{
			sfm = 14.8500003815,
			deg = 19.71
		},
		{
			sfm = 22.5799999237,
			deg = 29.82
		},
		{
			sfm = 30.0900001526,
			deg = 39.43
		},
		{
			sfm = 37.3129997253,
			deg = 48.485
		},
		{
			sfm = 44.2200012207,
			deg = 56.9
		},
		{
			sfm = 50.8,
			deg = 64.68
		},
		{
			sfm = 57,
			deg = 71.81
		},
		{
			sfm = 62.85,
			deg = 78.344
		},
		{
			sfm = 68.34,
			deg = 84.3
		},
		{
			sfm = 73.481,
			deg = 89.73
		},
		{
			sfm = 78.282,
			deg = 94.677
		},
		{
			sfm = 82.76,
			deg = 99.19
		},
		{
			sfm = 86.945,
			deg = 103.305
		},
		{
			sfm = 90.839,
			deg = 107.065
		},
		{
			sfm = 94.474,
			deg = 110.512
		},
		{
			sfm = 97.86,
			deg = 113.673
		},
		{
			sfm = 101.03,
			deg = 116.577
		},
		{
			sfm = 103.985,
			deg = 119.255
		},
		{
			sfm = 106.758,
			deg = 121.728
		},
		{
			sfm = 109.35,
			deg = 124.018
		},
		{
			sfm = 111.778,
			deg = 126.138
		},
		{
			sfm = 114.051,
			deg = 128.11
		},
		{
			sfm = 116.19,
			deg = 129.946
		},
		{
			sfm = 118.203,
			deg = 131.659
		},
		{
			sfm = 120.1,
			deg = 133.26
		},
		{
			sfm = 121.89,
			deg = 134.76
		},
		{
			sfm = 123.575,
			deg = 136.167
		},
		{
			sfm = 125.17,
			deg = 137.49
		},
		{
			sfm = 126.68,
			deg = 138.734
		},
		{
			sfm = 128.11,
			deg = 139.906
		},
		{
			sfm = 141.51,
			deg = 150.654
		},
		{
			sfm = 152.993,
			deg = 159.5805
		},

		{
			sfm = 180.0,
			deg = 180.0
		}
	}
	for i=1,#translationTable do
		translationTable[i].deg = math.deg(math.horizontal_fov_to_vertical_fov(math.rad(translationTable[i].deg),sfm.ASPECT_RATIO))
	end
	local i0
	local i1
	for i,t in ipairs(translationTable) do
		if(fov < t.sfm) then
			i0 = (i > 1) and (i -1) or 1
			i1 = i
			break
		end
	end
	i1 = i1 or #translationTable
	i0 = i0 or i1

	local t0 = translationTable[i0]
	local t1 = translationTable[i1]
	local interpFactor = (t1.sfm > t0.sfm) and ((fov -t0.sfm) /(t1.sfm -t0.sfm)) or 0.0
	return math.lerp(t0.deg,t1.deg,interpFactor)
end

sfm.convert_source_aperture_to_fstop = function(aperture)
	-- Source Engine depth of field values can't be directly translated to Pragma/Cycles values, so
	-- we'll use a translation table of manually determined values for the conversion.
	-- This may have to be tweaked in the future!
	local translationTable = {
		{
			sfmAperture = 0,
			fstop = 100
		},
		{
			sfmAperture = 1,
			fstop = 25
		},
		{
			sfmAperture = 3,
			fstop = 15
		},
		{
			sfmAperture = 5,
			fstop = 10
		},
		{
			sfmAperture = 10,
			fstop = 5
		},
		{
			sfmAperture = 20,
			fstop = 4
		},
		{
			sfmAperture = 30,
			fstop = 3
		},
		{
			sfmAperture = 50,
			fstop = 2
		},
		{
			sfmAperture = 100,
			fstop = 1
		},
		{
			sfmAperture = 1000,
			fstop = 0.1
		}
	}
	local i0
	local i1
	for i,t in ipairs(translationTable) do
		if(aperture < t.sfmAperture) then
			i0 = (i > 1) and (i -1) or 1
			i1 = i
			break
		end
	end
	i1 = i1 or #translationTable
	i0 = i0 or i1

	local t0 = translationTable[i0]
	local t1 = translationTable[i1]
	local interpFactor = (t1.sfmAperture > t0.sfmAperture) and ((aperture -t0.sfmAperture) /(t1.sfmAperture -t0.sfmAperture)) or 0.0
	return math.lerp(t0.fstop,t1.fstop,interpFactor)
end

include("sfm/project.lua")

sfm.import_scene = function(fpath)
	local f = file.open(fpath,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then f = file.open_external_asset_file("elements/sessions/" .. fpath) end
	if(f == nil) then
		pfm.log("Unable to import SFM project '" .. fpath .. "': File not found!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return
	end
	local dmxData = dmx.load(f)
	f:Close()
	if(dmxData == false) then return end
	return sfm.Project(dmxData)
end
