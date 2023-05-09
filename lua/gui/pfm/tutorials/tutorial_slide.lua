--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("element_connector_line.lua")
include("element_selection.lua")
include("modal_overlay.lua")

local Element = util.register_class("gui.TutorialSlide", gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	self.m_highlights = {}
	self.m_messageBoxes = {}

	self.m_cbAudioEnabled = console.add_change_callback("pfm_tutorial_audio_enabled", function(old, new)
		self:UpdateAudio()
	end)
end
function Element:OnRemove()
	if self.m_sound ~= nil then
		self.m_sound:Stop()
	end
	util.remove(self.m_cbAudioEnabled)
end
function Element:SetTutorial(t)
	self.m_tutorial = t
end
function Element:FindPanelByWindow(identifier)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	return pm:GetWindowFrame(identifier)
end
function Element:FindElementByPath(path, baseElement)
	if type(path) == "string" then
		path = util.Path.CreateFilePath(path)
	end
	local root = baseElement or tool.get_filmmaker()
	local pathComponents = path:ToComponents()
	local function find_descendant(elBase)
		local el = elBase
		for _, c in ipairs(pathComponents) do
			local children = elBase:FindDescendantsByName(c)
			if #children == 0 then
				return false
			end
			el = children[1]
		end
		return el
	end
	local elChild = find_descendant(root)
	if elChild == false and baseElement == nil then
		for cat, frame in pairs(tool.get_filmmaker():GetFrames()) do
			for _, tabData in ipairs(frame:GetTabs()) do
				local window = frame:GetDetachedTabWindow(tabData.identifier)
				if util.is_valid(window) then
					local el = gui.get_base_element(window)
					if el ~= nil then
						elChild = find_descendant(el)
					end
				end
			end
		end
	end
	return elChild or root
end
function Element:GetBackButton()
	return self.m_buttonPrev
end
function Element:GetContinueButton()
	return self.m_buttonNext
end
function Element:GetEndButton()
	return self.m_buttonEnd
end
function Element:AddLocationMarker(pos)
	local ent = ents.create("env_particle_system")
	ent:SetKeyValue("loop", "0")
	ent:SetKeyValue("particle_file", "tutorial_viewport")
	ent:SetKeyValue("particle", "location_highlight")
	ent:SetKeyValue("transform_with_emitter", "0")
	ent:SetKeyValue("orientation_type", "3")
	ent:SetKeyValue("static_scale", "0.4")
	ent:Spawn()

	ent:SetPos(pos)
	ent:SetAngles(EulerAngles(-90, 0, 0))

	local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if ptC ~= nil then
		ptC:Start()
	end
	return ent
end
function Element:AddHighlight(el)
	local els = el
	if type(els) ~= "table" then
		els = { els }
	end
	if #els == 0 then
		return
	end
	local elFirst = els[1]
	if util.is_valid(elFirst) == false then
		return
	end
	local elOutline = gui.create("WIElementSelectionOutline", self)
	elOutline:SetTargetElement(els)
	elOutline:Update()
	table.insert(self.m_highlights, elOutline)
	return elFirst
end
function Element:SetFocusElement(el)
	if util.is_valid(el) == false then
		return
	end
	self.m_elFocus = el
	local elOutline = gui.create("WIElementSelectionOutline", self)
	elOutline:SetTargetElement(el)
	elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MINOR)
end
function Element:CreateButton(parent, text, f)
	local bt = gui.PFMButton.create(
		parent,
		"gui/pfm/icon_cp_generic_button_large",
		"gui/pfm/icon_cp_generic_button_large_activated",
		function()
			f()
			return util.EVENT_REPLY_HANDLED
		end
	)
	bt:SetSize(100, 32)
	bt:SetText(text)
	bt:SetZPos(1)
	return bt
