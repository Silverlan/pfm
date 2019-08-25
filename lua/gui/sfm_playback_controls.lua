sfm = sfm or {}
util.register_class("sfm.GUIPlaybackControls",gui.Base)

function sfm.GUIPlaybackControls:__init()
	gui.Base.__init(self)
	
	self.m_buttons = {}
end
function sfm.GUIPlaybackControls:OnInitialize()
	gui.Base.OnInitialize(self)
	
	local buttonFirstFrame = self:CreateButton()
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
	end)

	self:SizeToContents()
	print(self:GetSize())
end
function sfm.GUIPlaybackControls:CreateButton()
	local x = 0
	local buttonPrev = self.m_buttons[#self.m_buttons]
	if(util.is_valid(buttonPrev)) then x = buttonPrev:GetRight() end
	local button = gui.create_button("",self)
	button:SetX(x)
	table.insert(self.m_buttons,button)
	return button
end
function sfm.GUIPlaybackControls:MoveToFirstFrame()
	print("MoveToFirstFrame")
end
function sfm.GUIPlaybackControls:MoveToPreviousClip()
	print("MoveToPreviousClip")
end
function sfm.GUIPlaybackControls:MoveToPreviousFrame()
	print("MoveToPreviousFrame")
end
function sfm.GUIPlaybackControls:Record()
	print("Record")
end
function sfm.GUIPlaybackControls:Play()
	print("Play")
end
function sfm.GUIPlaybackControls:MoveToNextFrame()
	print("MoveToNextFrame")
end
function sfm.GUIPlaybackControls:MoveToNextClip()
	print("MoveToNextClip")
end
function sfm.GUIPlaybackControls:MoveToLastFrame()
	print("MoveToLastFrame")
end
gui.register("SFMPlaybackControls",sfm.GUIPlaybackControls)
