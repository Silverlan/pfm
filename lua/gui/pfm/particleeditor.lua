--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/colorentry.lua")
include("/gui/pfm/slider.lua")
include("/gui/editableentry.lua")
include("/gui/hbox.lua")
include("/gui/vbox.lua")
include("/gui/pfm/treeview.lua")

locale.load("pfm_particle_editor.txt")
locale.load("pfm_particle_operators.txt")
locale.load("pfm_particle_operators_source.txt")

util.register_class("gui.PFMParticleEditor",gui.Base)
function gui.PFMParticleEditor:__init()
	gui.Base.__init(self)
end
function gui.PFMParticleEditor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.m_contents = gui.create("WIHBox",self.m_bg,0,0,self:GetWidth(),self:GetHeight() -64,0,0,1,1)
	self.m_contents:SetAutoFillContents(true)

	self.m_controlsContents = gui.create("WIHBox",self.m_contents)
	self.m_controlsContents:SetAutoFillContents(true)

	self.m_tree = gui.create("WIPFMTreeView",self.m_controlsContents)
	self.m_tree:AddCallback("OnItemSelectChanged",function(tree,el,selected)
		self:ClearAttributes()
		if(selected == false) then return end
		if(el == self.m_elBasePropertiesItem) then
			self:PopulateAttributes("base","base")
			return
		end
		local data = self.m_operatorData[el]
		if(data == nil) then return end
		self:PopulateAttributes(data.operatorType,data.type,data.udmOperator)
	end)
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)
	self.m_tree:SetAutoSelectChildren(true)

	local function add_category(text,fPopulateContextMenu)
		local el = self.m_tree:AddItem(text)

		if(fPopulateContextMenu ~= nil) then
			el:AddCallback("OnMouseEvent",function(src,button,state,mods)
				if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
					local pContext = gui.open_context_menu()
					pContext:SetPos(input.get_cursor_pos())
					fPopulateContextMenu(pContext)
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
			end)
		end
		return el
	end
	self.m_propertyItems = {}
	local function add_property_category(propertyType,text)
		local item = add_category(text,function(pContext)
			local pt = self.m_particleSystem
			local ptC = util.is_valid(pt) and pt:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM) or nil
			if(ptC == nil) then return end
			local propertyList = {}
			if(propertyType == "initializer") then
				for _,initializer in ipairs(ents.ParticleSystemComponent.get_registered_initializers()) do
					if(ptC:FindInitializerByType(initializer) == nil) then
						table.insert(propertyList,initializer)
					end
				end
			elseif(propertyType == "operator") then
				for _,op in ipairs(ents.ParticleSystemComponent.get_registered_operators()) do
					if(ptC:FindOperatorByType(op) == nil) then
						table.insert(propertyList,op)
					end
				end
			elseif(propertyType == "renderer") then
				for _,renderer in ipairs(ents.ParticleSystemComponent.get_registered_renderers()) do
					if(ptC:FindRendererByType(renderer) == nil) then
						table.insert(propertyList,renderer)
					end
				end
			end
			if(#propertyList == 0) then return end
			local pItem,pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_pted_add_" .. propertyType))
			for _,property in ipairs(propertyList) do
				pSubMenu:AddItem(locale.get_text("pts_" .. property),function()
					self:AddProperty(propertyType,property)
				end)
				pSubMenu:Update()
			end
		end)
		self.m_propertyItems[propertyType] = item
	end

	self.m_elBasePropertiesItem = add_category(locale.get_text("pfm_pted_base_properties"))
	add_property_category("initializer",locale.get_text("pfm_pted_initializers"))
	add_property_category("operator",locale.get_text("pfm_pted_operators"))
	add_property_category("renderer",locale.get_text("pfm_pted_renderers"))
	self.m_elChildrenItem = add_category("children")

	gui.create("WIResizer",self.m_controlsContents):SetFraction(0.5)

	self.m_propertiesBox = gui.create("WIVBox",self.m_controlsContents)
	self.m_propertiesBox:SetAutoFillContentsToWidth(true)

	gui.create("WIResizer",self.m_contents):SetFraction(0.66)

	-- Viewport
	local vpContents = gui.create("WIBase",self.m_contents,0,0,self:GetWidth(),self:GetHeight())

	self.m_contents:Update()

	self.m_vpBox = gui.create("WIVBox",vpContents,0,0,vpContents:GetWidth(),vpContents:GetHeight(),0,0,1,1)
	self.m_vpBox:SetAutoFillContents(true)
	self:InitializeViewport()

	gui.create("WIResizer",self.m_vpBox):SetFraction(0.75)

	self.m_renderControlsWrapper = gui.create("WIBase",self.m_vpBox,0,0,100,100)
	self.m_renderControlsVbox = gui.create("WIVBox",self.m_renderControlsWrapper,0,0,self.m_renderControlsWrapper:GetWidth(),self.m_renderControlsWrapper:GetHeight(),0,0,1,1)
	self.m_renderControlsVbox:SetAutoFillContents(true)
	self:InitializeViewportControls()

	self.m_properties = {}
	self.m_operatorData = {}

	self.m_particleSystemDesc = udm.create("PPSD")
	local tFiles,_ = file.find("scripts/particle_system_desc/*.udm")
	for _,f in ipairs(tFiles) do
		local udmData,err = udm.load("scripts/particle_system_desc/" .. f)
		if(udmData ~= false) then
			self.m_particleSystemDesc:GetAssetData():GetData():Merge(udmData:GetAssetData():GetData(),udm.MERGE_FLAG_BIT_DEEP_COPY)
		end
	end

	-- Save
	local btSave = gui.create("WIPFMButton",self.m_bg)
	local pBg = gui.create("WIRect",btSave,0,0,btSave:GetWidth(),btSave:GetHeight(),0,0,1,1)
	pBg:SetVisible(false)
	self.m_saveBg = pBg
	btSave:SetText(locale.get_text("save"))
	btSave:SetHeight(32)
	btSave:AddCallback("OnPressed",function(btRaytracying) self:Save() end)
	btSave:SetWidth(self.m_bg:GetWidth())
	btSave:SetY(self.m_bg:GetBottom() -btSave:GetHeight() -32)
	btSave:SetAnchor(0,1,1,1)
	self.m_btSave = btSave

	local btOpenInExplorer = gui.create("WIPFMButton",self.m_bg)
	btOpenInExplorer:SetText(locale.get_text("pfm_open_in_explorer"))
	btOpenInExplorer:SetHeight(32)
	btOpenInExplorer:AddCallback("OnPressed",function(btRaytracying)
		local filePath = self:GetFullFileName()
		if(filePath == nil) then return end
		util.open_path_in_explorer(file.get_file_path(filePath),file.get_file_name(filePath))
	end)
	btOpenInExplorer:SetWidth(self.m_bg:GetWidth())
	btOpenInExplorer:SetY(self.m_bg:GetBottom() -btOpenInExplorer:GetHeight())
	btOpenInExplorer:SetAnchor(0,1,1,1)
