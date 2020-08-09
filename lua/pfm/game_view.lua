--[[
    Copyright (C) 2020  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}

util.register_class("pfm.GameView")
function pfm.GameView:__init()
end
function pfm.GameView:ClearGameView()
	if(util.is_valid(self.m_gameView)) then self.m_gameView:Remove() end
end
function pfm.GameView:StartGameView(project)
	self:ClearGameView()
	local entScene = ents.create("pfm_project")
	if(util.is_valid(entScene) == false) then
		pfm.log("Unable to initialize PFM project: Count not create 'pfm_project' entity!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return
	end

	local projectC = entScene:GetComponent(ents.COMPONENT_PFM_PROJECT)
	projectC:SetProjectData(project)
	entScene:Spawn()
	self.m_gameView = entScene
	projectC:Start()
	return entScene
end
function pfm.GameView:RefreshGameView()
	if(util.is_valid(self.m_gameView) == false) then return end
	local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
	if(projectC == nil) then return end
	projectC:Start()
	projectC:SetOffset(self:GetTimeOffset())
end
function pfm.GameView:SetGameViewOffset(offset,gameViewFlags)
	gameViewFlags = gameViewFlags or ents.PFMProject.GAME_VIEW_FLAG_NONE
	local projectC = self.m_gameView:GetComponent(ents.COMPONENT_PFM_PROJECT)
	if(projectC ~= nil) then projectC:SetOffset(offset,gameViewFlags) end
end
function pfm.GameView:GetGameView() return self.m_gameView end
