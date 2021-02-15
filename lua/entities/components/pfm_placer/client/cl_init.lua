--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMPlacer",BaseEntityComponent)

function ents.PFMPlacer:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)

	self.m_gridSize = 1.0
	self.m_radius = 100.0
	self.m_shader = shader.get("pfm_grid_3d")
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.PFMPlacer:OnEntitySpawn()
	self.m_cbRender = game.add_callback("Render",function()
		self:Draw()
	end)
end

function ents.PFMPlacer:GetUp() return Vector(0,1,0) end

function ents.PFMPlacer:SnapToGrid(v)
	v:SnapToGrid(self:GetGridSize())
end

function ents.PFMPlacer:OnRemove()
	self.m_bReleased = true
	if(util.is_valid(self.m_cbRender)) then self.m_cbRender:Remove() end
end

function ents.PFMPlacer:SetRadius(radius)
	radius = math.clamp(radius,100.0,1000.0)
	self.m_radius = radius
end
function ents.PFMPlacer:GetRadius() return self.m_radius end

function ents.PFMPlacer:GetGridSize() return self.m_gridSize end
function ents.PFMPlacer:SetGridSize(size)
	size = math.clamp(size,1.0,512.0)
	self.m_gridSize = size
end

function ents.PFMPlacer:IncreaseSize()
	self:SetGridSize(math.get_next_power_of_2(self:GetGridSize()))
end

function ents.PFMPlacer:DecreaseSize()
	self:SetGridSize(math.get_previous_power_of_2(self:GetGridSize()))
end

function ents.PFMPlacer:Draw()
	if(self.m_shader == nil) then return end
	local origin = self:GetEntity():GetPos()
	
	local cam = game.get_render_scene_camera()
	local scene = game.get_render_scene()
	local radius = 500
	local spacing = self:GetGridSize()
	local gridOrigin = origin:Copy()
	gridOrigin:SnapToGrid(spacing)
	gridOrigin.y = origin.y
	
	local m = Mat4(1.0)
	m:Translate(gridOrigin)
	self.m_shader:Draw(game.get_draw_command_buffer(),origin,spacing,radius,scene,m)
end
ents.COMPONENT_PFM_PLACER = ents.register_component("pfm_placer",ents.PFMPlacer)