end
function gui.PFMParticleEditor:GetFullFileName()
	if(self.m_particleFileName == nil) then return end
	local filePath = asset.find_file(self.m_particleFileName,asset.TYPE_PARTICLE_SYSTEM)
	if(filePath == nil) then return end
	return asset.get_asset_root_directory(asset.TYPE_PARTICLE_SYSTEM) .. "/" .. filePath
end
function gui.PFMParticleEditor:UpdateSaveButton(saved)
	self.m_saveBg:SetVisible(true)
	if(saved) then self.m_saveBg:SetColor(Color(20,100,20))
	else self.m_saveBg:SetColor(Color(100,20,20)) end
end
function gui.PFMParticleEditor:Save()
	local fileName = self:GetFullFileName()
	if(fileName == nil) then return false end
	local udmData,err = udm.create("PPTSYS",1)
	if(udmData == false) then
		console.print_warning(err)
		return false
	end

	local assetData = udmData:GetAssetData():GetData()
	assetData:Merge(self.m_udmData:Get(),udm.MERGE_FLAG_BIT_DEEP_COPY)
	
	local f = file.open(fileName,bit.bor(file.OPEN_MODE_WRITE))
	if(f == nil) then
		pfm.log("Unable to open particle system file '" .. fileName .. "' for writing!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local res,err = udmData:SaveAscii(f)
	f:Close()
	if(res == false) then
		pfm.log("Failed to save particle system as '" .. fileName .. "': " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	pfm.log("Particle system has been saved as '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)
	self:UpdateSaveButton(true)
	return true
end
function gui.PFMParticleEditor:OnRemove()
	self:DestroyParticleSystem()
end
function gui.PFMParticleEditor:GetParticleEffectUdmData(ptName)
	local ptDefs = self.m_udmData:Get("particleSystemDefinitions")
	local child = ptDefs:Get(ptName)
	return child:Get("assetData")
end
function gui.PFMParticleEditor:ReloadParticleProperties()
	local udmData,err = udm.load(asset.get_asset_root_directory(asset.TYPE_PARTICLE_SYSTEM) .. "/" .. self.m_particleFileName)
	if(udmData == false) then return end
	local assetData = udmData:GetAssetData():GetData()
	local ptDefs = assetData:Get("particleSystemDefinitions")
	self.m_propertyItems["initializer"]:Clear()
	self.m_operatorData = {}
	self.m_udmData = assetData:ClaimOwnership()
	self.m_ptName = self.m_particleName
	local child = ptDefs:Get(self.m_ptName)
	if(child:IsValid() == false) then return end
	local function init_properties(baseName,keyName)
		local props = child:Get("assetData"):Get(keyName)
		if(props:IsValid()) then
			for _,udmProp in ipairs(props:GetArrayValues()) do
				local name = udmProp:GetValue("name")
					local propertyType = baseName
					local type = name
					local el = self.m_propertyItems[propertyType]:AddItem(locale.get_text("pts_" .. type))
					self.m_operatorData[el] = {
						operatorType = propertyType,
						type = name,
						udmOperator = udmProp
					}
					el:AddCallback("OnMouseEvent",function(el,button,state,mods)
						if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
							local pContext = gui.open_context_menu()
							pContext:SetPos(input.get_cursor_pos())
							local item
							item = pContext:AddItem(locale.get_text("remove"),function()
								util.remove(item)
								self:RemoveProperty(propertyType,type)
							end)
							pContext:Update()
							return util.EVENT_REPLY_HANDLED
						end
						return util.EVENT_REPLY_UNHANDLED
					end)
				--end
			end
			
		end
	end
	init_properties("initializer","initializers")
	init_properties("operator","operators")
	init_properties("renderer","renderers")

	local children = child:Get("assetData"):Get("children")
	for _,child in ipairs(children:GetArrayValues()) do
		local type = child:GetValue("type",udm.TYPE_STRING) or ""
		local el = self.m_elChildrenItem:AddItem(type)
		
		-- TODO
	end
end
function gui.PFMParticleEditor:InitializeViewportControls()
	local colorCtrl = gui.create("WIPFMColorEntry",self.m_renderControlsVbox)
	colorCtrl:GetColorProperty():AddCallback(function(oldCol,newCol)
		self.m_viewport:SetClearColor(newCol)
	end)
	colorCtrl:SetColor(Color.Black)
	colorCtrl:Wrap("WIEditableEntry"):SetText(locale.get_text("background_color"))

	--[[local btSwitchViewport = gui.create("WIPFMButton",self.m_renderControlsVbox)
	btSwitchViewport:SetText(locale.get_text("pfm_pted_switch_to_raytracing_viewport"))
	btSwitchViewport:AddCallback("OnPressed",function(btSwitchViewport)
		if(self.m_viewport:IsVisible()) then self:SwitchToRaytracingViewport()
		else self:SwitchToRealtimeViewport() end
	end)
	self.m_btSwitchViewport = btSwitchViewport

	local btRaytracying = gui.create("WIPFMButton",self.m_renderControlsVbox)
	btRaytracying:SetText(locale.get_text("pfm_render_preview"))
	btRaytracying:AddCallback("OnPressed",function(btRaytracying)
		btRaytracying:SetEnabled(false)
		self:SwitchToRaytracingViewport()
		self.m_rtViewport:Refresh()
	end)
	self.m_btRaytracying = btRaytracying]]

	gui.create("WIBase",self.m_renderControlsVbox)
end
function gui.PFMParticleEditor:SwitchToRaytracingViewport()
	self.m_viewport:SetVisible(false)
	self.m_rtViewport:SetVisible(true)
	self.m_btSwitchViewport:SetText(locale.get_text("pfm_pted_switch_to_realtime_viewport"))
end
function gui.PFMParticleEditor:SwitchToRealtimeViewport()
	self.m_viewport:SetVisible(true)
	self.m_rtViewport:SetVisible(false)
	self.m_btSwitchViewport:SetText(locale.get_text("pfm_pted_switch_to_raytracing_viewport"))
end
function gui.PFMParticleEditor:InitializeViewport()
	local width = 1024
	local height = 1024
	local vpContainer = gui.create("WIRect",self.m_vpBox,0,0,width,height)
	vpContainer:SetColor(Color.Black) -- Background has to be black, in case transparent pixels are being rendered
	self.m_viewport = gui.create("WIModelView",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_viewport:SetClearColor(Color.Black)--Color.Clear)
	self.m_viewport:InitializeViewport(width,height)
	self.m_viewport:SetFov(math.horizontal_fov_to_vertical_fov(45.0,width,height))
	self.m_viewport:SetModel("error")
	self.m_viewport:SetAlwaysRender(true)

	self.m_rtViewport = gui.create("WIRaytracedViewport",vpContainer,0,0,vpContainer:GetWidth(),vpContainer:GetHeight(),0,0,1,1)
	self.m_rtViewport:SetProjectManager(tool.get_filmmaker())
	self.m_rtViewport:SetGameScene(self.m_viewport:GetScene())
	self.m_rtViewport:SetVisible(false)
	self.m_rtViewport:SetUseElementSizeAsRenderResolution(true)
	self.m_rtViewport:AddCallback("OnComplete",function()
		self.m_btRaytracying:SetEnabled(true)
	end)

	local settings = self.m_rtViewport:GetRenderSettings()
	settings:SetSky("skies/dusk379.hdr")
	settings:SetWidth(width)
	settings:SetHeight(height)
	settings:SetSamples(40)
end
function gui.PFMParticleEditor:PopulateAttributes(propertyType,opType,udmOperator)
	local data = self.m_particleSystemDesc
	if(data == nil) then return end
	data = data:GetAssetData():GetData()
	local ptDef = data:Get(opType)
	if(ptDef:IsValid() == false) then return end
	local keyValueBlock = ptDef:Get("keyvalues")
	if(keyValueBlock:IsValid()) then
		local pt = self.m_particleSystem
		local ptC = util.is_valid(pt) and pt:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM) or nil
		local property
		if(ptC ~= nil and propertyType ~= "base") then
			if(propertyType == "initializer") then property = ptC:FindInitializerByType(opType)
			elseif(propertyType == "operator") then property = ptC:FindOperatorByType(opType)
			elseif(propertyType == "renderer") then property = ptC:FindRendererByType(opType) end
		end
		local keyValues = (property ~= nil) and property:GetKeyValues() or {}
		local function get_key_value(key)
			if(propertyType ~= "base") then return keyValues[key] end
			if(util.is_valid(ptC) == false) then return end
			if(key == "maxparticles") then return tostring(ptC:GetMaxParticleCount()) end
			if(key == "emission_rate") then return tostring(ptC:GetEmissionRate()) end
			if(key == "material") then
				local mat = ptC:GetMaterial()
				return (mat ~= nil) and mat:GetName() or nil
			end
			if(key == "radius") then return tostring(ptC:GetRadius()) end
			if(key == "sort_particles") then return ptC:GetSortParticles() and "1" or "0" end
			if(key == "color") then return tostring(ptC:GetInitialColor()) end
			if(key == "soft_particles") then return ptC:GetSoftParticles() and "1" or "0" end
		end
		local function set_key_value(key,val)
			if(udmOperator ~= nil) then
				local udmKeyValues = udmOperator:Get("keyValues")
				if(udmKeyValues:IsValid()) then
					udmKeyValues:SetValue(key,udmKeyValues:Get(key):GetType(),val)
				end
			end

			self:ReloadParticleSystem(self.m_ptName)
			self:UpdateSaveButton(false)
		end
		for name,kvData in pairs(keyValueBlock:GetChildren()) do
			local locName = locale.get_text("pts_" .. opType .. "_" .. name)
			local type = kvData:GetValue("type",udm.TYPE_STRING)
			local ctrl
			if(type == "float" or type == "int") then -- or type == "bool") then
				local min = kvData:GetValue("min",udm.TYPE_FLOAT) or 0.0
				local max = kvData:GetValue("max",udm.TYPE_FLOAT) or 0.0
				local default = kvData:GetValue("default",udm.TYPE_FLOAT) or 0.0
				local stepSize = kvData:GetValue("step_size",udm.TYPE_FLOAT) or 1--0.01)
				local sliderCtrl = gui.create("WIPFMSlider",self.m_propertiesBox)
				sliderCtrl:SetText(locName)
				sliderCtrl:SetRange(min,max)
				sliderCtrl:SetDefault(default)
				-- sliderCtrl:SetTooltip(locale.get_text("pfm_metalness_desc"))
				sliderCtrl:SetStepSize(stepSize)

				local val = get_key_value(name)
				if(val ~= nil) then sliderCtrl:SetValue(tonumber(val)) end

				if(type == "int" or type == "bool") then sliderCtrl:SetInteger() end
				sliderCtrl:AddCallback("OnLeftValueChanged",function(el,value)
					set_key_value(name,tostring(value))
					self:ReloadParticle()
				end)
				ctrl = sliderCtrl
			elseif(type == "string" or type == "vector") then
				local default = kvData:GetValue("default",udm.TYPE_STRING) or ""
				local teCtrl = gui.create("WITextEntry",self.m_propertiesBox)
				teCtrl:AddCallback("OnTextEntered",function(pEntry)
					set_key_value(name,pEntry:GetText())
					self:ReloadParticle()
				end)
				local wrapper = teCtrl:Wrap("WIEditableEntry")
				wrapper:SetText(locName)
				teCtrl:SetText(default)

				local val = get_key_value(name)
				if(val ~= nil) then teCtrl:SetText(tostring(val)) end

				ctrl = wrapper
			elseif(type == "color") then
				local default = kvData:GetValue("default",udm.TYPE_VECTOR4) or Vector4(1,1,1,1)
				default = Color(default)
				local colorCtrl = gui.create("WIPFMColorEntry",self.m_propertiesBox)
				colorCtrl:GetColorProperty():AddCallback(function(oldCol,newCol)
					set_key_value(name,tostring(newCol))
					self:ReloadParticle()
				end)
				local wrapper = colorCtrl:Wrap("WIEditableEntry")
				wrapper:SetText(locName)

				local val = get_key_value(name)
				if(val ~= nil) then colorCtrl:SetColor(Color(val)) end

				ctrl = wrapper
			else console.print_warning("Unsupported particle field type '" .. type .. "' for key '" .. name .. "' of operator '" .. opType .. "'! Ignoring...") end
			if(util.is_valid(ctrl)) then table.insert(self.m_properties,ctrl) end
		end
	end
	--[[local keyValues = op:GetKeyValues()
	for key,val in pairs(keyValues) do
		-- TODO: Init element by type??
		local te = gui.create("WITextEntry",self.m_propertiesBox)
		te:AddCallback("OnTextEntered",function(pEntry)
			
		end)
		te:Wrap("WIEditableEntry"):SetText(text)
		table.insert(self.m_properties,te)
	end]]
