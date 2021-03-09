--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

net.register("sv_pfm_camera_mode")
net.register("sv_pfm_load_map")

local CAMERA_MODE_PLAYBACK = 0
local CAMERA_MODE_FLY = 1
local CAMERA_MODE_WALK = 2
net.receive("sv_pfm_camera_mode",function(packet,pl)
	local physC = util.is_valid(pl) and pl:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	local camMode = packet:ReadUInt8()
	if(physC ~= nil) then
		if(camMode == CAMERA_MODE_PLAYBACK or camMode == CAMERA_MODE_FLY) then
			physC:SetMoveType(ents.PhysicsComponent.MOVETYPE_NOCLIP)
			physC:SetCollisionFilterGroup(phys.COLLISIONMASK_NO_COLLISION)
		else
			physC:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK)
			physC:SetCollisionFilterGroup(phys.COLLISIONMASK_PLAYER)
		end
	end

	--[[local updatePos = packet:ReadBool()
	if(updatePos == true) then
		local pos = packet:ReadVector()
		local rot = packet:ReadQuaternion()
		local ang = rot:ToEulerAngles()
		ang.r = 0.0

		local ent = pl:GetEntity()
		local eyeOffset = Vector()
		local trC = ent:GetComponent(ents.COMPONENT_TRANSFORM)
		if(trC ~= nil) then eyeOffset = trC:GetEyeOffset() end
		pos = pos -eyeOffset -- TODO: Take player's up-direction into account
		ent:SetPos(pos)

		local charC = ent:GetComponent(ents.COMPONENT_CHARACTER)
		if(charC ~= nil) then charC:SetViewAngles(ang)
		else ent:SetAngles(ang) end
	end]]
end)

net.receive("sv_pfm_load_map",function(packet,pl)
	local mapName = packet:ReadString()
	game.load_map(mapName,Vector(0,0,0),true)
end)
