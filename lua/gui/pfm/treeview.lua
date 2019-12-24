--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/pfm/fonts.lua")

util.register_class("gui.PFMTreeView",gui.Base)

function gui.PFMTreeView:__init()
	gui.Base.__init(self)
end
function gui.PFMTreeView:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,19)
	self.m_rootElement = gui.create("WIPFMTreeViewElement",self)
	self.m_rootElement:SetName("root")
	self.m_rootElement:SetWidth(self:GetWidth())
	self.m_rootElement:SetText("ROOT")
	self.m_rootElement.m_treeView = self
	self.m_selectedElements = {}

	self:SetAutoSizeToContents(false,true)
	self:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)
	self:SetAutoSelectChildren(true)
end
function gui.PFMTreeView:GetItemHeight()
	return util.is_valid(self.m_rootElement) and self.m_rootElement:GetHeight() or 0
end
function gui.PFMTreeView:CollapseAll()
	if(util.is_valid(self.m_rootElement) == false) then return end
	self.m_rootElement:CollapseAll()
end
function gui.PFMTreeView:ExpandAll()
	if(util.is_valid(self.m_rootElement) == false) then return end
	self.m_rootElement:ExpandAll()
end
function gui.PFMTreeView:Clear()
	if(util.is_valid(self.m_rootElement) == false) then return end
	self.m_rootElement:Clear()
end
function gui.PFMTreeView:AddItem(text,fPopulate,insertIndex)
	if(util.is_valid(self.m_rootElement) == false) then return end
	return self.m_rootElement:AddItem(text,fPopulate,insertIndex)
end
function gui.PFMTreeView:OnElementSelectionChanged(elTgt,selected)
	if(selected) then
		table.insert(self.m_selectedElements,elTgt)
	else
		for i,el in ipairs(self.m_selectedElements) do
			if(el == elTgt) then
				table.remove(self.m_selectedElements,i)
				break
			end
		end
	end
	self:CallCallbacks("OnItemSelectChanged",el,selected)
end
function gui.PFMTreeView:SetAutoSelectChildren(autoSelected) self.m_autoSelectChildren = autoSelected end
function gui.PFMTreeView:ShouldAutoSelectChildren() return self.m_autoSelectChildren or false end
function gui.PFMTreeView:SetSelectable(selectableMode)
	self.m_selectableMode = selectableMode

	if(selectableMode == gui.Table.SELECTABLE_MODE_NONE) then self:DeselectAll()
	elseif(selectableMode == gui.Table.SELECTABLE_MODE_SINGLE) then
		local elSelected
		for _,el in ipairs(self.m_selectedElements) do
			if(el:IsValid()) then
				elSelected = el
				break
			end
		end
		self:DeselectAll()
		if(util.is_valid(elSelected)) then elSelected:Select() end
	end
end
function gui.PFMTreeView:IsSelectable() return self:GetSelectableMode() ~= gui.Table.SELECTABLE_MODE_NONE end
function gui.PFMTreeView:GetSelectableMode() return self.m_selectableMode end
function gui.PFMTreeView:DeselectAll()
	local selectedElements = self.m_selectedElements
	self.m_selectedElements = {}
	for _,el in ipairs(selectedElements) do
		if(el:IsValid()) then el:SetSelected(false) end
	end
end
function gui.PFMTreeView:OnSizeChanged(w,h)
	if(util.is_valid(self.m_rootElement) == false) then return end
	self.m_rootElement:SetWidth(w)
end
function gui.PFMTreeView:GetRoot() return self.m_rootElement end
gui.register("WIPFMTreeView",gui.PFMTreeView)

------------------------

util.register_class("gui.PFMTreeViewElement",gui.Base)

function gui.PFMTreeViewElement:__init()
	gui.Base.__init(self)
