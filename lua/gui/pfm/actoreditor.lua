--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("slider.lua")
include("treeview.lua")
include("weightslider.lua")

util.register_class("gui.PFMActorEditor",gui.Base)

function gui.PFMActorEditor:__init()
	gui.Base.__init(self)
end
function gui.PFMActorEditor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.navBar = gui.create("WIHBox",self)
	self:InitializeNavigationBar()

	self.navBar:SetHeight(32)
	self.navBar:SetAnchor(0,0,1,0)

	self.m_btTools = gui.PFMButton.create(self,"gui/pfm/icon_gear","gui/pfm/icon_gear_activated",function()
		print("TODO")
	end)
	self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth())

	self.m_contents = gui.create("WIHBox",self,
		0,self.m_btTools:GetBottom(),self:GetWidth(),self:GetHeight() -self.m_btTools:GetBottom(),
		0,0,1,1
	)
	self.m_contents:SetAutoFillContents(true)

	local treeScrollContainerBg = gui.create("WIRect",self.m_contents,0,0,64,128)
	treeScrollContainerBg:SetColor(Color(38,38,38))
	local treeScrollContainer = gui.create("WIScrollContainer",treeScrollContainerBg,0,0,64,128,0,0,1,1)
	treeScrollContainerBg:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_tree)) then
			self.m_tree:SetWidth(el:GetWidth())
		end
	end)
	--treeScrollContainer:SetFixedSize(true)
	--[[local bg = gui.create("WIRect",treeScrollContainer,0,0,treeScrollContainer:GetWidth(),treeScrollContainer:GetHeight(),0,0,1,1)
	bg:SetColor(Color(38,38,38))
	treeScrollContainer:SetBackgroundElement(bg)]]


	local resizer = gui.create("WIResizer",self.m_contents)
	local dataVBox = gui.create("WIVBox",self.m_contents)
	dataVBox:SetFixedSize(true)
	dataVBox:SetAutoFillContentsToWidth(true)
	self.m_sliderControlBox = dataVBox
	self.m_sliderControls = {}

	self.m_tree = gui.create("WIPFMTreeView",treeScrollContainer,0,0,treeScrollContainer:GetWidth(),treeScrollContainer:GetHeight())
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)
	self.m_treeElementToActor = {}
	self.m_tree:AddCallback("OnItemSelectChanged",function(tree,el,selected)
		self:UpdateSelectedEntities()
	end)
	--[[self.m_data = gui.create("WITable",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)

	self.m_data:SetRowHeight(self.m_tree:GetRowHeight())
	self.m_data:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)]]

	self.m_leftRightWeightSlider = gui.create("WIPFMWeightSlider",self.m_sliderControlBox)
	return slider
end
function gui.PFMActorEditor:AddSliderControl(component,controlData)
	if(util.is_valid(self.m_sliderControlBox) == false) then return end
	local slider = gui.create("WIPFMSlider",self.m_sliderControlBox)
	slider:SetText(controlData.name)
	slider:SetRange(controlData.min,controlData.max,controlData.default)
	if(controlData.dualChannel == true) then
		slider:GetLeftRightValueRatioProperty():Link(self.m_leftRightWeightSlider:GetFractionProperty())
	end
	if(controlData.property ~= nil) then
		slider:SetValue(component:GetProperty(controlData.property):GetValue())
	elseif(controlData.get ~= nil) then
		slider:SetValue(controlData.get(component))
	elseif(controlData.dualChannel == true) then
		if(controlData.getLeft ~= nil) then
			slider:SetLeftValue(controlData.getLeft(component))
		end
		if(controlData.getRight ~= nil) then
			slider:SetRightValue(controlData.getRight(component))
		end
	end
	slider:AddCallback("OnLeftValueChanged",function(el,value)
		if(controlData.property ~= nil) then
			component:GetProperty(controlData.property):SetValue(value)
		elseif(controlData.set ~= nil) then
			controlData.set(component,value)
		elseif(controlData.setLeft ~= nil) then
			controlData.setLeft(component,value)
		end
	end)
	slider:AddCallback("OnRightValueChanged",function(el,value)
		if(controlData.setRight ~= nil) then
			controlData.setRight(component,value)
		end
	end)
	table.insert(self.m_sliderControls,slider)
	return slider
