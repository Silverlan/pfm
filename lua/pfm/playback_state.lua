-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}
local PlaybackState = util.register_class("pfm.util.PlaybackState", util.CallbackHandler)
PlaybackState.STATE_INITIAL = 0
PlaybackState.STATE_PLAYING = 1
PlaybackState.STATE_PAUSED = 2
function PlaybackState:__init()
	util.CallbackHandler.__init(self)
	self.m_state = PlaybackState.STATE_INITIAL
	self:SetPlaybackSpeed(1.0)
end
function PlaybackState:__finalize()
	self:Reset()
end
function PlaybackState:Reset()
	if util.is_valid(self.m_cbThink) then
		self.m_cbThink:Remove()
	end
	self.m_cbThink = nil
	self.m_state = PlaybackState.STATE_INITIAL
end
function PlaybackState:GetPlaybackSpeed()
	return self.m_playbackSpeed
end
function PlaybackState:SetPlaybackSpeed(speed)
	self.m_playbackSpeed = speed
end
function PlaybackState:SetState(state)
	if state == self:GetState() then
		return
	end
	local oldState = self:GetState()
	self.m_state = state
	if util.is_valid(self.m_cbThink) then
		self.m_cbThink:Remove()
	end
	if state == PlaybackState.STATE_PLAYING then
		local tStart = time.cur_time()
		self.m_cbThink = game.add_callback("DrawFrame", function()
			if self:IsPlaying() == false then
				return
			end
			local dt = time.cur_time() - tStart
			tStart = time.cur_time()
			dt = dt * self:GetPlaybackSpeed()
			self:CallCallbacks("OnTimeAdvance", dt)
		end)
	end
	self:CallCallbacks("OnStateChanged", oldState, state)
end
function PlaybackState:GetState()
	return self.m_state
end
function PlaybackState:IsPlaying()
	return self.m_state == PlaybackState.STATE_PLAYING
end
function PlaybackState:Play()
	self:SetState(PlaybackState.STATE_PLAYING)
end
function PlaybackState:Pause()
	self:SetState(PlaybackState.STATE_PAUSED)
end
function PlaybackState:TogglePlay()
	if self:IsPlaying() then
		self:Pause()
		return
	end
	self:Play()
end
function PlaybackState:Stop()
	self:Pause()
end
