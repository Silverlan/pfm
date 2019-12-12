--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("slider.lua")

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
		print("PRESS")
	end)
	self.m_btTools:SetX(self:GetWidth() -self.m_btTools:GetWidth())

	self.m_contents = gui.create("WIHBox",self,
		0,self.m_btTools:GetBottom(),self:GetWidth(),self:GetHeight() -self.m_btTools:GetBottom(),
		0,0,1,1
	)
	self.m_contents:SetAutoFillContents(true)

	local treeVBox = gui.create("WIScrollContainer",self.m_contents,0,0,64,128)
	--treeVBox:SetFixedSize(true)
	--[[local bg = gui.create("WIRect",treeVBox,0,0,treeVBox:GetWidth(),treeVBox:GetHeight(),0,0,1,1)
	bg:SetColor(Color(38,38,38))
	treeVBox:SetBackgroundElement(bg)]]

	local resizer = gui.create("WIResizer",self.m_contents)
	local dataVBox = gui.create("WIVBox",self.m_contents)
	dataVBox:SetFixedSize(true)
	dataVBox:SetAutoFillContentsToWidth(true)
	self.m_sliderControlBox = dataVBox
	self.m_sliderControls = {}

	self.m_tree = gui.create("WITreeList",treeVBox,0,0,treeVBox:GetWidth(),treeVBox:GetHeight())
	self.m_tree:SetSelectableMode(gui.Table.SELECTABLE_MODE_MULTI)
	self.m_tree:SetAutoSizeToContents()
	--[[self.m_data = gui.create("WITable",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)

	self.m_data:SetRowHeight(self.m_tree:GetRowHeight())
	self.m_data:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)]]
end
function gui.PFMActorEditor:AddSliderControl(component,controlData)
	if(util.is_valid(self.m_sliderControlBox) == false) then return end
	local slider = gui.create("WIPFMSlider",self.m_sliderControlBox)
	slider:SetText(controlData.name)
	slider:SetRange(controlData.min,controlData.max,controlData.default)
	if(controlData.property ~= nil) then
		slider:SetValue(component:GetProperty(controlData.property):GetValue())
	elseif(controlData.get ~= nil and controlData.set ~= nil) then
		slider:SetValue(controlData.get(component))
	end
	table.insert(self.m_sliderControls,slider)
	return slider
end
function gui.PFMActorEditor:Setup(filmClip)
	self.m_tree:Clear()
	-- TODO: Include groups the actors belong to!
	for _,actor in ipairs(filmClip:GetActors():GetTable()) do
		local itemActor = self.m_tree:AddItem(actor:GetName())
		local itemComponents = itemActor:AddItem(locale.get_text("components"))
		for _,component in ipairs(actor:GetComponents():GetTable()) do
			local itemComponent = itemComponents:AddItem(component:GetName())
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