end
function gui.PFMParticleEditor:DestroyParticleSystem()
	-- if(util.is_valid(self.m_particleSystem)) then self.m_particleSystem:Remove() end
end
function gui.PFMParticleEditor:LoadParticleSystem(fileName,ptName)
	game.precache_particle_system(fileName)
	self.m_viewport:SetParticleSystem(ptName)
	self.m_particleSystem = self.m_viewport:GetEntity()
	self.m_particleFileName = fileName
	self.m_particleName = ptName

	self:ReloadParticleProperties()
end
function gui.PFMParticleEditor:SaveParticleSystem()
	local particleSystems = {}

	--local success = game.save_particle_system("particles/ciri/fireplace_2.pptsys",particleSystems)
end
function gui.PFMParticleEditor:GetParticleSystem()
	return util.is_valid(self.m_particleSystem) and self.m_particleSystem:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM) or nil
end
function gui.PFMParticleEditor:CreateNewParticleSystem()
	self.m_viewport:SetParticleSystem()
	self.m_particleSystem = self.m_viewport:GetEntity()
	--[[local ent = self:CreateParticleSystem(fileName,ptName)
	local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)

	local radius = 4.0
	ent:SetKeyValue("maxparticles",tostring(100))
	ent:SetKeyValue("material","effects/brightglow_y_nomodel")
	ent:SetKeyValue("radius",tostring(radius))
	ent:SetKeyValue("lifetime",tostring(10))
	ent:SetKeyValue("color","255 255 255 255")
	ent:SetKeyValue("sort_particles",tostring(true))
	ent:SetKeyValue("emission_rate","100") -- -- TODO: Emitter tostring(1))--tostring(numParticles))
	ent:SetKeyValue("loop","1")
	ent:SetKeyValue("auto_simulate","1")
	ent:SetKeyValue("transform_with_emitter","1")

	ptC:AddRenderer("sprite",{})
	ent:Spawn()

	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:TurnOn() end]]
