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
	self.m_btTools:SetupContextMenu(function(pContext)
		pContext:AddItem(locale.get_text("pfm_create_new_actor"),function()
			local filmClip = self:GetFilmClip()
			if(filmClip == nil) then return end
			local actor = udm.PFMActor()
			local actorName = "actor"

			local actorIndex = 1
			while(filmClip:FindActor(actorName .. actorIndex) ~= nil) do actorIndex = actorIndex +1 end
			actor:ChangeName(actorName .. actorIndex)

			local pos = Vector()
			local rot = Quaternion()
			local cam = tool.get_filmmaker():GetActiveCamera()
			if(util.is_valid(cam)) then
				local entCam = cam:GetEntity()
				pos = entCam:GetPos() +entCam:GetForward() *100.0
				rot = EulerAngles(0,entCam:GetAngles().y,0):ToQuaternion()
			end
			local t = actor:GetTransform()
			t:SetPosition(pos)
			t:SetRotation(rot)

			filmClip:GetActors():PushBack(actor)
			self:AddActor(actor)
		end)
		--[[local history = self:GetHistory()
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
		end)]]
	end,true)

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

	local propertiesHBox = gui.create("WIHBox",dataVBox)
	propertiesHBox:SetAutoFillContents(true)
	self.m_propertiesHBox = propertiesHBox

	local propertiesLabelsVBox = gui.create("WIVBox",propertiesHBox)
	propertiesLabelsVBox:SetAutoFillContentsToWidth(true)
	self.m_propertiesLabelsVBox = propertiesLabelsVBox

	gui.create("WIResizer",propertiesHBox)

	local propertiesElementsVBox = gui.create("WIVBox",propertiesHBox)
	propertiesElementsVBox:SetAutoFillContentsToWidth(true)
	self.m_propertiesElementsVBox = propertiesElementsVBox

	gui.create("WIResizer",dataVBox)

	local animSetControlsVBox = gui.create("WIVBox",dataVBox)
	animSetControlsVBox:SetAutoFillContentsToWidth(true)
	self.m_animSetControlsVBox = animSetControlsVBox

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

	self.m_leftRightWeightSlider = gui.create("WIPFMWeightSlider",self.m_animSetControlsVBox)
	return slider
