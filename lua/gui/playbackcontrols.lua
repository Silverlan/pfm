--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PlaybackControls",gui.Base)

gui.PlaybackControls.STATE_INITIAL = 0
gui.PlaybackControls.STATE_PLAYING = 1
gui.PlaybackControls.STATE_PAUSED = 2
function gui.PlaybackControls:__init()
	gui.Base.__init(self)
end
function gui.PlaybackControls:OnInitialize()
	gui.Base.OnInitialize(self)
	
	self.m_buttons = {}
	self.m_state = gui.PlaybackControls.STATE_INITIAL
	--[[local buttonFirstFrame = self:CreateButton()
	buttonFirstFrame:SetText("<<")
	buttonFirstFrame:SetTooltip(locale.get_text("sfm_playback_first_frame") .. " (Home)")
	buttonFirstFrame:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:MoveToFirstFrame() end
	end)
	
	local buttonPrevClip = self:CreateButton()
	buttonPrevClip:SetText("[")
	buttonPrevClip:SetTooltip(locale.get_text("sfm_playback_previous_clip") .. " (Up)")
	buttonPrevClip:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:MoveToPreviousClip() end
	end)
	
	local buttonPrevFrame = self:CreateButton()
	buttonPrevFrame:SetText("|<")
	buttonPrevFrame:SetTooltip(locale.get_text("sfm_playback_previous_frame") .. " (Left)")
	buttonPrevFrame:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:MoveToPreviousFrame() end
	end)
	
	local buttonRecord = self:CreateButton()
	buttonRecord:SetText("o")
	buttonRecord:SetTooltip(locale.get_text("sfm_playback_record"))
	buttonRecord:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:Record() end
	end)
	
	local buttonPlay = self:CreateButton()
	buttonPlay:SetText(">")
	buttonPlay:SetTooltip(locale.get_text("sfm_playback_play") .. " (Space)")
	buttonPlay:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:Play() end
	end)
	
	local buttonNextFrame = self:CreateButton()
	buttonNextFrame:SetText(">|")
	buttonNextFrame:SetTooltip(locale.get_text("sfm_playback_next_frame") .. " (Right)")
	buttonNextFrame:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:MoveToNextFrame() end
	end)
	
	local buttonNextClip = self:CreateButton()
	buttonNextClip:SetText("]")
	buttonNextClip:SetTooltip(locale.get_text("sfm_playback_next_clip") .. " (Down)")
	buttonNextClip:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:MoveToNextClip() end
	end)
	
	local buttonLastFrame = self:CreateButton()
	buttonLastFrame:SetText(">>")
	buttonLastFrame:SetTooltip(locale.get_text("sfm_playback_last_frame") .. " (End)")
	buttonLastFrame:AddCallback("OnPressed",function()
		if(self:IsValid()) then self:MoveToLastFrame() end
	end)]]

	local playButton = gui.create("WITexturedRect",self)
	playButton:SetSize(24,24)
	playButton:SetMaterial("gui/pfm/playback/play")
	playButton:SetMouseInputEnabled(true)
	playButton:AddCallback("OnMousePressed",function()
		self:TogglePlay()
	end)
	self.m_playButton = playButton

	local progressBar = gui.create("WISlider",self)
	progressBar:SetSize(128,24)
	progressBar:SetLeft(playButton:GetRight() +5)
	progressBar:SetProgress(0.5)
	progressBar:AddCallback("TranslateValue",function()
		return self:GetFormattedTime(self.m_progressBar:GetValue())
	end)
	progressBar:AddCallback("OnChange",function(progressBar,progress,value)
		self:OnProgressChanged(progress,value)
	end)
	self.m_progressBar = progressBar

	self:SizeToContents()

	playButton:SetAnchor(0,0,0,1)
	progressBar:SetAnchor(0,0,1,1)
	self:SetDuration(60.0)
end
function gui.PlaybackControls:OnProgressChanged(progress,value)
	self:CallCallbacks("OnProgressChanged",progress,value)
end
function gui.PlaybackControls:GetProgressBar() return self.m_progressBar end
function gui.PlaybackControls:GetFormattedTime(t)
	if(util.is_valid(self.m_progressBar) == false) then return "00:00:00" end
	local seconds = math.floor(t)
	local minutes = math.floor(seconds /60.0)
	seconds = seconds %60.0

	local hours = math.floor(minutes /60.0)
	hours = hours %60.0

	return string.fill_zeroes(hours,2) .. ":" .. string.fill_zeroes(minutes,2) .. ":" .. string.fill_zeroes(seconds,2)
