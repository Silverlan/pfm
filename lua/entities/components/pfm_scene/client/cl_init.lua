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
		c:LoadProject()
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
function Component:LoadProject()
	self:GetEntity():RemoveComponent("pfm_project")
	self.m_udmProject = nil

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
	local session = project:GetSession()
	if session ~= nil then
		ents.PFMProject.precache_session_assets(session)
	end
	self.m_udmProject = project

	if self:GetEntity():IsSpawned() then
		self:InitializeProject()
	end
end
function Component:GetProjectData()
	return self.m_udmProject
end
function Component:OnRemove()
	util.remove(self.m_entScene)
end
function Component:OnEntitySpawn()
	self:InitializeProject()
end
function Component:InitializeProject()
	local ent = self:GetEntity()
	if ent:IsSpawned() == false or self.m_udmProject == nil then
		return
	end

	local projectC = ent:AddComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:SetProjectData(self.m_udmProject)
	projectC:Start()
end
ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene", Component)
