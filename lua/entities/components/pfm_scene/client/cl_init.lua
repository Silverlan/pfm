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
Component:RegisterMember(
	"Scenebuild",
	udm.TYPE_BOOLEAN,
	false,
	{},
	bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER)
)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:LoadProject()
	self:Clear()

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
function Component:Clear()
	util.remove(self.m_entScene)
	self:GetEntity():RemoveComponent("pfm_project")
	util.remove(self.m_cbOnParentPlaybackOffsetChanged)
	self.m_udmProject = nil
end
function Component:OnRemove()
	self:Clear()
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

	-- This scene may be a child of another scene/project, in which case we'll
	-- link our playback offset to it.
	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	local projectCParent = (actorC ~= nil) and actorC:GetProject() or nil
	if util.is_valid(projectCParent) then
		self.m_cbOnParentPlaybackOffsetChanged = projectCParent:AddEventCallback(
			ents.PFMProject.EVENT_ON_PLAYBACK_OFFSET_CHANGED,
			function(offset)
				local projectC = self:GetEntityComponent(ents.COMPONENT_PFM_PROJECT)
				if projectC == nil then
					return
				end
				projectC:ChangePlaybackOffset(offset)
			end
		)
	end
end
ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene", Component)
