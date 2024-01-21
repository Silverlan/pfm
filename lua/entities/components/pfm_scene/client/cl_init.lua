--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/pfm.lua")

local Component = util.register_class("ents.PFMScene", BaseEntityComponent)

Component:RegisterMember("Project", udm.TYPE_STRING, "", {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		c:UpdateProject()
	end,
	metaData = {
		rootPath = pfm.Project.get_project_root_path(),
		extensions = pfm.Project.get_format_extensions(),
		stripExtension = true,
	},
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("pfm_project")
end
function Component:OnRemove()
	util.remove(self.m_entScene)
end
function Component:OnEntitySpawn()
	self:UpdateProject()
end
function Component:UpdateProject()
	local ent = self:GetEntity()
	if ent:IsSpawned() == false then
		return
	end
	local projectPath = pfm.Project.get_full_project_file_name(self:GetProject(), true)
	local project, err = pfm.load_project(projectPath, true)
	if project == false then
		pfm.log(
			"Unable to load project '" .. projectPath .. "': " .. (err or "Unknown error") .. "!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end

	local projectC = ent:AddComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:SetProjectData(project)
	projectC:Start()
end
ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene", Component)