end
function gui.PlaybackControls:SetDuration(duration)
	if(util.is_valid(self.m_progressBar) == false) then return end
	self.m_progressBar:SetRange(0,0,0.01)
	self.m_progressBar:SetRange(0,duration,0.01)
end
function gui.PlaybackControls:GetDuration()
	if(util.is_valid(self.m_progressBar) == false) then return 0.0 end
	local min,max,stepSize = self.m_progressBar:GetRange()
	return max
end
function gui.PlaybackControls:OnRemove()
	if(util.is_valid(self.m_cbThink)) then self.m_cbThink:Remove() end
end
function gui.PlaybackControls:SetState(state)
	if(state == self:GetState()) then return end
	local oldState = self:GetState()
	self.m_state = state
	if(util.is_valid(self.m_cbThink)) then self.m_cbThink:Remove()
	elseif(state == gui.PlaybackControls.STATE_PLAYING) then
		self.m_cbThink = game.add_callback("Think",function()
			if(util.is_valid(self.m_progressBar) == false or self:IsPlaying() == false) then return end
			local dt = time.delta_time()
			self.m_progressBar:SetValue(self.m_progressBar:GetValue() +dt)
		end)
	end
	self:CallCallbacks("OnStateChanged",oldState,state)
end
function gui.PlaybackControls:GetState() return self.m_state end
function gui.PlaybackControls:IsPlaying() return self.m_state == gui.PlaybackControls.STATE_PLAYING end
function gui.PlaybackControls:Play()
	local playButton = self.m_playButton
	if(util.is_valid(playButton)) then playButton:SetMaterial("gui/pfm/playback/pause") end
	self:SetState(gui.PlaybackControls.STATE_PLAYING)
end
function gui.PlaybackControls:Pause()
	local playButton = self.m_playButton
	if(util.is_valid(playButton)) then playButton:SetMaterial("gui/pfm/playback/play") end
	self:SetState(gui.PlaybackControls.STATE_PAUSED)
end
function gui.PlaybackControls:TogglePlay()
	if(self:IsPlaying()) then
		self:Pause()
		return
	end
	self:Play()
end
function gui.PlaybackControls:Stop()
	self:Pause()
	self:SetOffset(0.0)
end
function gui.PlaybackControls:SetOffset(offset)
	if(util.is_valid(self.m_progressBar) == false) then return end
	self.m_progressBar:SetOffset(offset)
end
function gui.PlaybackControls:GetOffset()
	if(util.is_valid(self.m_progressBar) == false) then return 0.0 end
	return self.m_progressBar:GetOffset()
end
function gui.PlaybackControls:SetSecOffset(offset)
	if(util.is_valid(self.m_progressBar) == false) then return end
	self.m_progressBar:SetValue(offset)
end
function gui.PlaybackControls:GetSecOffset()
	if(util.is_valid(self.m_progressBar) == false) then return 0.0 end
	return self.m_progressBar:GetValue()
end
function gui.PlaybackControls:MoveToFirstFrame()
	print("MoveToFirstFrame")
end
function gui.PlaybackControls:MoveToPreviousClip()
	print("MoveToPreviousClip")
end
function gui.PlaybackControls:MoveToPreviousFrame()
	print("MoveToPreviousFrame")
end
function gui.PlaybackControls:Record()
	print("Record")
end
function gui.PlaybackControls:MoveToNextFrame()
	print("MoveToNextFrame")
end
function gui.PlaybackControls:MoveToNextClip()
	print("MoveToNextClip")
end
function gui.PlaybackControls:MoveToLastFrame()
	print("MoveToLastFrame")
end

function gui.PlaybackControls:CreateButton()
	local x = 0
	local buttonPrev = self.m_buttons[#self.m_buttons]
	if(util.is_valid(buttonPrev)) then x = buttonPrev:GetRight() end
	local button = gui.create_button("",self)
	button:SetX(x)
	table.insert(self.m_buttons,button)
	return button
end
gui.register("PlaybackControls",gui.PlaybackControls)
