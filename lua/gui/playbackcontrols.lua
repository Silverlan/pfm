--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PlaybackControls",gui.Base)
gui.PlaybackControls.BUTTON_FIRST_FRAME = 0
gui.PlaybackControls.BUTTON_PREVIOUS_CLIP = 1
gui.PlaybackControls.BUTTON_PREVIOUS_FRAME = 2
gui.PlaybackControls.BUTTON_RECORD = 3
gui.PlaybackControls.BUTTON_PLAY = 4
gui.PlaybackControls.BUTTON_PAUSE = 5
gui.PlaybackControls.BUTTON_NEXT_FRAME = 6
gui.PlaybackControls.BUTTON_NEXT_CLIP = 7
gui.PlaybackControls.BUTTON_LAST_FRAME = 8
function gui.PlaybackControls:__init()
	gui.Base.__init(self)
end
function gui.PlaybackControls:OnInitialize()
	gui.Base.OnInitialize(self)
	
	local controls = gui.create("WIHBox",self)

	self.m_btFirstFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_firstframe","gui/pfm/icon_cp_firstframe_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_FIRST_FRAME)
	end)
	self.m_btFirstFrame:SetTooltip(locale.get_text("pfm_playback_first_frame"))

	self.m_btPrevClip = gui.PFMButton.create(controls,"gui/pfm/icon_cp_prevclip","gui/pfm/icon_cp_prevclip_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_PREVIOUS_CLIP)
	end)
	self.m_btPrevClip:SetTooltip(locale.get_text("pfm_playback_previous_clip"))

	self.m_btPrevFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_prevframe","gui/pfm/icon_cp_prevframe_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_PREVIOUS_FRAME)
	end)
	self.m_btPrevFrame:SetTooltip(locale.get_text("pfm_playback_previous_frame"))

	self.m_btRecord = gui.PFMButton.create(controls,"gui/pfm/icon_cp_record","gui/pfm/icon_cp_record_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_RECORD)
	end)
	self.m_btRecord:SetTooltip(locale.get_text("pfm_playback_record"))

	self.m_btPlay = gui.create("WIPFMPlayButton",controls)
	self.m_btPlay:SetTooltip(locale.get_text("pfm_playback_play"))
	self.m_btPlay:AddCallback("OnStateChanged",function(btPlay,oldState,newState)
		if(newState == gui.PFMPlayButton.STATE_PLAYING) then self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_PLAY)
		elseif(newState == gui.PFMPlayButton.STATE_PAUSED) then self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_PAUSE) end
	end)
	self.m_btPlay:AddCallback("OnTimeAdvance",function(el,dt)
		self:CallCallbacks("OnTimeAdvance",dt)
	end)

	self.m_btNextFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_nextframe","gui/pfm/icon_cp_nextframe_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_NEXT_FRAME)
	end)
	self.m_btNextFrame:SetTooltip(locale.get_text("pfm_playback_next_frame"))

	self.m_btNextClip = gui.PFMButton.create(controls,"gui/pfm/icon_cp_nextclip","gui/pfm/icon_cp_nextclip_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_NEXT_CLIP)
	end)
	self.m_btNextClip:SetTooltip(locale.get_text("pfm_playback_next_clip"))

	self.m_btLastFrame = gui.PFMButton.create(controls,"gui/pfm/icon_cp_lastframe","gui/pfm/icon_cp_lastframe_activated",function()
		self:CallCallbacks("OnButtonPressed",gui.PlaybackControls.BUTTON_LAST_FRAME)
	end)
	self.m_btLastFrame:SetTooltip(locale.get_text("pfm_playback_last_frame"))

	controls:SetHeight(self.m_btFirstFrame:GetHeight())
	controls:Update()
	self.m_playControls = controls

	self:SizeToContents()
	return controls
end
function gui.PlaybackControls:GetPlayButton() return self.m_btPlay end
function gui.PlaybackControls:HandleKeyboardInput(key,state,mods)
	local bt
	if(key == input.KEY_SPACE) then bt = self.m_btPlay
	elseif(key == input.KEY_LEFT) then bt = self.m_btPrevFrame
	elseif(key == input.KEY_RIGHT) then bt = self.m_btNextFrame
	elseif(key == input.KEY_UP) then bt = self.m_btPrevClip
	elseif(key == input.KEY_DOWN) then bt = self.m_btNextClip
	elseif(key == input.KEY_HOME) then bt = self.m_btFirstFrame
	elseif(key == input.KEY_END) then bt = self.m_btLastFrame end
	if(util.is_valid(bt)) then
		bt:InjectMouseInput(Vector2(0,0),input.MOUSE_BUTTON_LEFT,state)
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PlaybackControls:LinkToPFMProject(projectManager)
	if(util.is_valid(self.m_cbButtonPressed)) then self.m_cbButtonPressed:Remove() end
	self.m_cbButtonPressed = self:AddCallback("OnButtonPressed",function(el,button)
		if(button == gui.PlaybackControls.BUTTON_FIRST_FRAME) then projectManager:GoToFirstFrame()
		elseif(button == gui.PlaybackControls.BUTTON_PREVIOUS_CLIP) then projectManager:GoToPreviousClip()
		elseif(button == gui.PlaybackControls.BUTTON_PREVIOUS_FRAME) then projectManager:GoToPreviousFrame()
		elseif(button == gui.PlaybackControls.BUTTON_RECORD) then -- TODO
		elseif(button == gui.PlaybackControls.BUTTON_NEXT_FRAME) then projectManager:GoToNextFrame()
		elseif(button == gui.PlaybackControls.BUTTON_NEXT_CLIP) then projectManager:GoToNextClip()
		elseif(button == gui.PlaybackControls.BUTTON_LAST_FRAME) then projectManager:GoToLastFrame() end
	end)
end

function gui.PlaybackControls:OnRemove()
end
gui.register("PlaybackControls",gui.PlaybackControls)
