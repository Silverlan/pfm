-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.UnirenderComponent", BaseEntityComponent)

local Component = ents.UnirenderComponent
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnRemove() end
ents.register_component("unirender", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
Component.EVENT_INITIALIZE_SCENE = ents.register_component_event(ents.COMPONENT_UNIRENDER, "initialize_scene")
