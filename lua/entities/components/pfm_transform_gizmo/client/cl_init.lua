-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMTransformGizmo", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("util_transform")

	self:BindEvent(ents.UtilTransformComponent.EVENT_ON_GIZMO_CONTROL_ADDED, "OnGizmoControlAdded")
end
function Component:OnGizmoControlAdded(entCtrl)
	local renderC = entCtrl:GetComponent(ents.COMPONENT_RENDER)
	if renderC ~= nil then
		renderC:AddToRenderGroup("pfm_editor_overlay")
	end
end
ents.register_component("pfm_transform_gizmo", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
