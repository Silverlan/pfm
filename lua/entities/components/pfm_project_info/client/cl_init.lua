--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMProjectInfo", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
ents.COMPONENT_PFM_PROJECT_INFO = ents.register_component("pfm_project_info", Component)
