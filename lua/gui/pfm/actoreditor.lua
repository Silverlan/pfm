--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("slider.lua")
include("treeview.lua")
include("weightslider.lua")
include("controls_menu.lua")
include("/pfm/component_manager.lua")

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
			self:AddNewActor()
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_articulated_actor"),function()
			gui.open_model_dialog(function(dialogResult,mdlName)
				if(dialogResult ~= gui.DIALOG_RESULT_OK) then return end
				if(self:IsValid() == false) then return end
				local actor = self:CreateNewActor()
				if(actor == nil) then return end
				local mdlC = self:CreateNewActorComponent(actor,"PFMModel")
				self:CreateNewActorComponent(actor,"PFMAnimationSet",nil,function(mdlC) mdlC:ChangeModel(mdlName) end)

				self:AddActorToScene(actor)
			end)
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_prop"),function()
			gui.open_model_dialog(function(dialogResult,mdlName)
				if(dialogResult ~= gui.DIALOG_RESULT_OK) then return end
				if(self:IsValid() == false) then return end
				local actor = self:CreateNewActor()
				if(actor == nil) then return end
				local mdlC = self:CreateNewActorComponent(actor,"PFMModel",nil,function(mdlC) mdlC:ChangeModel(mdlName) end)

				self:AddActorToScene(actor)
			end)
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_camera"),function()
			local actor = self:CreateNewActor()
			if(actor == nil) then return end
			self:CreateNewActorComponent(actor,"PFMCamera")

			self:AddActorToScene(actor)
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_particle_system"),function()
			local actor = self:CreateNewActor()
			if(actor == nil) then return end
			self:CreateNewActorComponent(actor,"PFMParticleSystem")

			self:AddActorToScene(actor)
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_spot_light"),function()
			local actor = self:CreateNewActor()
			if(actor == nil) then return end
			self:CreateNewActorComponent(actor,"PFMSpotLight")

			self:AddActorToScene(actor)
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_point_light"),function()
			local actor = self:CreateNewActor()
			if(actor == nil) then return end
			self:CreateNewActorComponent(actor,"PFMPointLight")

			self:AddActorToScene(actor)
		end)
		pContext:AddItem(locale.get_text("pfm_create_new_directional_light"),function()
			local actor = self:CreateNewActor()
			if(actor == nil) then return end
			self:CreateNewActorComponent(actor,"PFMDirectionalLight")

			self:AddActorToScene(actor)
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

	local animSetControls = gui.create("WIPFMControlsMenu",dataVBox)
	animSetControls:SetAutoFillContentsToWidth(true)
	animSetControls:SetAutoFillContentsToHeight(false)
	animSetControls:SetFixedHeight(false)
	animSetControls:AddCallback("OnControlAdded",function(el,name,ctrl,wrapper)
		if(wrapper ~= nil) then
			wrapper:AddCallback("OnValueChanged",function()
				local filmmaker = tool.get_filmmaker()
				filmmaker:TagRenderSceneAsDirty()
			end)
		end
	end)
	self.m_animSetControls = animSetControls

	self.m_sliderControls = {}

	self.m_tree = gui.create("WIPFMTreeView",treeScrollContainer,0,0,treeScrollContainer:GetWidth(),treeScrollContainer:GetHeight())
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)
	self.m_treeElementToActorData = {}
	self.m_tree:AddCallback("OnItemSelectChanged",function(tree,el,selected)
		self:ScheduleUpdateSelectedEntities()
	end)
	--[[self.m_data = gui.create("WITable",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)

	self.m_data:SetRowHeight(self.m_tree:GetRowHeight())
	self.m_data:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)]]

	self.m_componentManager = pfm.ComponentManager()

	self.m_leftRightWeightSlider = gui.create("WIPFMWeightSlider",self.m_animSetControls)
	return slider
end
function gui.PFMActorEditor:GetTree() return self.m_tree end
function gui.PFMActorEditor:GetActorItem(actor)
	for item,actorData in pairs(self.m_treeElementToActorData) do
		if(util.is_same_object(actorData.actor,actor)) then return item end
	end
end
function gui.PFMActorEditor:GetActorComponentItem(actor,componentName)
	local item = self:GetActorItem(actor)
	if(item == nil) then return end
	if(self.m_treeElementToActorData == nil or self.m_treeElementToActorData[item] == nil) then return end
	local item = self.m_treeElementToActorData[item].componentsEntry
	if(util.is_valid(item) == false) then return end
	return item:GetItemByIdentifier(componentName)
