--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

net.register("sv_pfm_camera_mode")

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
		else physC:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK) end
	end

	local updatePos = packet:ReadBool()
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
	end
end)

--[[

	local packet = net.Packet()
	packet:WriteUInt8(camMode)
	local cam = game.get_render_scene_camera()
	if(cam ~= nil) then
		packet:WriteBool(true)
		packet:WriteVector(cam:GetEntity():GetPos())
		packet:WriteQuaternion(cam:GetEntity():GetRotation())
	else packet:WriteBool(false) end
	net.send(net.PROTOCOL_SLOW_RELIABLE,"sv_pfm_camera_mode",packet)
]]
