-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
		self:LogWarn("Unable to load project '" .. projectPath .. "': " .. (err or "Unknown error") .. "!")
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
	self.m_updatePlaybackOffset = nil
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
	pfm.clear_static_geometry_cache()
end
function Component:OnTick(dt)
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)

	if self.m_updatePlaybackOffset then
		-- This scene may be a child of another scene/project, in which case we'll
		-- link our playback offset to it.
		local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
		local projectCParent = (actorC ~= nil) and actorC:GetProject() or nil
		if util.is_valid(projectCParent) then
			util.remove(self.m_cbOnParentPlaybackOffsetChanged)
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
			local projectC = self:GetEntityComponent(ents.COMPONENT_PFM_PROJECT)
			if projectC ~= nil then
				projectC:ChangePlaybackOffset(projectCParent:GetPlaybackOffset())
			end
		end
	end
end
function Component:InitializeProject()
	local ent = self:GetEntity()
	if ent:IsSpawned() == false or self.m_udmProject == nil then
		return
	end

	local projectC = ent:AddComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:SetProjectData(self.m_udmProject)
	projectC:Start()

	-- Changing the playback offset immediately here may cause a crash for an unknown reason.
	-- We'll delay it to the next tick instead.
	self.m_updatePlaybackOffset = true
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
ents.register_component("pfm_scene", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