end
function gui.PFMActorEditor:UpdateSelectedEntities()
	if(util.is_valid(self.m_tree) == false) then return end
	local selectionManager = tool.get_filmmaker():GetSelectionManager()
	selectionManager:ClearSelections()
	local function iterate_tree(el,level)
		if(util.is_valid(el) == false) then return false end
		level = level or 0
		local selected = el:IsSelected()
		if(selected == false) then
			for _,item in ipairs(el:GetItems()) do
				selected = iterate_tree(item,level +1)
				if(selected == true and level > 0) then break end
			end
		end
		if(selected and level == 1) then
			-- Root element or one of its children is selected; Select entity associated with the actor
			local actorData = self.m_treeElementToActor[el]
			local ent = actorData:FindEntity()
			if(ent ~= nil) then
				selectionManager:Select(ent)
			end
		end
		return selected
	end
	iterate_tree(self.m_tree:GetRoot())
end
function gui.PFMActorEditor:Setup(filmClip)
	if(util.is_same_object(filmClip,self.m_filmClip)) then return end
	self.m_filmClip = filmClip
	self.m_tree:Clear()
	self.m_treeElementToActor = {}
	-- TODO: Include groups the actors belong to!
	for _,actor in ipairs(filmClip:GetActors():GetTable()) do
		local itemActor = self.m_tree:AddItem(actor:GetName())
		self.m_treeElementToActor[itemActor] = actor
		local itemComponents = itemActor:AddItem(locale.get_text("components"))
		for _,component in ipairs(actor:GetComponents():GetTable()) do
			local itemComponent = itemComponents:AddItem(component:GetName())
			if(component.GetIconMaterial) then
				itemComponent:AddIcon(component:GetIconMaterial())
				itemActor:AddIcon(component:GetIconMaterial())
			end
			if(component.SetupControls) then
				component:SetupControls(self,itemComponent)
			end
		end
	end
end
function gui.PFMActorEditor:AddControl(component,item,controlData)
	local child = item:AddItem(controlData.name)
	local sliderControl
	child:AddCallback("OnSelected",function()
		if(util.is_valid(sliderControl)) then return end
		sliderControl = self:AddSliderControl(component,controlData)
	end)
	child:AddCallback("OnDeselected",function()
		if(util.is_valid(sliderControl) == false) then return end
		sliderControl:Remove()
	end)
end
function gui.PFMActorEditor:InitializeNavigationBar()
	--[[self.m_btHome = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_home","gui/pfm/icon_nav_home_activated",function()
		if(self.m_rootNode == nil) then return end
		self:GetHistory():Clear()
		self:GetHistory():Add(self.m_rootNode)
	end)
	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btUp = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_up","gui/pfm/icon_nav_up_activated",function()
		print("TODO")
	end)
	self.m_btUp:SetupContextMenu(function(pContext)
		print("TODO")
	end)

	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btBack = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_back","gui/pfm/icon_nav_back_activated",function()
		self:GetHistory():GoBack()
	end)
	self.m_btBack:SetupContextMenu(function(pContext)
		local history = self:GetHistory()
		local pos = history:GetCurrentPosition()
		if(pos > 1) then
			for i=pos -1,1,-1 do
				local el = history:Get(i)
				pContext:AddItem(el:GetName(),function()
					history:SetCurrentPosition(i)
				end)
			end
		end
		pContext:AddLine()
		pContext:AddItem(locale.get_text("pfm_reset_history"),function()
			history:Clear()
		end)
	end)

	gui.create("WIBase",self.navBar):SetSize(5,1) -- Gap

	self.m_btForward = gui.PFMButton.create(self.navBar,"gui/pfm/icon_nav_forward","gui/pfm/icon_nav_forward_activated",function()
		self:GetHistory():GoForward()
	end)
	self.m_btForward:SetupContextMenu(function(pContext)
		local history = self:GetHistory()
		local pos = history:GetCurrentPosition()
		local numItems = #history
		if(pos < numItems) then
			for i=pos +1,numItems do
				local el = history:Get(i)
				pContext:AddItem(el:GetName(),function()
					history:SetCurrentPosition(i)
				end)
			end
		end
		pContext:AddLine()
		pContext:AddItem(locale.get_text("pfm_reset_history"),function()
			history:Clear()
		end)
	end)]]
end
gui.register("WIPFMActorEditor",gui.PFMActorEditor)
