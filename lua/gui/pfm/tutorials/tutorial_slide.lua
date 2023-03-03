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
function Element:FindElementByPath(path)
	if(type(path) == "string") then path = util.Path.CreateFilePath(path) end
	local el = tool.get_filmmaker()
	local pathComponents = path:ToComponents()
	for _,c in ipairs(pathComponents) do
		local children = el:FindDescendantsByName(c)
		print(el,c)
		if(#children == 0) then return end
		el = children[1]
	end
	return el
end
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
function Element:AddMessageBox(msg)
	local elTgt = self.m_highlights[1]
	if(util.is_valid(elTgt) == false) then return end
	local elFocus = util.is_valid(self.m_elFocus) and self.m_elFocus or elTgt
	local overlay = gui.create("WIModalOverlay",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	
	local el = gui.create("WITransformable",self)
	el:SetDraggable(true)
	el:SetResizable(true)
	el:SetSize(400,128)
	el:SetMouseInputEnabled(true)
	el:GetDragArea():SetAutoAlignToParent(true)

	local elBox = gui.create_info_box(el,msg)
	elBox:SetAlpha(220)
	elBox:SetSize(el:GetSize())
	table.insert(self.m_messageBoxes,el)
	elBox:SizeToContents()
	elBox:Update()
	el:SetSize(elBox:GetSize())
	elBox:SetAnchor(0,0,1,1)

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
	return el
end
function Element:OnRemove()
end
gui.register("WITutorialSlide",Element)
