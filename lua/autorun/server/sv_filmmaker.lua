--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

net.register("sv_pfm_camera_mode")

local CAMERA_MODE_PLAYBACK = 1
local CAMERA_MODE_FLY = 2
local CAMERA_MODE_WALK = 3
net.receive("sv_pfm_camera_mode",function(packet,pl)
	local physC = util.is_valid(pl) and pl:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if(physC == nil) then return end
	local camMode = packet:ReadUInt8()
	if(camMode == CAMERA_MODE_PLAYBACK or camMode == CAMERA_MODE_FLY) then physC:SetMoveType(ents.PhysicsComponent.MOVETYPE_NOCLIP)
	else physC:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK) end
end)
