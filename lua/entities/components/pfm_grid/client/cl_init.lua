--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_grid_3d.lua")

util.register_class("ents.PFMGrid",BaseEntityComponent)

ents.PFMGrid.GRID_UNIT_SIZE = bit.lshift(1,4)
ents.PFMGrid.GRID_RADIUS = 512.0
ents.PFMGrid.set_unit_size = function(gridSize)
	gridSize = math.clamp(gridSize,1.0,512.0)
	ents.PFMGrid.GRID_UNIT_SIZE = gridSize
end

ents.PFMGrid.get_unit_size = function() return ents.PFMGrid.GRID_UNIT_SIZE end
ents.PFMGrid.get_radius = function() return ents.PFMGrid.GRID_RADIUS end

ents.PFMGrid.set_radius = function(radius)
	radius = math.clamp(radius,100.0,1000.0)
	ents.PFMGrid.GRID_RADIUS = radius
end

ents.PFMGrid.increase_grid_size = function()
	ents.PFMGrid.set_unit_size(math.get_next_power_of_2(ents.PFMGrid.GRID_UNIT_SIZE))
end

ents.PFMGrid.decrease_grid_size = function()
	ents.PFMGrid.set_unit_size(math.get_previous_power_of_2(ents.PFMGrid.GRID_UNIT_SIZE))
end

ents.PFMGrid.snap_to_grid = function(v)
	v:SnapToGrid(ents.PFMGrid.GRID_UNIT_SIZE)
end

function ents.PFMGrid:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LOGIC)
	self:BindEvent(ents.LogicComponent.EVENT_ON_TICK,"OnTick")

	self.m_shader = shader.get("pfm_grid_3d")
end

function ents.PFMGrid:OnEntitySpawn()
	self.m_cbRender = game.add_callback("Render",function()
		self:Draw()
	end)
end

function ents.PFMGrid:GetUp() return Vector(0,1,0) end

function ents.PFMGrid:OnRemove()
	self.m_bReleased = true
	if(util.is_valid(self.m_cbRender)) then self.m_cbRender:Remove() end
end

function ents.PFMGrid:Draw()
	if(self.m_shader == nil) then return end
	local origin = self:GetEntity():GetPos()
	
	local cam = game.get_render_scene_camera()
	local scene = game.get_render_scene()
	local radius = ents.PFMGrid.GRID_RADIUS
	local spacing = ents.PFMGrid.GRID_UNIT_SIZE
	local gridOrigin = origin:Copy()
	gridOrigin:SnapToGrid(spacing)
	gridOrigin.y = origin.y
	
	local m = Mat4(1.0)
	m:Translate(gridOrigin)
	self.m_shader:Draw(game.get_draw_command_buffer(),origin,spacing,radius,scene,m)
end
ents.COMPONENT_PFM_GRID = ents.register_component("pfm_grid",ents.PFMGrid)
