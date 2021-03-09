--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("controls_menu.lua")
include("/gui/vr_player/video_player.lua")
include("/gui/vr_player/timeline.lua")
include("/gui/playbackcontrols.lua")

util.register_class("gui.PFMVideoPlayer",gui.Base)

function gui.PFMVideoPlayer:__init()
	gui.Base.__init(self)
end
function gui.PFMVideoPlayer:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,128)

	local contents = gui.create("WIBase",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)

	local playControls = gui.create("PlaybackControls",contents)

	local aspectRatioWrapper = gui.create("WIAspectRatio",contents)

	local timeline = gui.create("VRTimeline",contents)
	timeline:CenterToParentX()
	timeline:SetAnchor(0.5,1,0.5,1)
	timeline:AddCallback("OnTimeOffsetChanged",function(timeline,offset)
		local vp = self:GetVideoPlayerElement():GetVideoPlayer()
		if(vp ~= nil and vp:IsFileLoaded() and vp:IsPlaying() == false) then
			vp:Seek(offset)
		end
	end)
	self.m_timeline = timeline

	local player = gui.create("VRVideoPlayer",aspectRatioWrapper)
	player:LinkToControls(aspectRatioWrapper,timeline,playControls)
	self.m_videoPlayer = player
	
	playControls:CenterToParentX()
	playControls:SetY(contents:GetHeight() -playControls:GetHeight())
	playControls:SetAnchor(0.5,1,0.5,1)
	playControls:AddCallback("OnTimeAdvance",function(el,dt)
		--self:SetTimeOffset(self:GetTimeOffset() +dt)
	end)
	playControls:AddCallback("OnStateChanged",function(el,oldState,state)
		--[[ents.PFMSoundSource.set_audio_enabled(state == gui.PFMPlayButton.STATE_PLAYING)
		if(state == gui.PFMPlayButton.STATE_PAUSED) then
			self:ClampTimeOffsetToFrame()
		end]]
	end)
	self.m_playbackControls = playControls

	timeline:SetY(playControls:GetY() -timeline:GetHeight() -5)
	aspectRatioWrapper:SetWidth(contents:GetWidth())
	aspectRatioWrapper:SetHeight(timeline:GetY() -5)
	aspectRatioWrapper:SetAnchor(0,0,1,1)
end
function gui.PFMVideoPlayer:GetPlayControls() return self.m_playbackControls end
function gui.PFMVideoPlayer:GetVideoPlayerElement() return self.m_videoPlayer end
gui.register("WIPFMVideoPlayer",gui.PFMVideoPlayer)
