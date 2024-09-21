--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.UnirenderComponent", BaseEntityComponent)

local Component = ents.UnirenderComponent
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnRemove() end
ents.register_component("unirender", Component, "pfm")
Component.EVENT_INITIALIZE_SCENE = ents.register_component_event(ents.COMPONENT_UNIRENDER, "initialize_scene")