end
function gui.PFMParticleEditor:CreateParticleSystem(fileName,ptName)
	--[[self:DestroyParticleSystem()
	local ent = ents.create("env_particle_system")
	ent:SetKeyValue("loop","1")
	if(fileName ~= nil) then
		ent:SetKeyValue("particle_file",fileName)
		ent:SetKeyValue("particle",ptName)
	end
	self.m_particleSystem = ent
	ent:AddComponent(ents.COMPONENT_TRANSFORM)
	ent:AddComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	ent:AddComponent(ents.COMPONENT_LOGIC)

	local scene = self.m_viewport:GetScene()
	ent:AddToScene(scene)
	ent:RemoveFromScene(game.get_scene())]]

	-- TODO
	--[[local el = self.m_catInitializerBox:AddItem("radius_random")
	self.m_operatorData[el] = {
		operatorType = "initializer",
		type = "radius_random"
	}
	el:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem("Remove",function() -- TODO: Localization
				self.m_operatorData[el] = nil
				print("Remove initializer...")
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)]]
	return ent
end
function gui.PFMParticleEditor:AddInitializer(initializer) self:AddProperty("initializer",initializer) end
function gui.PFMParticleEditor:AddOperator(operator) self:AddProperty("operator",operator) end
function gui.PFMParticleEditor:AddEmitter(emitter) self:AddProperty("emitter",emitter) end
function gui.PFMParticleEditor:AddProperty(propertyType,property)
	local pt = self.m_particleSystem
	local ptC = util.is_valid(pt) and pt:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM) or nil
	if(ptC == nil or ptC:FindInitializerByType(property)) then return end
	if(propertyType == "initializer") then property = ptC:AddInitializer(property,{})
	elseif(propertyType == "operator") then property = ptC:AddOperator(property,{})
	elseif(propertyType == "renderer") then property = ptC:AddRenderer(property,{}) end
	if(property == nil) then return end
	self:PopulateProperty(ptC,propertyType,property)
