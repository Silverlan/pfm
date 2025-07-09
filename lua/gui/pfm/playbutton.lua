-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/button.lua")

local Element = util.register_class("gui.PFMPlayButton", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_btPlay = gui.PFMButton.create(self, "play-fill", function()
		self:TogglePlay()
	end)
	self:GetSizeProperty():Link(self.m_btPlay:GetSizeProperty())
end
function Element:SetType(type)
	self.m_btPlay:SetType(type)
end
function Element:SetPlaybackState(playbackState)
	util.remove(self.m_cbOnStateChanged)
	self.m_cbOnStateChanged = playbackState:AddCallback("OnStateChanged", function(oldState, newState)
		if newState == pfm.util.PlaybackState.STATE_PLAYING then
			if util.is_valid(self.m_btPlay) then
				self.m_btPlay:SetIcon("pause-fill")
			end
		elseif newState == pfm.util.PlaybackState.STATE_PAUSED then
			if util.is_valid(self.m_btPlay) then
				self.m_btPlay:SetIcon("play-fill")
			end
		end
		self:CallCallbacks("OnStateChanged", oldState, newState)
	end)
	self.m_playbackState = playbackState
end
function Element:OnRemove()
	util.remove(self.m_cbOnStateChanged)
end
function Element:SetActivated(activated)
	if util.is_valid(self.m_btPlay) == false then
		return
	end
	if self:GetState() == pfm.util.PlaybackState.STATE_PLAYING then
		self.m_btPlay:SetIcon(activated and "pause-fill" or "pause-fill")
	else
		self.m_btPlay:SetIcon(activated and "play-fill" or "play-fill")
	end
end
function Element:GetState()
	return self.m_playbackState:GetState()
end
function Element:IsPlaying()
	return self.m_playbackState:IsPlaying()
end
function Element:Play()
	self.m_playbackState:Play()
end
function Element:Pause()
	self.m_playbackState:Pause()
end
function Element:TogglePlay()
	self.m_playbackState:TogglePlay()
end
function Element:Stop()
	self.m_playbackState:Stop()
end
gui.register("WIPFMPlayButton", Element)
