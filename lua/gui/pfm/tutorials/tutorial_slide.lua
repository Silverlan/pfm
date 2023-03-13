--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("element_connector_line.lua")
include("element_selection.lua")
include("modal_overlay.lua")

local Element = util.register_class("gui.TutorialSlide",gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)
	self.m_highlights = {}
	self.m_messageBoxes = {}
end
function Element:SetTutorial(t) self.m_tutorial = t end
function Element:FindElementByPath(path,baseElement)
	if(type(path) == "string") then path = util.Path.CreateFilePath(path) end
	local el = baseElement or tool.get_filmmaker()
	local pathComponents = path:ToComponents()
	for _,c in ipairs(pathComponents) do
		local children = el:FindDescendantsByName(c)
		print(el,c)
		if(#children == 0) then return end
		el = children[1]
	end
	return el
end
function Element:GetBackButton() return self.m_buttonPrev end
function Element:GetContinueButton() return self.m_buttonNext end
function Element:GetEndButton() return self.m_buttonEnd end
function Element:AddHighlight(el)
	if(util.is_valid(el) == false) then return end
	local elOutline = gui.create("WIElementSelectionOutline",self)
	elOutline:SetTargetElement(el)
	table.insert(self.m_highlights,el)
	return el
end
function Element:SetFocusElement(el)
	if(util.is_valid(el) == false) then return end
	self.m_elFocus = el
	local elOutline = gui.create("WIElementSelectionOutline",self)
	elOutline:SetTargetElement(el)
	elOutline:SetOutlineType(gui.ElementSelectionOutline.OUTLINE_TYPE_MINOR)
end
function Element:CreateButton(parent,text,f)
	local bt = gui.PFMButton.create(parent,"gui/pfm/icon_cp_generic_button_large","gui/pfm/icon_cp_generic_button_large_activated",function()
		f()
		return util.EVENT_REPLY_HANDLED
	end)
	bt:SetSize(100,32)
	bt:SetText(text)
	bt:SetZPos(1)
	return bt
end
function Element:AddMessageBox(msg)
	local elTgt
	if(#self.m_highlights > 1) then elTgt = self.m_elFocus end
	elTgt = elTgt or self.m_highlights[1] or self
	local elFocus = util.is_valid(self.m_elFocus) and self.m_elFocus or elTgt
	local overlay = gui.create("WIModalOverlay",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	
	local el = gui.create("WITransformable",self)
	el:SetDraggable(true)
	el:SetResizable(true)
	el:SetSize(400,128)
	el:SetMouseInputEnabled(true)
	el:GetDragArea():SetAutoAlignToParent(true)

	local vbox = gui.create("WIVBox",el)

	local elBox = gui.create_info_box(vbox,msg)
	elBox:SetAlpha(220)
	elBox:SetSize(el:GetSize())
	table.insert(self.m_messageBoxes,vbox)

	local buttonContainer = gui.create("WIBase",vbox)
	local hbox = gui.create("WIHBox",buttonContainer)
	self.m_buttonPrev = self:CreateButton(hbox,locale.get_text("pfm_go_back"),function() self.m_tutorial:PreviousSlide() end)
	self.m_buttonNext = self:CreateButton(hbox,locale.get_text("pfm_continue"),function() self.m_tutorial:NextSlide() end)
	self.m_buttonNext:SetEnabledColor(Color.Lime)
	self.m_buttonNext:SetDisabledColor(Color.Red)
	hbox:Update()
	self.m_buttonEnd = self:CreateButton(buttonContainer,locale.get_text("pfm_end_tutorial"),function() self.m_tutorial:EndTutorial() end)
	self.m_buttonEnd:SetX(elBox:GetWidth() -self.m_buttonEnd:GetWidth())
	buttonContainer:SizeToContents()

	elBox:SizeToContents()
	elBox:Update()
	vbox:Update()
	el:SetSize(vbox:GetSize())

	if(elTgt ~= self) then
		local l = gui.create("WIElementConnectorLine",self)
		l:SetSize(self:GetSize())
		l:SetAnchor(0,0,1,1)
		l:Setup(el,elTgt)

		local posAbs = elTgt:GetAbsolutePos()
		local posAbsEnd = posAbs +elTgt:GetSize()
		local spaceLeft = posAbs.x
		local spaceRight = self:GetWidth() -posAbsEnd.x
		local spaceUp = posAbs.y
		local spaceDown = self:GetHeight() -posAbsEnd.y

		local w = elBox:GetWidth()
		local h = elBox:GetHeight()

		local max = math.max(spaceLeft -w,spaceRight -w,spaceUp -h,spaceDown -h)
		local hw = el:GetHalfWidth()
		local hh = el:GetHalfHeight()
		if(spaceLeft -w >= max) then
			el:SetPos(spaceLeft *0.75 -hw,self:GetHeight() *0.25 -hh)
		elseif(spaceRight -w >= max) then
			el:SetPos(posAbsEnd.x +spaceRight *0.75 -hw,self:GetHeight() *0.25 -hh)
		elseif(spaceUp -h >= max) then
			el:SetPos(self:GetWidth() *0.25 -hw,spaceUp *0.75 -hh)
		elseif(spaceDown -h >= max) then
			el:SetPos(self:GetWidth() *0.25 -hw,posAbsEnd.y +spaceDown *0.75 -hh)
		end
		overlay:SetTarget(elFocus)
	else el:CenterToParent() end
	overlay:ScheduleUpdate()

	return el
end
function Element:OnRemove()
end
gui.register("WITutorialSlide",Element)