end
function gui.PFMActorEditor:CreateNewActor()
	local filmClip = self:GetFilmClip()
	if(filmClip == nil) then
		pfm.create_popup_message(locale.get_text("pfm_popup_create_actor_no_film_clip"))
		return
	end
	local actor = fudm.PFMActor()
	local actorName = "actor"

	local actorIndex = 1
	while(filmClip:FindActor(actorName .. actorIndex) ~= nil) do actorIndex = actorIndex +1 end
	actor:ChangeName(actorName .. actorIndex)
	actor:SetUniqueId(util.generate_uuid_v4())

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

	self:AddActor(actor)
	return actor
end
function gui.PFMActorEditor:AddActorToScene(actor) tool.get_filmmaker():AddActor(actor,self:GetFilmClip()) end
function gui.PFMActorEditor:CreateNewActorComponent(actor,componentType,updateActor,initComponent)
	local itemActor
	for elTree,data in pairs(self.m_treeElementToActorData) do
		if(util.is_same_object(actor,data.actor)) then
			itemActor = elTree
			break
		end
	end

	local component = fudm[componentType]()
	if(itemActor == nil or component == nil) then return end
	local actorData = self.m_treeElementToActorData[itemActor]
	local componentName = component:GetComponentName() .. "_component"
	local componentIndex = 1
	while(actor:FindComponent(componentName .. componentIndex) ~= nil) do componentIndex = componentIndex +1 end
	component:ChangeName((componentIndex == 1) and componentName or (componentName .. componentIndex))
	if(initComponent ~= nil) then initComponent(component) end

	actor:AddComponent(component)

	self:AddActorComponent(itemActor,actorData.componentsEntry,component)
	actorData.componentsEntry:Update()

	if(updateActor == true) then tool.get_filmmaker():UpdateActor(actor,self:GetFilmClip(),true) end
	return component
end
function gui.PFMActorEditor:TagRenderSceneAsDirty(dirty)
	tool.get_filmmaker():TagRenderSceneAsDirty(dirty)