end
function gui.PFMTreeViewElement:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_items = {}
	self.m_itemElements = {}
	self:SetSize(64,19)

	self.m_vBox = gui.create("WIVBox",self,0,0,self:GetWidth(),self:GetHeight())
	self.m_vBox:SetAutoFillContentsToWidth(true)
	self.m_vBox:SetName("contents_wrapper")

	self.m_header = gui.create("WIHBox",self.m_vBox,0,0,self:GetWidth(),self:GetHeight())
	self.m_selection = gui.create("WIRect",self.m_header,0,0,self.m_header:GetWidth(),self.m_header:GetHeight(),0,0,1,1)
	self.m_selection:SetColor(Color(79,82,89))
	self.m_header:SetFixedWidth(true)
	self.m_header:SetFixedHeight(true)
	self.m_header:SetBackgroundElement(self.m_selection)
	self.m_header:SetName("header")
	self.m_header:AddCallback("OnDoubleClick",function(el)
		self:Toggle()
	end)

	self.m_iconBox = gui.create("WIHBox",self.m_header,0,0,0,14)
	self.m_iconBox:CenterToParentY()
	self.m_icons = {}

	gui.create("WIBase",self.m_header,0,0,3,1) -- gap

	self:SetMouseInputEnabled(true)
	self:SetAutoSizeToContents(false,true)
	self:SetSelected(false)
end
function gui.PFMTreeViewElement:MouseCallback(button,state,mods)
	if(button ~= input.MOUSE_BUTTON_LEFT or state ~= input.STATE_PRESS or self.m_header:IsValid() == false or self.m_header:IsCursorInBounds() == false) then return util.EVENT_REPLY_UNHANDLED end
	local treeView = self:GetTreeView()
	if(util.is_valid(treeView) == false or treeView:GetSelectableMode() == gui.Table.SELECTABLE_MODE_NONE) then return util.EVENT_REPLY_UNHANDLED end
	local isCtrlDown = input.get_key_state(input.KEY_LEFT_CONTROL) ~= input.STATE_RELEASE or
		input.get_key_state(input.KEY_RIGHT_CONTROL) ~= input.STATE_RELEASE
	if(treeView:GetSelectableMode() == gui.Table.SELECTABLE_MODE_SINGLE or isCtrlDown == false) then treeView:DeselectAll() end

	local select = true
	if(isCtrlDown) then select = not self:IsSelected() end

	self:SetSelected(select)
	return util.EVENT_REPLY_HANDLED
end
function gui.PFMTreeViewElement:IsRoot() return self:GetParentItem() == nil end
function gui.PFMTreeViewElement:RemoveItem(item) if(item:IsValid()) then item:Remove() end end
function gui.PFMTreeViewElement:AddIcon(material)
	local icon = gui.create("WITexturedRect",self.m_iconBox)
	icon:SetSize(14,14)
	icon:SetMaterial(material)
	table.insert(self.m_icons,icon)
	return icon
end
function gui.PFMTreeViewElement:GetHeader() return self.m_header end
function gui.PFMTreeViewElement:GetTreeView() return self.m_treeView end
function gui.PFMTreeViewElement:InitializeChildBox()
	if(util.is_valid(self.m_childHBox)) then return end
	self.m_childHBox = gui.create("WIHBox",self.m_vBox,0,0,self.m_vBox:GetWidth(),self.m_vBox:GetHeight())
	self.m_childHBox:SetFixedWidth(true)
	self.m_childHBox:SetAutoFillContentsToWidth(true)
	self.m_childHBox:SetName("child contents box with prefix")

	self.m_childPrefix = gui.create("WIBase",self.m_childHBox,0,0,18,self.m_childHBox:GetHeight())
	self.m_childPrefix:SetName("child prefix rect")

	self.m_vLine = gui.create("WIRect",self.m_childPrefix,0,0,1,1)
	self.m_vLine:SetColor(Color(58,58,58))
	self.m_vLine:SetName("child vertical line indicator")

	self.m_vBoxChildren = gui.create("WIVBox",self.m_childHBox,0,0,self:GetWidth(),self:GetHeight())
	self.m_vBoxChildren:SetAutoFillContentsToWidth(true)
	self.m_vBoxChildren:SetName("child contents box")

	if(self:IsCollapsed()) then self.m_childHBox:SetVisible(false) end
end
function gui.PFMTreeViewElement:OnSizeChanged(w,h)
	--print("OnSizeChanged...")
	if(util.is_valid(self.m_vBox)) then
		self.m_vBox:SetWidth(w)
		-- We need to update immediately to avoid some weird twitching effects
		self.m_vBox:Update()
	end
	self:ScheduleUpdate()
