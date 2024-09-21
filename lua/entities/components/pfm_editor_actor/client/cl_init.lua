--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMEditorActor", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:GetActor()
	return self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
end
ents.register_component("pfm_editor_actor", Component, "pfm")
