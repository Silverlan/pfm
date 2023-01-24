--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMTransformGizmo",BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("util_transform")

	self:BindEvent(ents.UtilTransformComponent.EVENT_ON_GIZMO_CONTROL_ADDED,"OnGizmoControlAdded")
end
function Component:OnGizmoControlAdded(entCtrl)
	local renderC = entCtrl:GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then renderC:AddToRenderGroup("pfm_editor_overlay") end
end
ents.COMPONENT_PFM_TRANSFORM_GIZMO = ents.register_component("pfm_transform_gizmo",Component)
