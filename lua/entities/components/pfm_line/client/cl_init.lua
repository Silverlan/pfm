-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMLine", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end

function Component:OnRemove()
end

function Component:OnEntitySpawn()
	local mdlC = self:GetEntity():AddComponent(ents.COMPONENT_MODEL)
	if mdlC == nil or mdlC:GetModel() ~= nil then
		return
	end

	self:GetEntity():SetModel("pfm/line")

	local renderC = self:GetEntity():AddComponent(ents.COMPONENT_RENDER)
	renderC:SetCastShadows(false)
	renderC:AddToRenderGroup("pfm_editor_overlay")
end
ents.register_component("pfm_line", Component, "editor")