end
function gui.PFMParticleEditor:RemoveProperty(propertyType,property)
	local ptUdmData = self:GetParticleEffectUdmData(self.m_particleName)
	local props = ptUdmData:Get(propertyType .. "s")
	for i,child in ipairs(props:GetChildren()) do
		local name = child:GetValue("name",udm.TYPE_STRING) or ""
		if(name == property) then
			child:RemoveValue(i -1)
			break
		end
	end

	self:ReloadParticleSystem(self.m_ptName)
	self:UpdateSaveButton(false)
end
function gui.ReloadParticleSystem(ptName)
	local pt = self.m_particleSystem
	if(util.is_valid(pt) == false) then return end
	local ptC = pt:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC ~= nil) then
		local name = ptName
		ptC:Clear()

		local res,err = game.register_particle_system(name,self.m_udmData:Get("particleSystemDefinitions"):Get(name):Get("assetData"))
		if(res) then
			ptC:InitializeFromParticleSystemDefinition(name)
			ptC:Start()
		else
			pfm.log("Failed to register particle system '" .. name .. "': " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		end
	end
end
function gui.PFMParticleEditor:PopulateProperty(ptC,propertyType,property)
	local type = property:GetType()
	local el = self.m_propertyItems[propertyType]:AddItem(locale.get_text("pts_" .. type))
	self.m_operatorData[el] = {
		operatorType = propertyType,
		type = type
	}
	el:AddCallback("OnMouseEvent",function(el,button,state,mods)
		if(button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS) then
			local pContext = gui.open_context_menu()
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("remove"),function()
				self:RemoveProperty(propertyType,type)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function gui.PFMParticleEditor:PopulateParticleProperties()
	local ent = self.m_particleSystem
	local ptC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM) or nil
	if(ptC == nil) then return end
	for _,initializer in ipairs(ptC:GetInitializers()) do
		self:PopulateProperty(ptC,"initializer",initializer)
	end
	for _,op in ipairs(ptC:GetOperators()) do
		self:PopulateProperty(ptC,"operator",op)
	end
	for _,renderer in ipairs(ptC:GetRenderers()) do
		self:PopulateProperty(ptC,"renderer",renderer)
	end
end
function gui.PFMParticleEditor:ReloadParticle()
	local ent = self.m_particleSystem
	if(util.is_valid(ent) == false) then return end
	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then
		toggleC:TurnOff()
		toggleC:TurnOn()
	end
	self.m_viewport:Render()
end
function gui.PFMParticleEditor:ClearAttributes()
	for _,el in ipairs(self.m_properties) do
		if(el:IsValid()) then el:Remove() end
	end
	self.m_properties = {}
end
function gui.PFMParticleEditor:SetKeyValue(key,val)

	-- Remove particle and re-create
end
gui.register("WIPFMParticleEditor",gui.PFMParticleEditor)
