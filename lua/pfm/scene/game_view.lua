-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}

util.register_class("pfm.GameView")
function pfm.GameView:__init() end
function pfm.GameView:ClearGameView()
	if util.is_valid(self.m_gameView) then
		self.m_gameView:Remove()
	end
	self:OnGameViewCleared()
end
function pfm.GameView:StartGameView(project)
	self:ClearGameView()
	local entScene = ents.create("pfm_project")
	if util.is_valid(entScene) == false then
		pfm.log(
			"Unable to initialize PFM project: Count not create 'pfm_project' entity!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_ERROR
		)
		return
	end

	local projectC = entScene:GetComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:SetProjectData(project, self)
	entScene:Spawn()
	self.m_gameView = entScene
	self:OnGameViewCreated(projectC)
	projectC:Start()
	self:OnGameViewInitialized(projectC)
	return entScene
end
function pfm.GameView:ReloadGameView()
	if util.is_valid(self.m_gameView) == false then
		return
	end
	local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
	if projectC == nil then
		return
	end
	projectC:Start()
	projectC:SetPlaybackOffset(self:GetTimeOffset())

	self:OnGameViewReloaded()
end
function pfm.GameView:RefreshGameView()
	if util.is_valid(self.m_gameView) == false then
		return
	end
	local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
	if projectC == nil then
		return
	end
	projectC:SetPlaybackOffset(self:GetTimeOffset())

	self:OnGameViewReloaded()
end
function pfm.GameView:SetGameViewOffset(offset, gameViewFlags)
	gameViewFlags = gameViewFlags or ents.PFMProject.GAME_VIEW_FLAG_NONE
	local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
	if projectC ~= nil then
		projectC:ChangePlaybackOffset(offset, gameViewFlags)
	end
end
function pfm.GameView:GetGameView()
	return self.m_gameView
end

-- These can be overriden by derived classes
function pfm.GameView:OnGameViewCreated(projectC) end
function pfm.GameView:OnGameViewInitialized(projectC) end
function pfm.GameView:OnGameViewCleared() end
function pfm.GameView:OnGameViewReloaded() end
