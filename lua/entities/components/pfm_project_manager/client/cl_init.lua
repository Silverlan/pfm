--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/pfm.lua")
include("/pfm/project_manager.lua")

local Component = util.register_class("ents.PFMProjectManager", BaseEntityComponent)

Component:RegisterMember("ProjectFile", udm.TYPE_STRING, "", {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		c:UpdateProject()
	end,
	metaData = {
		rootPath = "projects/",
		extensions = pfm.Project.get_format_extensions(),
		stripExtension = true,
	},
})

Component:RegisterMember("TimeOffset", udm.TYPE_FLOAT, 0.0, {
	onChange = function(c)
		c:UpdateTimeOffset()
	end,
})

Component:RegisterMember("Looping", udm.TYPE_BOOLEAN, true, {}, "def+is")
Component:RegisterMember("Playing", udm.TYPE_BOOLEAN, false, {
	onChange = function(c)
		c:UpdatePlayCallback()
	end,
}, "def+is")
Component:RegisterMember("SceneCameraEnabled", udm.TYPE_BOOLEAN, false, {
	onChange = function(c)
		c:UpdateSceneCamera()
	end,
}, "def+is")

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_projectManager = pfm.ProjectManager()
	self.m_projectManager:OnInitialize()
end

function Component:OnEntitySpawn()
	self.m_initialGameCam = game.get_primary_camera()
	self:UpdateProject()
end

function Component:UpdateSceneCamera()
	if util.is_valid(self.m_initialGameCam) == false then
		return
	end
	if self:IsSceneCameraEnabled() then
		game.clear_gameplay_control_camera()
	else
		local cam = self.m_initialGameCam
		if cam ~= nil then
			game.set_gameplay_control_camera(cam)
		end
	end
end

function Component:UpdatePlayCallback()
	if self:IsPlaying() == false then
		util.remove(self.m_cbUpdate)
		return
	end
	if util.is_valid(self.m_cbUpdate) or util.is_valid(self.m_projectC) == false then
		return
	end
	self:UpdateSceneCamera()

	self.m_tCur = time.cur_time()
	self.m_cbUpdate = game.add_callback("Think", function()
		local t = time.cur_time()
		local dt = t - self.m_tCur
		local tNew = self:GetTimeOffset() + dt
		local timeFrame = self.m_projectC:GetTimeFrame()
		if self:IsLooping() then
			tNew = (self.m_duration > 0.0) and (tNew % self.m_duration) or 0.0
		end
		tNew = timeFrame:ClampToTimeFrame(tNew)
		self:SetTimeOffset(tNew)
		self.m_tCur = t
	end)
end

function Component:Start()
	self:SetPlaying(true)
end

function Component:Pause()
	self:SetPlaying(false)
end

function Component:UpdateTimeOffset()
	local t = self:GetTimeOffset()
	self.m_projectManager:SetTimeOffset(t)
end

function Component:GetDuration()
	return self.m_duration or 0.0
end

function Component:UpdateProject()
	if self:GetEntity():IsSpawned() == false then
		return
	end
	local projectFileName = self:GetProjectFile()
	if projectFileName == self.m_curProjectFileName then
		return
	end
	self:Clear()
	self.m_curProjectFileName = projectFileName
	local ignoreMap = true
	self.m_projectLoadResult = self.m_projectManager:LoadProject(self.m_curProjectFileName, ignoreMap)
	if self.m_projectLoadResult then
		self.m_projectC = self.m_projectManager:GetGameView():GetComponent(ents.COMPONENT_PFM_PROJECT)

		local timeFrame = self.m_projectC:GetTimeFrame()
		self.m_duration = timeFrame:GetDuration()
	end
	self:UpdatePlayCallback()
end

function Component:Clear()
	self.m_projectManager:ClearGameView()
	self.m_curProjectFileName = nil
	self.m_projectLoadResult = nil
	self.m_projectC = nil
	self.m_duration = nil
	util.remove(self.m_cbUpdate)
end

function Component:OnRemove()
	self:Clear()
	self.m_projectManager = nil
end
ents.register_component("pfm_project_manager", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
