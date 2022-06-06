--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_wireframe_line.lua")

local Component = util.register_class("ents.PFMSelectionWireframe",BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent("pfm_overlay_object")
	renderC:SetCastShadows(false)

	self.m_listeners = {}
end
function Component:OnRemove()
	util.remove(self.m_listeners)
end
function Component:OnEntitySpawn()
	self:GetEntity():SetModel("pfm/cube_wireframe")
end
function Component:SetDirty()
	self.m_isDirty = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:OnTick(dt)
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)
	if(self.m_isDirty ~= true) then return end
	self.m_isDirty = nil
	self:UpdateSelection()
	pfm.tag_render_scene_as_dirty()
end
function Component:GetTarget() return self.m_target end
function Component:SetTarget(ent)
	util.remove(self.m_listeners)
	self.m_listeners = {}

	self.m_target = ent
	if(util.is_valid(ent) == false) then return end
	local cb = ent:GetComponent(ents.COMPONENT_TRANSFORM):AddEventCallback(ents.TransformComponent.EVENT_ON_POSE_CHANGED,function()
		self:SetDirty()
	end)
	table.insert(self.m_listeners,cb)
	self:SetDirty()
end
function Component:UpdateSelection()
	local target = self:GetTarget()
	if(util.is_valid(target) == false) then return end
	local renderC = target:GetComponent(ents.COMPONENT_RENDER)
	if(renderC == nil) then return end
	local pose = target:GetPose()
	local min,max = renderC:GetLocalRenderBounds()
	local scale = max -min
	local offset = (max +min) /2.0
	pose:TranslateLocal(offset)
	self:GetEntity():SetPose(pose)
	self:GetEntity():SetScale(scale)
end
ents.COMPONENT_PFM_SELECTION_WIREFRAME = ents.register_component("pfm_selection_wireframe",Component)
