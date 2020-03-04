--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMGhost",BaseEntityComponent)

function ents.PFMGhost:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LOGIC)
	self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")
end

function ents.PFMGhost:OnTick()
	local filmmaker = tool.get_filmmaker()
	local viewport = filmmaker:GetViewport():GetViewport()

	local scene = game.get_render_scene()
	local cam = scene:GetActiveCamera()
	local res = Vector2(viewport:GetWidth(),viewport:GetHeight())
	local cursorPos = viewport:GetCursorPos()

	local dir = util.calc_world_direction_from_2d_coordinates(cam,res.x,res.y,Vector2(cursorPos.x /res.x,cursorPos.y /res.y))
	local entCam = cam:GetEntity()
	local pos = entCam:GetPos() +entCam:GetForward() *cam:GetNearZ()

	local pl = ents.get_local_player()
	local charComponent = (pl ~= nil) and pl:GetEntity():GetComponent(ents.COMPONENT_CHARACTER) or nil
	if(charComponent == nil) then return end
	local posDst = pos +dir *2048.0
	local rayData = charComponent:GetAimRayData(1200.0)
	rayData:SetSource(pos)
	rayData:SetTarget(posDst)
	local ray = phys.raycast(rayData)
	if(ray ~= false) then posDst = ray.position end
	local ent = self:GetEntity()
	ent:SetPos(posDst)
end

function ents.PFMGhost:OnEntitySpawn()
	self:GetEntity():SetModel("error.wmd") -- TODO
end
ents.COMPONENT_PFM_GHOST = ents.register_component("pfm_ghost",ents.PFMGhost)
