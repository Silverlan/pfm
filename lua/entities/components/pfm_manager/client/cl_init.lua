--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("pfm_selection_wireframe")

local Component = util.register_class("ents.PFMManager",BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	local cursorTargetC = self:AddEntityComponent("pfm_cursor_target")
	cursorTargetC:AddEventCallback(ents.PFMCursorTarget.EVENT_ON_TARGET_CHANGED,function(...)
		self:OnCursorTargetChanged(...)
	end)
end
function Component:OnRemove()
end
function Component:AddOutline(ent)
	ent:AddComponent(ents.COMPONENT_PFM_SELECTION_WIREFRAME)
end
function Component:RemoveOutline(ent)
	ent:RemoveComponent(ents.COMPONENT_PFM_SELECTION_WIREFRAME)
end
function Component:OnCursorTargetChanged(hitData)
	if(util.is_valid(self.m_prevActor)) then
		local selC = self.m_prevActor:GetComponent(ents.COMPONENT_PFM_SELECTION_WIREFRAME)
		if(selC ~= nil and selC:IsPersistent() == false) then self:RemoveOutline(self.m_prevActor) end
	end
	if(util.is_valid(hitData.actor)) then
		self.m_prevActor = hitData.actor
		self:AddOutline(hitData.actor)
	end
	pfm.tag_render_scene_as_dirty()
end
ents.COMPONENT_PFM_MANAGER = ents.register_component("pfm_manager",Component)
