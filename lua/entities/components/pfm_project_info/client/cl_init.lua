-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMProjectInfo", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
ents.register_component("pfm_project_info", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
