--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/button.lua")

util.register_class("gui.PFMPlayButton",gui.Base)

gui.PFMPlayButton.STATE_INITIAL = 0
gui.PFMPlayButton.STATE_PLAYING = 1
gui.PFMPlayButton.STATE_PAUSED = 2
function gui.PFMPlayButton:__init()
	gui.Base.__init(self)
end
function gui.PFMPlayButton:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_state = gui.PFMPlayButton.STATE_INITIAL
	self.m_btPlay = gui.PFMButton.create(self,"gui/pfm/icon_cp_play","gui/pfm/icon_cp_play_activated",function()
		self:TogglePlay()
	end)
	self:GetSizeProperty():Link(self.m_btPlay:GetSizeProperty())
end
function gui.PFMPlayButton:OnRemove()
	if(util.is_valid(self.m_cbThink)) then self.m_cbThink:Remove() end
end
function gui.PFMPlayButton:SetActivated(activated)
	if(util.is_valid(self.m_btPlay) == false) then return end
	if(self:GetState() == gui.PFMPlayButton.STATE_PLAYING) then
		self.m_btPlay:SetMaterial(activated and "gui/pfm/icon_cp_pause_activated" or "gui/pfm/icon_cp_pause")
	else
		self.m_btPlay:SetMaterial(activated and "gui/pfm/icon_cp_play_activated" or "gui/pfm/icon_cp_play")
	end
end
function gui.PFMPlayButton:SetState(state)
	if(state == self:GetState()) then return end
	local oldState = self:GetState()
	self.m_state = state
	if(util.is_valid(self.m_cbThink)) then self.m_cbThink:Remove() end
	if(state == gui.PFMPlayButton.STATE_PLAYING) then
		local tStart = time.real_time()
		self.m_cbThink = game.add_callback("DrawFrame",function()
			if(self:IsPlaying() == false) then return end
			local dt = time.real_time() -tStart
			tStart = time.real_time()
			self:CallCallbacks("OnTimeAdvance",dt)
		end)
		if(util.is_valid(self.m_btPlay)) then
			self.m_btPlay:SetMaterials("gui/pfm/icon_cp_pause","gui/pfm/icon_cp_pause_activated")
		end
	elseif(state == gui.PFMPlayButton.STATE_PAUSED) then
		if(util.is_valid(self.m_btPlay)) then
			self.m_btPlay:SetMaterials("gui/pfm/icon_cp_play","gui/pfm/icon_cp_play_activated")
		end
	end
	self:CallCallbacks("OnStateChanged",oldState,state)
end
function gui.PFMPlayButton:GetState() return self.m_state end
function gui.PFMPlayButton:IsPlaying() return self.m_state == gui.PFMPlayButton.STATE_PLAYING end
function gui.PFMPlayButton:Play()
	local playButton = self.m_btPlay
	if(util.is_valid(playButton)) then playButton:SetMaterial("gui/pfm/icon_cp_pause") end
	self:SetState(gui.PFMPlayButton.STATE_PLAYING)
end
function gui.PFMPlayButton:Pause()
	local playButton = self.m_btPlay
	if(util.is_valid(playButton)) then playButton:SetMaterial("gui/pfm/icon_cp_play") end
	self:SetState(gui.PFMPlayButton.STATE_PAUSED)
end
function gui.PFMPlayButton:TogglePlay()
	if(self:IsPlaying()) then
		self:Pause()
		return
	end
	self:Play()
end
function gui.PFMPlayButton:Stop()
	self:Pause()
	self:SetOffset(0.0)
end
gui.register("WIPFMPlayButton",gui.PFMPlayButton)