end
function gui.PFMActorEditor:AddSliderControl(component,controlData)
	if(util.is_valid(self.m_animSetControlsVBox) == false) then return end
	local slider = gui.create("WIPFMSlider",self.m_animSetControlsVBox)
	slider:SetText(controlData.name)
	slider:SetRange(controlData.min,controlData.max,controlData.default)
	local callbacks = {}
	if(controlData.type == "flexController") then
		if(controlData.dualChannel == true) then
			slider:GetLeftRightValueRatioProperty():Link(self.m_leftRightWeightSlider:GetFractionProperty())
		end
		if(controlData.property ~= nil) then
			slider:SetValue(component:GetProperty(controlData.property):GetValue())
		elseif(controlData.get ~= nil) then
			slider:SetValue(controlData.get(component))
			if(controlData.getProperty ~= nil) then
				local prop = controlData.getProperty(component)
				if(prop ~= nil) then
					local cb = prop:AddChangeListener(function(newValue)
						slider:SetValue(newValue)
					end)
					table.insert(callbacks,cb)
				end
			end
		elseif(controlData.dualChannel == true) then
			if(controlData.getLeft ~= nil) then
				slider:SetLeftValue(controlData.getLeft(component))
				if(controlData.getLeftProperty ~= nil) then
					local prop = controlData.getLeftProperty(component)
					if(prop ~= nil) then
						local cb = prop:AddChangeListener(function(newValue)
							slider:SetLeftValue(newValue)
						end)
						table.insert(callbacks,cb)
					end
				end
			end
			if(controlData.getRight ~= nil) then
				slider:SetRightValue(controlData.getRight(component))
				if(controlData.getRightProperty ~= nil) then
					local prop = controlData.getRightProperty(component)
					if(prop ~= nil) then
						local cb = prop:AddChangeListener(function(newValue)
							slider:SetRightValue(newValue)
						end)
						table.insert(callbacks,cb)
					end
				end
			end
		end
	end
	if(#callbacks > 0) then
		slider:AddCallback("OnRemove",function()
			for _,cb in ipairs(callbacks) do
				if(cb:IsValid()) then cb:Remove() end
			end
		end)
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

	--[[

	local channelTrackGroup = (filmClip ~= nil) and filmClip:GetChannelTrackGroup() or nil
	local track = (channelTrackGroup ~= nil) and channelTrackGroup:GetTracks():Get(1) or nil
	if(track ~= nil) then
		local channelClips = track:GetChannelClips()
		for _,channelClip in ipairs(track:GetChannelClips():GetTable()) do
			for _,channel in ipairs(channelClip:GetClips():GetTable()) do
				local toElement = channel:GetToElement()

			end
		end
		-- TODO: Get channel clip? How?
		-- TODO: Get actor? How?
		-- Iterate channel clips
		-- Iterate channels
		-- ToElement
		-- -> Flex?

		local actorData = self.m_treeElementToActor[el]
		local ent = actorData:FindEntity()
		local graphEditor = tool.get_filmmaker():GetViewport():GetGraphEditor()
		graphEditor:Setup(actor,channelClip)
	end]]
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
function gui.PFMActorEditor:GetFilmClip() return self.m_filmClip end
function gui.PFMActorEditor:SelectActor(actor)
	if(util.is_valid(self.m_tree)) then self.m_tree:DeselectAll() end
	for itemActor,actorOther in pairs(self.m_treeElementToActor) do
		if(util.is_same_object(actor,actorOther)) then
			if(itemActor:IsValid()) then itemActor:Select() end
			break
		end
	end
end
function gui.PFMActorEditor:AddActorComponent(itemActor,itemComponents,component)
	local itemComponent = itemComponents:AddItem(component:GetName())
	if(component.GetIconMaterial) then
		itemComponent:AddIcon(component:GetIconMaterial())
		itemActor:AddIcon(component:GetIconMaterial())
	end
	if(component.SetupControls) then
		component:SetupControls(self,itemComponent)
	end
end
function gui.PFMActorEditor:AddActor(actor)
	local itemActor = self.m_tree:AddItem(actor:GetName())
	self.m_treeElementToActor[itemActor] = actor
	local itemComponents = itemActor:AddItem(locale.get_text("components"))
	itemComponents:AddCallback("OnMouseEvent",function(tex,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())
			local pComponentsItem,pComponentsMenu = pContext:AddSubMenu(locale.get_text("pfm_add_component"))
			local components = {"PFMModel","PFMSpotLight","PFMParticleSystem","PFMCamera","PFMAnimationSet"} -- TODO: Retrieve these automatically
			for _,componentType in ipairs(components) do
				-- TODO: Only show in list if actor doesn't already have this component!
				pComponentsMenu:AddItem(locale.get_text("pfm_add_component_type",{componentType}),function()
					local component = udm[componentType]()

					local componentName = component:GetComponentName() .. "_component"
					local componentIndex = 1
					while(actor:FindComponent(componentName .. componentIndex) ~= nil) do componentIndex = componentIndex +1 end
					component:ChangeName((componentIndex == 1) and componentName or (componentName .. componentIndex))

					actor:AddComponent(component)
					self:AddActorComponent(itemActor,itemComponents,component)
					itemComponents:Update()
				end)
			end
			pComponentsMenu:Update()
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end)
	for _,component in ipairs(actor:GetComponents():GetTable()) do
		self:AddActorComponent(itemActor,itemComponents,component)
	end
end
function gui.PFMActorEditor:Setup(filmClip)
	if(util.is_same_object(filmClip,self.m_filmClip)) then return end
	self.m_filmClip = filmClip
	self.m_tree:Clear()
	self.m_treeElementToActor = {}
	-- TODO: Include groups the actors belong to!
	for _,actor in ipairs(filmClip:GetActors():GetTable()) do
		self:AddActor(actor)
	end
end
function gui.PFMActorEditor:AddProperty(name,item,fInitPropertyEl)
	local child = item:AddItem(name)

	local elLabelContainer
	local elProperty
	local elHeight = 24
	child:AddCallback("OnSelected",function()
		elLabelContainer = gui.create("WIBase",self.m_propertiesLabelsVBox)
		elLabelContainer:SetHeight(elHeight)

		local elLabel = gui.create("WIText",elLabelContainer)
		elLabel:SetText(name)
		elLabel:SetColor(Color(200,200,200))
		elLabel:SetFont("pfm_medium")
		elLabel:SizeToContents()
		elLabel:CenterToParentY()
		elLabel:SetX(5)

		elProperty = fInitPropertyEl(self.m_propertiesElementsVBox)
		if(util.is_valid(elProperty)) then
			elProperty:SetHeight(elHeight)
		end
	end)
	child:AddCallback("OnDeselected",function()
		if(util.is_valid(elLabelContainer)) then elLabelContainer:Remove() end
		if(util.is_valid(elProperty)) then elProperty:Remove() end
	end)
end
function gui.PFMActorEditor:AddControl(component,item,controlData)
	local child = item:AddItem(controlData.name)

	local sliderControl
	local selectedCount = 0
	local fOnSelected = function()
		selectedCount = selectedCount +1
		if(selectedCount > 1 or util.is_valid(sliderControl)) then return end
		sliderControl = self:AddSliderControl(component,controlData)
		self:CallCallbacks("OnControlSelected",component,controlData,sliderControl)
	end
	local fOnDeselected = function()
		selectedCount = selectedCount -1
		if(selectedCount > 0) then return end
		self:CallCallbacks("OnControlDeselected",component,controlData,sliderControl)
		if(util.is_valid(sliderControl) == false) then return end
		sliderControl:Remove()
	end
	if(controlData.type == "bone") then
		local function add_item(parent,name)
			local item = parent:AddItem(name)
			item:AddCallback("OnSelected",fOnSelected)
			item:AddCallback("OnDeselected",fOnDeselected)
			return item
		end

		local childPos = child:AddItem("pos")
		add_item(childPos,"x")
		add_item(childPos,"y")
		add_item(childPos,"z")

		local childRot = child:AddItem("rot")
		add_item(childRot,"x")
		add_item(childRot,"y")
		add_item(childRot,"z")
	else
		child:AddCallback("OnSelected",fOnSelected)
		child:AddCallback("OnDeselected",fOnDeselected)
	end
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