end
function gui.PFMActorEditor:AddSliderControl(component,controlData)
	if(util.is_valid(self.m_animSetControls) == false) then return end
	local slider = self.m_animSetControls:AddSliderControl(controlData.name,controlData.identifier,controlData.default,controlData.min,controlData.max,nil,nil,controlData.integer or controlData.boolean)
	local callbacks = {}
	local skipCallbacks
	if(controlData.type == "flexController") then
		if(controlData.dualChannel == true) then
			slider:GetLeftRightValueRatioProperty():Link(self.m_leftRightWeightSlider:GetFractionProperty())
		end
		if(controlData.property ~= nil) then
			slider:SetValue(controlData.translateToInterface(component:GetProperty(controlData.property):GetValue()))
		elseif(controlData.get ~= nil) then
			slider:SetValue(controlData.translateToInterface(controlData.get(component)))
			if(controlData.getProperty ~= nil) then
				local prop = controlData.getProperty(component)
				if(prop ~= nil) then
					local cb = prop:AddChangeListener(function(newValue)
						self:TagRenderSceneAsDirty()
						if(skipCallbacks) then return end
						skipCallbacks = true
						slider:SetValue(controlData.translateToInterface(newValue))
						skipCallbacks = nil
					end)
					table.insert(callbacks,cb)
				end
			end
		elseif(controlData.dualChannel == true) then
			if(controlData.getLeft ~= nil) then
				slider:SetLeftValue(controlData.translateToInterface(controlData.getLeft(component)))
				if(controlData.getLeftProperty ~= nil) then
					local prop = controlData.getLeftProperty(component)
					if(prop ~= nil) then
						local cb = prop:AddChangeListener(function(newValue)
						self:TagRenderSceneAsDirty()
							if(skipCallbacks) then return end
							skipCallbacks = true
							slider:SetLeftValue(controlData.translateToInterface(newValue))
							skipCallbacks = nil
						end)
						table.insert(callbacks,cb)
					end
				end
			end
			if(controlData.getRight ~= nil) then
				slider:SetRightValue(controlData.translateToInterface(controlData.getRight(component)))
				if(controlData.getRightProperty ~= nil) then
					local prop = controlData.getRightProperty(component)
					if(prop ~= nil) then
						local cb = prop:AddChangeListener(function(newValue)
						self:TagRenderSceneAsDirty()
							if(skipCallbacks) then return end
							skipCallbacks = true
							slider:SetRightValue(controlData.translateToInterface(newValue))
							skipCallbacks = nil
						end)
						table.insert(callbacks,cb)
					end
				end
			end
		end
	elseif(controlData.property ~= nil) then
		local prop = component:GetProperty(controlData.property)
		if(prop ~= nil) then
			local function get_numeric_value(val)
				if(val == true) then val = 1.0
				elseif(val == false) then val = 0.0 end
				return val
			end
			local cb = prop:AddChangeListener(function(newValue)
				self:TagRenderSceneAsDirty()
				if(skipCallbacks) then return end
				skipCallbacks = true
				slider:SetValue(controlData.translateToInterface(get_numeric_value(newValue)))
				skipCallbacks = nil
			end)
			table.insert(callbacks,cb)
			slider:SetValue(controlData.translateToInterface(get_numeric_value(prop:GetValue())))
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
		if(controlData.boolean) then value = toboolean(value) end
		if(controlData.property ~= nil) then
			component:GetProperty(controlData.property):SetValue(controlData.translateFromInterface(value))
		elseif(controlData.set ~= nil) then
			controlData.set(component,value)
		elseif(controlData.setLeft ~= nil) then
			controlData.setLeft(component,value)
		end
	end)
	slider:AddCallback("OnRightValueChanged",function(el,value)
		if(controlData.boolean) then value = toboolean(value) end
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
function gui.PFMActorEditor:ScheduleUpdateSelectedEntities()
	if(self.m_updateSelectedEntities) then return end
	self:EnableThinking()
	self.m_updateSelectedEntities = true
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
			local actorData = self.m_treeElementToActorData[el]
			local ent = actorData.actor:FindEntity()
			if(ent ~= nil) then
				selectionManager:Select(ent)
			end
		end
		return selected
	end
	iterate_tree(self.m_tree:GetRoot())
end
function gui.PFMActorEditor:OnThink()
	if(self.m_updateSelectedEntities) then
		self.m_updateSelectedEntities = nil
		self:DisableThinking()
		self:UpdateSelectedEntities()
	end
end
function gui.PFMActorEditor:GetFilmClip() return self.m_filmClip end
function gui.PFMActorEditor:SelectActor(actor)
	if(util.is_valid(self.m_tree)) then self.m_tree:DeselectAll() end
	for itemActor,actorData in pairs(self.m_treeElementToActorData) do
		if(util.is_same_object(actor,actorData.actor)) then
			if(itemActor:IsValid()) then itemActor:Select() end
			break
		end
	end
end
function gui.PFMActorEditor:AddActorComponent(itemActor,itemComponents,component)
	local itemComponent = itemComponents:AddItem(component:GetName(),nil,nil,component:GetComponentName())
	if(component.GetIconMaterial) then
		itemComponent:AddIcon(component:GetIconMaterial())
		itemActor:AddIcon(component:GetIconMaterial())
	end
	if(component.SetupControls) then
		component:SetupControls(self,itemComponent)
	end

	-- TODO: Use the code below once the system has been fully transitioned to UDM
	--[[local itemComponent = itemComponents:AddItem(component:GetName())
	if(component.GetIconMaterial) then
		itemComponent:AddIcon(component:GetIconMaterial())
		itemActor:AddIcon(component:GetIconMaterial())
	end
	local function stringToFunction(str)
		if(str == nil) then return end
		local f = loadstring("return " .. str)
		if(f == nil or type(f) ~= "function") then return end
		return f()
	end
	local function getText(udm,key,localizedKey)
		local text = udm:GetValue(localizedKey)
		if(text ~= nil) then text = locale.get_text(text)
		else text = udm:GetValue(key) end
		return text or ""
	end
	local udmComponent = self.m_componentManager:GetComponents():Get(component:GetComponentName())
	if(udmComponent:IsValid()) then

		for _,udmControl in ipairs(udmComponent:GetArrayValues("controls")) do
			local type = udmControl:GetValue("type")
			local name = getText(udmControl,"label","localizedLabel")

			local udmLua = udmControl:Get("lua")
			local identifier = udmControl:GetValue("identifier")

			if(type == "slider") then
				local ctrlSettings = {
					name = name,
					property = udmControl:GetValue("keyValue"),
					min = udmControl:GetValue("min"),
					max = udmControl:GetValue("max"),
					default = udmControl:GetValue("default")
				}

				ctrlSettings.translateToInterface = stringToFunction(udmLua:GetValue("translateToInterface"))
				ctrlSettings.translateFromInterface = stringToFunction(udmLua:GetValue("translateFromInterface"))

				local unit = getText(udmControl,"unit","localizedUnit")
				if(#unit > 0) then ctrlSettings["unit"] = unit end
				self:AddControl(component,itemComponent,ctrlSettings)
			elseif(type == "color") then
				local ctrlSettings = {
					name = name,
					addControl = function(ctrls)
						local colField,wrapper = ctrls:AddColorField(locale.get_text("color"),"color",self:GetColor(),function(oldCol,newCol)
							self:SetColor(newCol)
							self:TagRenderSceneAsDirty()
						end)
						return wrapper
					end
				}
				self:AddControl(component,itemComponent,ctrlSettings)
			elseif(type == "drop_down_menu") then
				local options = {}
				for _,udmOption in ipairs(udmControl:GetArrayValues("options")) do
					local value = udmOption:GetValue("value")
					local name = locale.get_text(udmOption:GetValue("localizedDisplayText"))
					table.insert(options,{value,name})
				end
				local onChange = stringToFunction(udmLua:GetValue("onChange"))
				local ctrlSettings = {
					name = name,
					addControl = function(ctrls)
						local fOnChange = onChange
						if(fOnChange ~= nil) then
							fOnChange = function(menu,option) onChange(ctrls,menu,option) end
						end
						local menu,wrapper = ctrls:AddDropDownMenu(name,identifier,options,udmControl:GetValue("default") or 0,fOnChange)
						return wrapper
					end
				}
				self:AddControl(component,itemComponent,ctrlSettings)
			end
		end
	end]]
end
function gui.PFMActorEditor:AddActor(actor)
	local itemActor = self.m_tree:AddItem(actor:GetName())

	itemActor:AddCallback("OnMouseEvent",function(tex,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())

			pContext:AddItem(locale.get_text("pfm_export_animation"),function()
				local entActor = actor:FindEntity()
				if(util.is_valid(entActor) == false) then return end
				local filmmaker = tool.get_filmmaker()
				filmmaker:ExportAnimation(entActor)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end)

	local itemComponents = itemActor:AddItem(locale.get_text("components"))
	self.m_treeElementToActorData[itemActor] = {
		actor = actor,
		componentsEntry = itemComponents
	}
	itemComponents:AddCallback("OnMouseEvent",function(tex,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			if(util.is_valid(pContext) == false) then return end
			pContext:SetPos(input.get_cursor_pos())
			local pComponentsItem,pComponentsMenu = pContext:AddSubMenu(locale.get_text("pfm_add_component"))

			local componentManager = self.m_componentManager
			local components = {}
			for componentType,udmComponent in pairs(componentManager:GetComponents():GetChildren()) do
				local name = udmComponent:GetValue("name")
				if(name == nil) then
					local valid,n = locale.get_text("component_" .. componentType,nil,true)
					if(valid) then name = n
					else name = componentType end
				end
				locale.get_text("pfm_add_component_type",{name})
				pComponentsMenu:AddItem(locale.get_text("pfm_add_component_type",{componentType}),function()
					local tTranslation = {
						["pfm_model"] = "PFMModel",
						["pfm_particle_system"] = "PFMParticleSystem",
						["pfm_camera"] = "PFMCamera",
						["pfm_animation_set"] = "PFMAnimationSet",
						["pfm_light_spot"] = "PFMSpotLight",
						["pfm_light_directional"] = "PFMDirectionalLight",
						["pfm_light_point"] = "PFMPointLight",
						["pfm_impersonatee"] = "PFMImpersonatee"
					}
					self:CreateNewActorComponent(actor,tTranslation[componentType],true)
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
	self.m_treeElementToActorData = {}
	-- TODO: Include groups the actors belong to!
	for _,actor in ipairs(filmClip:GetActorList()) do
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
function gui.PFMActorEditor:AddControl(component,item,controlData,identifier)
	controlData.translateToInterface = controlData.translateToInterface or function(val) return val end
	controlData.translateFromInterface = controlData.translateFromInterface or function(val) return val end
	local child = item:AddItem(controlData.name,nil,nil,identifier)

	local ctrl
	local selectedCount = 0
	local fOnSelected = function()
		selectedCount = selectedCount +1
		if(selectedCount > 1 or util.is_valid(ctrl)) then return end
		if(controlData.addControl) then ctrl = controlData.addControl(self.m_animSetControls)
		else
			ctrl = self:AddSliderControl(component,controlData)
			if(controlData.unit) then ctrl:SetUnit(controlData.unit) end
		end
		self:CallCallbacks("OnControlSelected",component,controlData,ctrl)
	end
	local fOnDeselected = function()
		selectedCount = selectedCount -1
		if(selectedCount > 0) then return end
		self:CallCallbacks("OnControlDeselected",component,controlData,ctrl)
		if(util.is_valid(ctrl) == false) then return end
		ctrl:Remove()
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
	return ctrl
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
