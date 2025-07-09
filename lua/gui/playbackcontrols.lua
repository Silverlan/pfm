-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("pfm/button.lua")

util.register_class("gui.PlaybackControls", gui.Base)
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

	local controls = gui.create("WIHBox", self)
	local btGroup = gui.PFMButtonGroup(controls)

	self.m_btFirstFrame = btGroup:AddIconButton("skip-backward-fill", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_FIRST_FRAME)
	end)
	self.m_btFirstFrame:SetTooltip(locale.get_text("pfm_playback_first_frame"))
	self.m_btFirstFrame:SetName("pc_first_frame")

	self.m_btPrevClip = btGroup:AddIconButton("chevron-compact-left", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_PREVIOUS_CLIP)
	end)
	self.m_btPrevClip:SetTooltip(locale.get_text("pfm_playback_previous_clip"))
	self.m_btPrevClip:SetName("pc_prev_clip")

	self.m_btPrevFrame = btGroup:AddIconButton("skip-start-fill", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_PREVIOUS_FRAME)
	end)
	self.m_btPrevFrame:SetTooltip(locale.get_text("pfm_playback_previous_frame"))
	self.m_btPrevFrame:SetName("pc_prev_frame")

	gui.create("WIBase", controls, 0, 0, 1, 1) -- Gap
	self.m_btRecord = btGroup:AddIconButton("record-fill", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_RECORD)
	end)
	self.m_btRecord:SetTooltip(locale.get_text("pfm_playback_record"))
	self.m_btRecord:SetName("pc_record")

	self.m_btPlay = gui.create("WIPFMPlayButton", controls)
	self.m_btPlay:SetTooltip(locale.get_text("pfm_playback_play"))
	self.m_btPlay:AddCallback("OnStateChanged", function(btPlay, oldState, newState)
		if newState == pfm.util.PlaybackState.STATE_PLAYING then
			self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_PLAY)
		elseif newState == pfm.util.PlaybackState.STATE_PAUSED then
			self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_PAUSE)
		end
	end)
	self.m_btPlay:SetName("pc_player")
	btGroup:AddButton(self.m_btPlay)

	self.m_btNextFrame = btGroup:AddIconButton("skip-end-fill", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_NEXT_FRAME)
	end)
	self.m_btNextFrame:SetTooltip(locale.get_text("pfm_playback_next_frame"))
	self.m_btNextFrame:SetName("pc_next_frame")

	self.m_btNextClip = btGroup:AddIconButton("chevron-compact-right", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_NEXT_CLIP)
	end)
	self.m_btNextClip:SetTooltip(locale.get_text("pfm_playback_next_clip"))
	self.m_btNextClip:SetName("pc_next_clip")

	self.m_btLastFrame = btGroup:AddIconButton("skip-forward-fill", function()
		self:CallCallbacks("OnButtonPressed", gui.PlaybackControls.BUTTON_LAST_FRAME)
	end)
	self.m_btLastFrame:SetTooltip(locale.get_text("pfm_playback_last_frame"))
	self.m_btLastFrame:SetName("pc_last_frame")

	controls:SetHeight(self.m_btFirstFrame:GetHeight())
	controls:Update()
	self.m_playControls = controls

	self:SizeToContents()
	return controls
end
function gui.PlaybackControls:GetPlayButton()
	return self.m_btPlay
end
function gui.PlaybackControls:HandleKeyboardInput(key, state, mods)
	if state ~= input.STATE_PRESS then
		return
	end
	local bt
	if key == input.KEY_SPACE then
		bt = self.m_btPlay
	elseif key == input.KEY_LEFT then
		bt = self.m_btPrevFrame
	elseif key == input.KEY_RIGHT then
		bt = self.m_btNextFrame
	elseif key == input.KEY_UP then
		bt = self.m_btPrevClip
	elseif key == input.KEY_DOWN then
		bt = self.m_btNextClip
	elseif key == input.KEY_HOME then
		bt = self.m_btFirstFrame
	elseif key == input.KEY_END then
		bt = self.m_btLastFrame
	end
	if util.is_valid(bt) then
		bt:InjectMouseClick(Vector2(0, 0), input.MOUSE_BUTTON_LEFT)
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PlaybackControls:LinkToPFMProject(projectManager)
	self.m_btPlay:SetPlaybackState(projectManager:GetPlaybackState())
	if util.is_valid(self.m_cbButtonPressed) then
		self.m_cbButtonPressed:Remove()
	end
	self.m_cbButtonPressed = self:AddCallback("OnButtonPressed", function(el, button)
		if button == gui.PlaybackControls.BUTTON_FIRST_FRAME then
			projectManager:GoToFirstFrame()
		elseif button == gui.PlaybackControls.BUTTON_PREVIOUS_CLIP then
			projectManager:GoToPreviousClip()
		elseif button == gui.PlaybackControls.BUTTON_PREVIOUS_FRAME then
			projectManager:GoToPreviousFrame()
		elseif button == gui.PlaybackControls.BUTTON_RECORD then
			projectManager:ToggleRecording()
		elseif button == gui.PlaybackControls.BUTTON_NEXT_FRAME then
			projectManager:GoToNextFrame()
		elseif button == gui.PlaybackControls.BUTTON_NEXT_CLIP then
			projectManager:GoToNextClip()
		elseif button == gui.PlaybackControls.BUTTON_LAST_FRAME then
			projectManager:GoToLastFrame()
		end
	end)
end

function gui.PlaybackControls:OnRemove() end
gui.register("PlaybackControls", gui.PlaybackControls)
