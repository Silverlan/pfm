-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMEditorActor", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:GetActor()
	return self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
end
ents.register_component("pfm_editor_actor", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