end
function gui.PFMTreeViewElement:OnUpdate()
	if(util.is_valid(self.m_vLine) == false) then return end
	if(self:IsRoot()) then
		if(util.is_valid(self.m_header)) then self.m_header:SetVisible(false) end
	end
	local lastItem = self.m_items[#self.m_items]
	if(util.is_valid(lastItem)) then
		local y = lastItem:GetY() +lastItem:GetHeader():GetCenterY()
		self.m_vLine:SetHeight(y +1)
		self.m_vLine:CenterToParentX()
	end

	for _,els in ipairs(self.m_itemElements) do
		local item = els[1]
		local line = els[2]
		local expandIcon = els[3]
		if(item:IsValid()) then
			local y = item:GetY() +item:GetHeader():GetCenterY()
			if(line:IsValid()) then
				line:SetX(self.m_vLine:GetX() +1)
				line:SetY(y)
			end
			if(#item:GetItems() > 0 or item.m_fPopulate ~= nil) then
				local expandIcon = self:InitializeExpandIcon(item)
				if(util.is_valid(expandIcon)) then
					expandIcon:SetX(self.m_vLine:GetX() -expandIcon:GetHalfWidth() +1)
					expandIcon:SetY(y -expandIcon:GetHalfHeight())
				end
			end
		end
	end

	self:UpdateChildBoxBounds()
	self:SizeToContents()
end
function gui.PFMTreeViewElement:InitializeExpandIcon(item)
	if(util.is_valid(item.m_expandIcon)) then return item.m_expandIcon end
	local expandIcon = gui.create("WIPFMTreeExpandIcon",self.m_childPrefix)
	expandIcon:SetColor(Color(80,80,80))
	expandIcon:AddCallback("OnExpand",function()
		if(item:IsValid() == false) then return end
		if(item.m_fPopulate) then item.m_fPopulate(item) end
		if(util.is_valid(item.m_childHBox)) then item.m_childHBox:SetVisible(true) end
		self:UpdateChildBoxBounds()
	end)
	expandIcon:AddCallback("OnCollapse",function()
		if(item:IsValid() == false) then return end
		if(item.m_fPopulate) then
			for _,child in ipairs(item:GetItems()) do
				if(child:IsValid()) then child:Remove() end
			end
		end
		if(util.is_valid(item.m_childHBox)) then item.m_childHBox:SetVisible(false) end
	end)
	item:RemoveElementOnRemoval(expandIcon)
	item.m_expandIcon = expandIcon
	expandIcon:Collapse()
	return item.m_expandIcon
end
function gui.PFMTreeViewElement:UpdateChildBoxBounds()
	local y = 0
	for _,els in ipairs(self:GetItems()) do
		if(els:IsValid() and els:IsVisible()) then
			y = math.max(y,els:GetBottom())
		end
	end
	self.m_childPrefix:SetHeight(y)

	local parent = self:GetParentItem()
	if(util.is_valid(parent)) then parent:UpdateChildBoxBounds() end
end
function gui.PFMTreeViewElement:GetParentItem() return self.m_parent end
function gui.PFMTreeViewElement:GetItems() return self.m_items end
function gui.PFMTreeViewElement:IsCollapsed() return util.is_valid(self.m_childHBox) == false or self.m_childHBox:IsVisible() == false end
function gui.PFMTreeViewElement:Toggle()
	if(self:IsCollapsed()) then self:Expand()
	else self:Collapse() end
end
function gui.PFMTreeViewElement:CollapseAll()
	self:Collapse()
	for _,item in ipairs(self:GetItems()) do
		if(item:IsValid()) then item:CollapseAll() end
	end
end
function gui.PFMTreeViewElement:ExpandAll()
	-- Don't expand if this element would expand dynamically, because this can potentially cause infinite recursions!
	if(self.m_fPopulate ~= nil) then return end
	self:Expand()
	for _,item in ipairs(self:GetItems()) do
		if(item:IsValid()) then item:ExpandAll() end
	end
end
function gui.PFMTreeViewElement:Collapse()
	if(self:IsRoot()) then return end -- Root item can never be collapsed
	if(util.is_valid(self.m_expandIcon)) then self.m_expandIcon:Collapse() end
end
function gui.PFMTreeViewElement:Expand()
	if(util.is_valid(self.m_expandIcon)) then self.m_expandIcon:Expand() end
end
function gui.PFMTreeViewElement:Clear()
	for _,item in ipairs(self.m_items) do
		if(item:IsValid()) then item:Remove() end
	end
	self.m_items = {}
	self.m_itemElements = {}
end
function gui.PFMTreeViewElement:SetText(text)
	if(util.is_valid(self.m_text) == false) then
		self.m_text = gui.create("WIText",self.m_header)
		self.m_text:SetColor(Color(200,200,200))
		self.m_text:SetFont("pfm_medium")
	end
	self.m_text:SetText(text)
	self.m_text:SizeToContents()
	self.m_text:CenterToParentY()

	self:SetName(text)
end
function gui.PFMTreeViewElement:IsSelected() return self.m_selected end
function gui.PFMTreeViewElement:Select() self:SetSelected(true) end
function gui.PFMTreeViewElement:Deselect() self:SetSelected(false) end
function gui.PFMTreeViewElement:SetSelected(selected)
	if(selected == self:IsSelected()) then return end
	self.m_selected = selected
	local treeView = self:GetTreeView()
	if(util.is_valid(treeView)) then
		treeView:OnElementSelectionChanged(self,selected)
	end
	if(util.is_valid(self.m_selection)) then self.m_selection:SetVisible(selected) end
	if(selected) then self:CallCallbacks("OnSelected")
	else self:CallCallbacks("OnDeselected") end

	local treeView = self:GetTreeView()
	if(selected == false or util.is_valid(treeView) == false or treeView:ShouldAutoSelectChildren() == false) then return end
	for _,item in ipairs(self:GetItems()) do
		if(item:IsValid()) then item:Select() end
	end
end
function gui.PFMTreeViewElement:AddItem(text,fPopulate,insertIndex)
	self:InitializeChildBox()
	local item = gui.create("WIPFMTreeViewElement")
	if(insertIndex == nil) then item:SetParent(self.m_vBoxChildren)
	else item:SetParent(self.m_vBoxChildren,insertIndex) end
	item:SetText(text)
	item.m_treeView = self.m_treeView
	item.m_fPopulate = fPopulate
	item.m_parent = self

	local hLine = gui.create("WIRect",self.m_childPrefix)
	hLine:SetSize(9,1)
	hLine:SetColor(Color(58,58,58))
	item:RemoveElementOnRemoval(hLine)

	if(insertIndex ~= nil) then
		table.insert(self.m_itemElements,insertIndex +1,{item,hLine})
		table.insert(self.m_items,insertIndex +1,item)
	else
		table.insert(self.m_itemElements,{item,hLine})
		table.insert(self.m_items,item)
	end
	self:ScheduleUpdate()
	return item
end
gui.register("WIPFMTreeViewElement",gui.PFMTreeViewElement)

------------------------

util.register_class("gui.PFMTreeExpandIcon",gui.Base)

function gui.PFMTreeExpandIcon:__init()
	gui.Base.__init(self)
end
function gui.PFMTreeExpandIcon:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(9,9)

	local texBg = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	texBg:SetMaterial("gui/pfm/circle_filled")
	texBg:SetColor(Color(38,38,38))

	local tex = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	tex:GetColorProperty():Link(self:GetColorProperty())
	self.m_tex = tex

	self:SetMouseInputEnabled(true)
	self:Expand()
end
function gui.PFMTreeExpandIcon:IsCollapsed() return self.m_collapsed end
function gui.PFMTreeExpandIcon:Expand()
	if(self:IsCollapsed() == false) then return end
	if(util.is_valid(self.m_tex)) then self.m_tex:SetMaterial("gui/pfm/tree_collapse") end
	self.m_collapsed = false
	self:CallCallbacks("OnExpand")
end
function gui.PFMTreeExpandIcon:Collapse()
	if(self:IsCollapsed()) then return end
	if(util.is_valid(self.m_tex)) then self.m_tex:SetMaterial("gui/pfm/tree_expand") end
	self.m_collapsed = true
	self:CallCallbacks("OnCollapse")
end
function gui.PFMTreeExpandIcon:Toggle()
	if(self:IsCollapsed()) then self:Expand()
	else self:Collapse() end
end
function gui.PFMTreeExpandIcon:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT and state == input.STATE_RELEASE) then
		self:Toggle()
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
gui.register("WIPFMTreeExpandIcon",gui.PFMTreeExpandIcon)