end
function Element:AddMessageBox(msg, audioFile)
	local elTgt
	if #self.m_highlights > 1 then
		elTgt = self.m_elFocus
	end
	elTgt = elTgt or self.m_highlights[1] or self
	local elFocus = util.is_valid(self.m_elFocus) and self.m_elFocus or elTgt
	local overlay = gui.create("WIModalOverlay", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)

	local el = gui.create("WITransformable", self)
	el:SetDraggable(true)
	el:SetResizable(true)
	el:SetSize(400, 128)
	el:SetMouseInputEnabled(true)
	el:GetDragArea():SetAutoAlignToParent(true)

	local vbox = gui.create("WIVBox", el)

	local elBox = gui.create_info_box(vbox, msg)
	elBox:SetAlpha(220)
	elBox:SetSize(el:GetSize())
	table.insert(self.m_messageBoxes, vbox)

	local buttonContainer = gui.create("WIBase", vbox)
	local hbox = gui.create("WIHBox", buttonContainer)
	self.m_buttonPrev = self:CreateButton(hbox, locale.get_text("pfm_go_back"), function()
		self.m_tutorial:PreviousSlide()
	end)
	self.m_buttonNext = self:CreateButton(hbox, locale.get_text("pfm_continue"), function()
		self.m_tutorial:NextSlide()
	end)
	self.m_buttonNext:SetEnabledColor(Color.Lime)
	self.m_buttonNext:SetDisabledColor(Color.Red)
	hbox:Update()
	self.m_buttonEnd = self:CreateButton(buttonContainer, locale.get_text("pfm_end_tutorial"), function()
		self.m_tutorial:EndTutorial()
	end)
	self.m_buttonEnd:SetX(elBox:GetWidth() - self.m_buttonEnd:GetWidth())
	buttonContainer:SizeToContents()

	local hasAudio = (audioFile ~= nil and asset.exists(audioFile, asset.TYPE_AUDIO))
	if hasAudio then
		local iconAudio = gui.PFMButton.create(el, "gui/pfm/icon_mute", "gui/pfm/icon_mute_activated", function()
			self:ToggleAudio()
			return true
		end)
		iconAudio:SetSize(20, 20)
		iconAudio:SetPos(5, 0)
		self.m_iconAudio = iconAudio
	end

	elBox:SizeToContents()
	elBox:Update()
	vbox:Update()
	el:SetSize(vbox:GetSize())

	if elTgt ~= self then
		local l = gui.create("WIElementConnectorLine", self)
		l:SetSize(self:GetSize())
		l:SetAnchor(0, 0, 1, 1)
		l:Setup(el, elTgt)

		local posAbs = elTgt:GetAbsolutePos()
		local posAbsEnd = posAbs + elTgt:GetSize()
		local spaceLeft = posAbs.x
		local spaceRight = self:GetWidth() - posAbsEnd.x
		local spaceUp = posAbs.y
		local spaceDown = self:GetHeight() - posAbsEnd.y

		local w = elBox:GetWidth()
		local h = elBox:GetHeight()

		local max = math.max(spaceLeft - w, spaceRight - w, spaceUp - h, spaceDown - h)
		local hw = el:GetHalfWidth()
		local hh = el:GetHalfHeight()
		if spaceLeft - w >= max then
			el:SetPos(spaceLeft * 0.75 - hw, self:GetHeight() * 0.25 - hh)
		elseif spaceRight - w >= max then
			el:SetPos(posAbsEnd.x + spaceRight * 0.75 - hw, self:GetHeight() * 0.25 - hh)
		elseif spaceUp - h >= max then
			el:SetPos(self:GetWidth() * 0.25 - hw, spaceUp * 0.75 - hh)
		elseif spaceDown - h >= max then
			el:SetPos(self:GetWidth() * 0.25 - hw, posAbsEnd.y + spaceDown * 0.75 - hh)
		end
		overlay:SetTarget(elFocus)
	else
		el:CenterToParent()
	end
	overlay:ScheduleUpdate()

	if hasAudio then
		if self.m_sound ~= nil then
			self.m_sound:Stop()
		end
		self.m_sound = sound.create(audioFile, sound.TYPE_VOICE, 1.0, 1.0)
		self:UpdateAudio()
	end

	return el
end
function Element:IsAudioEnabled()
	return console.get_convar_bool("pfm_tutorial_audio_enabled")
end
function Element:UpdateAudio()
	local enabled = self:IsAudioEnabled()
	self.m_iconAudio:SetActivated(not enabled)

	if enabled == false then
		if self.m_sound ~= nil then
			self.m_sound:Stop()
		end
	else
		if self.m_sound ~= nil then
			self.m_sound:Play()
		end
	end
end
function Element:ToggleAudio()
	local enabled = not self:IsAudioEnabled()
	console.run("pfm_tutorial_audio_enabled", enabled and "1" or "0")
end
gui.register("WITutorialSlide", Element)
