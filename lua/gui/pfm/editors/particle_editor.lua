-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/controls/color_entry.lua")
include("/gui/pfm/controls/slider.lua")
include("/gui/controls/editable_entry.lua")
include("/gui/layout/hbox.lua")
include("/gui/layout/vbox.lua")
include("/gui/pfm/containers/tree_view.lua")

locale.load("pfm_particle_editor.txt")
locale.load("pfm_particle_operators.txt")
locale.load("pfm_particle_operators_source.txt")

util.register_class("gui.PFMParticleEditor", gui.Base)
function gui.PFMParticleEditor:__init()
	gui.Base.__init(self)
end
function gui.PFMParticleEditor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 128)

	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(54, 54, 54))

	self.m_contents = gui.create("hbox", self.m_bg, 0, 0, self:GetWidth(), self:GetHeight() - 64, 0, 0, 1, 1)
	self.m_contents:SetAutoFillContents(true)

	self.m_controlsContents = gui.create("hbox", self.m_contents)
	self.m_controlsContents:SetAutoFillContents(true)

	self.m_tree = gui.create("pfm_tree_view", self.m_controlsContents)
	self.m_tree:AddCallback("OnItemSelectChanged", function(tree, el, selected)
		self:ClearAttributes()
		if selected == false then
			return
		end
		if el == self.m_elBasePropertiesItem then
			self:PopulateAttributes("base", "base")
			return
		end
		local data = self.m_operatorData[el]
		if data == nil then
			return
		end
		self:PopulateAttributes(data.operatorType, data.type, data.udmOperator)
	end)
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_SINGLE)
	self.m_tree:SetAutoSelectChildren(true)

	gui.create("resizer", self.m_controlsContents):SetFraction(0.5)

	self.m_propertiesBox = gui.create("vbox", self.m_controlsContents)
	self.m_propertiesBox:SetAutoFillContentsToWidth(true)

	gui.create("resizer", self.m_contents):SetFraction(0.66)

	-- Viewport
	local vpContents = gui.create("WIBase", self.m_contents, 0, 0, self:GetWidth(), self:GetHeight())

	self.m_contents:Update()

	self.m_vpBox = gui.create("vbox", vpContents, 0, 0, vpContents:GetWidth(), vpContents:GetHeight(), 0, 0, 1, 1)
	self.m_vpBox:SetAutoFillContents(true)
	self:InitializeViewport()

	gui.create("resizer", self.m_vpBox):SetFraction(0.75)

	self.m_renderControlsWrapper = gui.create("WIBase", self.m_vpBox, 0, 0, 100, 100)
	self.m_renderControlsVbox = gui.create(
		"vbox",
		self.m_renderControlsWrapper,
		0,
		0,
		self.m_renderControlsWrapper:GetWidth(),
		self.m_renderControlsWrapper:GetHeight(),
		0,
		0,
		1,
		1
	)
	self.m_renderControlsVbox:SetAutoFillContents(true)
	self:InitializeViewportControls()

	self.m_properties = {}
	self.m_operatorData = {}

	self.m_particleSystemDesc = udm.create("PPSD")
	local tFiles, _ = file.find("scripts/particle_system_desc/*.udm")
	for _, f in ipairs(tFiles) do
		local udmData, err = udm.load("scripts/particle_system_desc/" .. f)
		if udmData ~= false then
			self.m_particleSystemDesc
				:GetAssetData()
				:GetData()
				:Merge(udmData:GetAssetData():GetData(), udm.MERGE_FLAG_BIT_DEEP_COPY)
		end
	end

	-- Save
	local btSave = gui.create("pfm_button", self.m_bg)
	local pBg = gui.create("WIRect", btSave, 0, 0, btSave:GetWidth(), btSave:GetHeight(), 0, 0, 1, 1)
	pBg:SetVisible(false)
	self.m_saveBg = pBg
	btSave:SetText(locale.get_text("save"))
	btSave:SetHeight(32)
	btSave:AddCallback("OnPressed", function(btRaytracying)
		self:Save()
	end)
	btSave:SetWidth(self.m_bg:GetWidth())
	btSave:SetY(self.m_bg:GetBottom() - btSave:GetHeight() - 32)
	btSave:SetAnchor(0, 1, 1, 1)
	self.m_btSave = btSave

	local btOpenInExplorer = gui.create("pfm_button", self.m_bg)
	btOpenInExplorer:SetText(locale.get_text("pfm_open_in_explorer"))
	btOpenInExplorer:SetHeight(32)
	btOpenInExplorer:AddCallback("OnPressed", function(btRaytracying)
		local filePath = self:GetFullFileName()
		if filePath == nil then
			return
		end
		util.open_path_in_explorer(file.get_file_path(filePath), file.get_file_name(filePath))
	end)
	btOpenInExplorer:SetWidth(self.m_bg:GetWidth())
	btOpenInExplorer:SetY(self.m_bg:GetBottom() - btOpenInExplorer:GetHeight())
	btOpenInExplorer:SetAnchor(0, 1, 1, 1)

	self.m_propertyItems = {}
	self.m_parentSystems = {}
end
function gui.PFMParticleEditor:PopulatePropertyTree()
	local parentItem = self.m_tree
	local function add_category(text, fPopulateContextMenu)
		local el = parentItem:AddItem(text)

		if fPopulateContextMenu ~= nil then
			el:AddCallback("OnMouseEvent", function(src, button, state, mods)
				if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
					local pContext = gui.open_context_menu(self)
					pContext:SetPos(input.get_cursor_pos())
					fPopulateContextMenu(pContext)
					pContext:Update()
					return util.EVENT_REPLY_HANDLED
				end
			end)
		end
		return el
	end
	local function add_property_category(propertyType, text)
		local item = add_category(text, function(pContext)
			local ptC = self:GetTargetParticleSystem()
			if ptC == nil then
				return
			end
			local propertyList = {}
			local function get_sorted_list(list)
				local listTmp = {}
				for _, item in ipairs(list) do
					table.insert(listTmp, { locale.get_text("pts_" .. item), item })
				end
				table.sort(listTmp, function(a, b)
					return a[1] < b[1]
				end)
				list = {}
				for _, data in ipairs(listTmp) do
					table.insert(list, data[2])
				end
				return list
			end
			if propertyType == "initializer" then
				local initializers = get_sorted_list(ents.ParticleSystemComponent.get_registered_initializers())
				for _, initializer in ipairs(initializers) do
					if ptC:FindInitializerByType(initializer) == nil then
						table.insert(propertyList, initializer)
					end
				end
			elseif propertyType == "operator" then
				local operators = get_sorted_list(ents.ParticleSystemComponent.get_registered_operators())
				for _, op in ipairs(operators) do
					if ptC:FindOperatorByType(op) == nil then
						table.insert(propertyList, op)
					end
				end
			elseif propertyType == "renderer" then
				local renderers = get_sorted_list(ents.ParticleSystemComponent.get_registered_renderers())
				for _, renderer in ipairs(renderers) do
					if ptC:FindRendererByType(renderer) == nil then
						table.insert(propertyList, renderer)
					end
				end
			end
			if #propertyList == 0 then
				return
			end
			local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_pted_add_" .. propertyType))
			for _, property in ipairs(propertyList) do
				pSubMenu:AddItem(locale.get_text("pts_" .. property), function()
					self:AddProperty(propertyType, property)
				end)
				pSubMenu:ScheduleUpdate()
			end
		end)
		self.m_propertyItems[propertyType] = item
	end

	self.m_elBasePropertiesItem = add_category(locale.get_text("pfm_pted_base_properties"))
	add_property_category("initializer", locale.get_text("pfm_pted_initializers"))
	add_property_category("operator", locale.get_text("pfm_pted_operators"))
	add_property_category("renderer", locale.get_text("pfm_pted_renderers"))
	self.m_elChildrenItem = add_category("children")
	self.m_elChildrenItem:AddCallback("OnMouseEvent", function(src, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			self.m_elChildrenItem:Expand()
			local elTmpItem = self.m_elChildrenItem:AddItem("")

			local te =
				gui.create("WITextEntry", elTmpItem, 0, 0, elTmpItem:GetWidth(), elTmpItem:GetHeight(), 0, 0, 1, 1)
			te:SetText("")
			te:RequestFocus()
			te:AddCallback("OnFocusKilled", function()
				local childName = te:GetText()
				util.remove(elTmpItem, true)
				util.remove(te, true)
				if #childName > 0 then
					local udmData = self:GetParticleEffectUdmData(self.m_particleName)
					local udmChildren = udmData:Get("children")
					if udmChildren:IsValid() == false then
						udmChildren = udmData:AddArray("children", 0, udm.TYPE_ELEMENT)
					end
					udmChildren:Resize(udmChildren:GetSize() + 1)
					local el = udmChildren:Get(udmChildren:GetSize() - 1)
					el:SetValue("type", udm.TYPE_STRING, childName)
					el:SetValue("delay", udm.TYPE_FLOAT, 0.0)

					self:AddParticleChildItem(childName)

					self:ReloadParticleSystem(self.m_ptName)
					self:UpdateSaveButton(false)
				end
			end)
			return util.EVENT_REPLY_HANDLED
		end
	end)
end
function gui.PFMParticleEditor:AddParticleChildItem(childName)
	local el = self.m_elChildrenItem:AddItem(childName)
	el:AddCallback("OnDoubleClick", function(el, button, state, mods)
		time.create_simple_timer(0.0, function()
			if self:IsValid() == false then
				return
			end
			table.insert(self.m_parentSystems, {
				fileName = self.m_particleFileName,
				systemName = self.m_particleName,
			})
			self:LoadParticleSystem(self.m_particleFileName, childName, false)
		end)
		return util.EVENT_REPLY_HANDLED
	end)
	el:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu(self)
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("remove"), function()
				util.remove(el)

				local udmData = self:GetParticleEffectUdmData(self.m_particleName)
				local udmChildren = udmData:Get("children")
				for i, udmChild in ipairs(udmChildren:GetArrayValues()) do
					local type = udmChild:GetValue("type", udm.TYPE_STRING)
					if type == childName then
						udmChildren:RemoveValue(i - 1)
						util.remove(el, true)
						break
					end
				end

				self:ReloadParticleSystem(self.m_ptName)
				self:UpdateSaveButton(false)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
end
function gui.PFMParticleEditor:GetFullFileName()
	if self.m_particleFileName == nil then
		return
	end
	local filePath = asset.find_file(self.m_particleFileName, asset.TYPE_PARTICLE_SYSTEM)
	if filePath == nil then
		return
	end
	return asset.get_asset_root_directory(asset.TYPE_PARTICLE_SYSTEM) .. "/" .. filePath
end
function gui.PFMParticleEditor:UpdateSaveButton(saved)
	self.m_saveBg:SetVisible(true)
	if saved then
		self.m_saveBg:SetColor(Color(20, 100, 20))
	else
		self.m_saveBg:SetColor(Color(100, 20, 20))
	end
end
function gui.PFMParticleEditor:Save()
	local fileName = self:GetFullFileName()
	if fileName == nil then
		return false
	end
	local udmData, err = udm.create("PPTSYS", 1)
	if udmData == false then
		console.print_warning(err)
		return false
	end

	local assetData = udmData:GetAssetData():GetData()
	assetData:Merge(self.m_udmData:Get(), udm.MERGE_FLAG_BIT_DEEP_COPY)

	local f = file.open(fileName, bit.bor(file.OPEN_MODE_WRITE))
	if f == nil then
		self:LogWarn("Unable to open particle system file '" .. fileName .. "' for writing!")
		return false
	end
	local res, err = udmData:SaveAscii(f)
	f:Close()
	if res == false then
		self:LogWarn("Failed to save particle system as '" .. fileName .. "': " .. err)
		return false
	end
	self:LogInfo("Particle system has been saved as '" .. fileName .. "'...")
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
	self.m_tree:Clear()

	if #self.m_parentSystems > 0 then
		local pd = self.m_parentSystems[#self.m_parentSystems]
		local el = self.m_tree:AddItem(locale.get_text("pfm_pted_go_to_parent") .. " (" .. pd.systemName .. ")")
		el:AddCallback("OnDoubleClick", function(el, button, state, mods)
			time.create_simple_timer(0.0, function()
				if self:IsValid() == false then
					return
				end
				local fileName = pd.fileName
				local systemName = pd.systemName
				self.m_parentSystems[#self.m_parentSystems] = nil
				self:LoadParticleSystem(fileName, systemName, false)
			end)
			return util.EVENT_REPLY_HANDLED
		end)
	end

	self:PopulatePropertyTree()

	local udmData, err =
		udm.load(asset.get_asset_root_directory(asset.TYPE_PARTICLE_SYSTEM) .. "/" .. self.m_particleFileName)
	if udmData == false then
		return
	end
	local assetData = udmData:GetAssetData():GetData()
	local ptDefs = assetData:Get("particleSystemDefinitions")
	self.m_propertyItems["initializer"]:Clear()
	self.m_operatorData = {}
	self.m_udmData = assetData:ClaimOwnership()
	self.m_ptName = self.m_particleName
	local child = ptDefs:Get(self.m_ptName)
	if child:IsValid() == false then
		return
	end
	local function init_properties(baseName, keyName)
		local props = child:Get("assetData"):Get(keyName)
		if props:IsValid() then
			for _, udmProp in ipairs(props:GetArrayValues()) do
				local name = udmProp:GetValue("name")
				local propertyType = baseName
				local type = name
				local el = self.m_propertyItems[propertyType]:AddItem(locale.get_text("pts_" .. type))
				self.m_operatorData[el] = {
					operatorType = propertyType,
					type = name,
					udmOperator = udmProp,
				}
				el:AddCallback("OnMouseEvent", function(el, button, state, mods)
					if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
						local pContext = gui.open_context_menu(self)
						pContext:SetPos(input.get_cursor_pos())
						pContext:AddItem(locale.get_text("remove"), function()
							self.m_propertyItems[propertyType]:ScheduleUpdate()
							self.m_operatorData[el] = nil
							util.remove(el, true)
							self:RemoveProperty(propertyType, type)
						end)
						pContext:Update()
						return util.EVENT_REPLY_HANDLED
					end
					return util.EVENT_REPLY_UNHANDLED
				end)
			end
		end
	end
	init_properties("initializer", "initializers")
	init_properties("operator", "operators")
	init_properties("renderer", "renderers")

	local children = child:Get("assetData"):Get("children")
	for _, child in ipairs(children:GetArrayValues()) do
		local type = child:GetValue("type", udm.TYPE_STRING) or ""
		self:AddParticleChildItem(type)
	end
end
function gui.PFMParticleEditor:GetParentParticleSystem()
	local ptC = self.m_particleSystem
	if util.is_valid(ptC) == false then
		return
	end
	ptC = ptC:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if ptC == nil then
		return
	end
	local parent = ptC:GetParent()
	while parent ~= nil do
		local pparent = parent:GetParent()
		if pparent ~= nil then
			parent = pparent
		end
	end
	parent = parent or ptC
	return parent
end
function gui.PFMParticleEditor:FindChildParticleSystem(name, ptC)
	if ptC == nil then
		ptC = self:GetParentParticleSystem()
		if util.is_valid(ptC) == false then
			return
		end
		return self:FindChildParticleSystem(name, ptC)
	end

	if util.is_valid(ptC) == false then
		return
	end
	for _, child in ipairs(ptC:GetChildren()) do
		local childName = child:GetName()
		if childName == name then
			return child
		end
		local pt = self:FindChildParticleSystem(name, child)
		if pt ~= nil then
			return pt
		end
	end
end
function gui.PFMParticleEditor:InitializeViewportControls()
	local colorCtrl = gui.create("pfm_color_entry", self.m_renderControlsVbox)
	colorCtrl:GetColorProperty():AddCallback(function(oldCol, newCol)
		self.m_viewport:SetClearColor(newCol)
	end)
	colorCtrl:SetColor(Color.Black)
	colorCtrl:Wrap("editable_entry"):SetText(locale.get_text("background_color"))

	--[[local btSwitchViewport = gui.create("pfm_button",self.m_renderControlsVbox)
	btSwitchViewport:SetText(locale.get_text("pfm_pted_switch_to_raytracing_viewport"))
	btSwitchViewport:AddCallback("OnPressed",function(btSwitchViewport)
		if(self.m_viewport:IsVisible()) then self:SwitchToRaytracingViewport()
		else self:SwitchToRealtimeViewport() end
	end)
	self.m_btSwitchViewport = btSwitchViewport

	local btRaytracying = gui.create("pfm_button",self.m_renderControlsVbox)
	btRaytracying:SetText(locale.get_text("pfm_render_preview"))
	btRaytracying:AddCallback("OnPressed",function(btRaytracying)
		btRaytracying:SetEnabled(false)
		self:SwitchToRaytracingViewport()
		self.m_rtViewport:Refresh()
	end)
	self.m_btRaytracying = btRaytracying]]

	gui.create("WIBase", self.m_renderControlsVbox)
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
	local vpContainer = gui.create("WIRect", self.m_vpBox, 0, 0, width, height)
	vpContainer:SetColor(Color.Black) -- Background has to be black, in case transparent pixels are being rendered
	self.m_viewport =
		gui.create("model_view", vpContainer, 0, 0, vpContainer:GetWidth(), vpContainer:GetHeight(), 0, 0, 1, 1)
	self.m_viewport:SetClearColor(Color.Black) --Color.Clear)
	self.m_viewport:InitializeViewport(width, height)
	self.m_viewport:SetFov(math.horizontal_fov_to_vertical_fov(45.0, width, height))
	self.m_viewport:SetModel("error")
	self.m_viewport:SetAlwaysRender(true)

	self.m_rtViewport = gui.create(
		"raytraced_viewport",
		vpContainer,
		0,
		0,
		vpContainer:GetWidth(),
		vpContainer:GetHeight(),
		0,
		0,
		1,
		1
	)
	self.m_rtViewport:SetProjectManager(tool.get_filmmaker())
	self.m_rtViewport:SetGameScene(self.m_viewport:GetScene())
	self.m_rtViewport:SetVisible(false)
	self.m_rtViewport:SetUseElementSizeAsRenderResolution(true)
	self.m_rtViewport:AddCallback("OnComplete", function()
		self.m_btRaytracying:SetEnabled(true)
	end)

	local settings = self.m_rtViewport:GetRenderSettings()
	settings:SetSky("skies/dusk379.hdr")
	settings:SetWidth(width)
	settings:SetHeight(height)
	settings:SetSamples(40)
end
function gui.PFMParticleEditor:PopulateAttributes(propertyType, opType, udmOperator)
	local data = self.m_particleSystemDesc
	if data == nil then
		return
	end
	data = data:GetAssetData():GetData()
	local ptDef = data:Get(opType)
	if ptDef:IsValid() == false then
		return
	end
	local keyValueBlock = ptDef:Get("keyvalues")
	if keyValueBlock:IsValid() == false then
		keyValueBlock = ptDef:Add("keyvalues")
	end
	if keyValueBlock:IsValid() then
		local ptC = self:GetTargetParticleSystem()
		local property
		if ptC ~= nil and propertyType ~= "base" then
			if propertyType == "initializer" then
				property = ptC:FindInitializerByType(opType)
			elseif propertyType == "operator" then
				property = ptC:FindOperatorByType(opType)
			elseif propertyType == "renderer" then
				property = ptC:FindRendererByType(opType)
			end
		end
		local keyValues = (property ~= nil) and property:GetKeyValues() or {}
		local function get_def_type(keyValueBlock, key)
			local kvData = keyValueBlock:Get(key)
			local strType = kvData:GetValue("type", udm.TYPE_STRING)
			local type
			if strType ~= nil then
				local etype = udm.ascii_type_to_enum(strType)
				if etype ~= udm.TYPE_INVALID then
					type = etype
				else
					self:LogWarn(
						"Unrecognized keyvalue type '"
							.. strType
							.. "' for keyvalue '"
							.. key
							.. "' of operator '"
							.. opType
							.. "'!"
					)
				end
			else
				self:LogWarn("Missing keyvalue type for keyvalue '" .. key .. "' of operator '" .. opType .. "'!")
			end
			return type
		end
		local function is_flag_set(flag)
			return (bit.band(ptC:GetFlags(), flag) ~= 0)
		end
		local function set_flag(flag, set)
			local flags = ptC:GetFlags()
			if set then
				flags = bit.bor(flags, flag)
			else
				flags = bit.band(flags, bit.bnot(flag))
			end
			ptC:SetFlags(flags)
		end
		local function get_key_value(key)
			if propertyType ~= "base" then
				return keyValues[key]
			end
			if util.is_valid(ptC) == false then
				return
			end
			if key == "maxparticles" then
				return tostring(ptC:GetMaxParticleCount())
			end
			if key == "emission_rate" then
				return tostring(ptC:GetEmissionRate())
			end
			if key == "material" then
				local mat = ptC:GetMaterial()
				return (mat ~= nil) and mat:GetName() or nil
			end
			if key == "radius" then
				return tostring(ptC:GetRadius())
			end
			if key == "extent" then
				return tostring(ptC:GetExtent())
			end
			if key == "sort_particles" then
				return ptC:GetSortParticles() and "1" or "0"
			end
			if key == "color" then
				return tostring(ptC:GetInitialColor())
			end
			if key == "soft_particles" then
				return ptC:GetSoftParticles() and "1" or "0"
			end
			if key == "rotate_with_emitter" then
				return is_flag_set(ents.ParticleSystemComponent.FLAG_BIT_ROTATE_WITH_EMITTER) and "1" or "0"
			end
			if key == "move_with_emitter" then
				return is_flag_set(ents.ParticleSystemComponent.FLAG_BIT_MOVE_WITH_EMITTER) and "1" or "0"
			end
			if key == "premultiply_alpha" then
				return is_flag_set(ents.ParticleSystemComponent.FLAG_BIT_PREMULTIPLY_ALPHA) and "1" or "0"
			end
			if key == "texture_scrolling_enabled" then
				return is_flag_set(ents.ParticleSystemComponent.FLAG_BIT_TEXTURE_SCROLLING_ENABLED) and "1" or "0"
			end
			if key == "cast_shadows" then
				return is_flag_set(ents.ParticleSystemComponent.FLAG_BIT_CAST_SHADOWS) and "1" or "0"
			end
			if key == "loop" then
				return bit.band(
					ptC:GetEntity():GetSpawnFlags(),
					ents.ParticleSystemComponent.SF_PARTICLE_SYSTEM_CONTINUOUS
				) ~= 0
			end
			if key == "max_node_count" then
				return tostring(ptC:GetMaxNodes())
			end
			if key == "alpha_mode" then
				local alphaMode = ptC:GetAlphaMode()
				if alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_ADDITIVE then
					return "additive"
				end
				if alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_ADDITIVE_BY_COLOR then
					return "additive_by_color"
				end
				if alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_OPAQUE then
					return "opaque"
				end
				if alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_MASKED then
					return "masked"
				end
				if alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_TRANSLUCENT then
					return "translucent"
				end
				if alphaMode == ents.ParticleSystemComponent.ALPHA_MODE_PREMULTIPLIED then
					return "premultiplied"
				end
				return "additive"
			end
		end
		local function alpha_mode_to_enum(val)
			local alphaMode
			if val == "additive" then
				alphaMode = ents.ParticleSystemComponent.ALPHA_MODE_ADDITIVE
			elseif val == "additive_by_color" then
				alphaMode = ents.ParticleSystemComponent.ALPHA_MODE_ADDITIVE_BY_COLOR
			elseif val == "opaque" then
				alphaMode = ents.ParticleSystemComponent.ALPHA_MODE_OPAQUE
			elseif val == "masked" then
				alphaMode = ents.ParticleSystemComponent.ALPHA_MODE_MASKED
			elseif val == "translucent" then
				alphaMode = ents.ParticleSystemComponent.ALPHA_MODE_TRANSLUCENT
			elseif val == "premultiplied" then
				alphaMode = ents.ParticleSystemComponent.ALPHA_MODE_PREMULTIPLIED
			end
			return alphaMode
		end
		local function set_key_value(key, val)
			if propertyType == "base" then
				local ptUdmData = self:GetParticleEffectUdmData(self.m_particleName)
				local udmKeyValues = ptUdmData:Get("keyValues")
				local type = get_def_type(data:Get("base"):Get("keyvalues"), key)
				if type ~= nil then
					udmKeyValues:SetValue(key, udm.TYPE_STRING, val)
				end
				if key == "maxparticles" then
					ptC:SetMaxParticleCount(toint(val))
				end
				if key == "emission_rate" then
					ptC:SetEmissionRate(tonumber(val))
				end
				if key == "material" then
					ptC:SetMaterial(val)
				end
				if key == "radius" then
					ptC:SetRadius(tonumber(val))
				end
				if key == "sort_particles" then
					ptC:SetSortParticles(toboolean(val))
				end
				if key == "color" then
					ptC:SetInitialColor(Color(val))
				end
				if key == "soft_particles" then
					ptC:SetSoftParticles(toboolean(val))
				end
				if key == "rotate_with_emitter" then
					set_flag(ents.ParticleSystemComponent.FLAG_BIT_ROTATE_WITH_EMITTER, toboolean(val))
				end
				if key == "move_with_emitter" then
					set_flag(ents.ParticleSystemComponent.FLAG_BIT_MOVE_WITH_EMITTER, toboolean(val))
				end
				if key == "premultiply_alpha" then
					set_flag(ents.ParticleSystemComponent.FLAG_BIT_PREMULTIPLY_ALPHA, toboolean(val))
				end
				if key == "texture_scrolling_enabled" then
					set_flag(ents.ParticleSystemComponent.FLAG_BIT_TEXTURE_SCROLLING_ENABLED, toboolean(val))
				end
				if key == "cast_shadows" then
					set_flag(ents.ParticleSystemComponent.FLAG_BIT_CAST_SHADOWS, toboolean(val))
				end
				if key == "loop" then
					local flags = ptC:GetEntity():GetSpawnFlags()
					local flag = ents.ParticleSystemComponent.SF_PARTICLE_SYSTEM_CONTINUOUS
					if toboolean(val) then
						flags = bit.bor(flags, flag)
					else
						flags = bit.band(flags, bit.bnot(flag))
					end
					ptC:GetEntity():SetKeyValue("spawnflags", tostring(flags))
				end
				if key == "max_node_count" then
					ptC:SetMaxNodes(toint(val))
				end
				if key == "alpha_mode" then
					ptC:SetAlphaMode(toint(val))
				end
			elseif udmOperator ~= nil then
				local udmKeyValues = udmOperator:Get("keyValues")
				if udmKeyValues:IsValid() == false then
					udmKeyValues = udmOperator:Add("keyValues")
				end
				if udmKeyValues:IsValid() then
					local type = udmKeyValues:Get(key):GetType()
					if type == udm.TYPE_NIL or type == udm.TYPE_INVALID then
						type = get_def_type(keyValueBlock, key) or type
					end
					val = udm.convert(val, udm.TYPE_STRING, type)
					if type == udm.TYPE_SRGBA then
						val = Color(val[1] or 255, val[2] or 255, val[3] or 255, val[4] or 255):ToVector4()
						type = udm.TYPE_VECTOR4
					end
					if val ~= nil then
						udmKeyValues:SetValue(key, type, val)
					else
						self:LogWarn(
							"Failed to convert keyvalue '"
								.. key
								.. "' from type 'string' to '"
								.. udm.enum_type_to_ascii(type)
								.. "'!"
						)
					end
				end
			end

			self:ReloadParticleSystem(self.m_ptName)
			self:UpdateSaveButton(false)
		end
		for name, kvData in pairs(keyValueBlock:GetChildren()) do
			local locName = locale.get_text("pts_" .. opType .. "_" .. name)
			local type = kvData:GetValue("type", udm.TYPE_STRING)
			local ctrl
			if type == "float" or type == "int32" then -- or type == "bool") then
				local min = kvData:GetValue("min", udm.TYPE_FLOAT) or 0.0
				local max = kvData:GetValue("max", udm.TYPE_FLOAT) or 0.0
				local default = kvData:GetValue("default", udm.TYPE_FLOAT) or 0.0
				local stepSize = kvData:GetValue("step_size", udm.TYPE_FLOAT) or 1 --0.01)
				local sliderCtrl = gui.create("pfm_slider", self.m_propertiesBox)
				sliderCtrl:SetText(locName)
				sliderCtrl:SetRange(min, max)
				sliderCtrl:SetDefault(default)
				-- sliderCtrl:SetTooltip(locale.get_text("pfm_metalness_desc"))
				sliderCtrl:SetStepSize(stepSize)

				local val = get_key_value(name)
				if val ~= nil then
					sliderCtrl:SetValue(tonumber(val))
				end

				if type == "int" or type == "bool" then
					sliderCtrl:SetInteger()
				end
				sliderCtrl:AddCallback("OnLeftValueChanged", function(el, value)
					set_key_value(name, tostring(value))
					self:ReloadParticle()
				end)
				ctrl = sliderCtrl
			elseif type == "bool" then
				local default = kvData:GetValue("default", udm.TYPE_BOOLEAN) or false
				local checkbox = gui.create("toggle_option", self.m_propertiesBox)
				checkbox:SetChecked(default)

				local val = get_key_value(name)
				if val ~= nil then
					checkbox:SetChecked(toboolean(val))
				end

				checkbox:GetCheckbox():AddCallback("OnChange", function(el, value)
					set_key_value(name, value and "1" or "0")
					self:ReloadParticle()
				end)
				local wrapper = checkbox:Wrap("editable_entry")
				checkbox:SetText(locName)
				ctrl = wrapper
			elseif type == "string" or type == "vec3" or type == "vec4" then
				local default = kvData:GetValue("default", udm.TYPE_STRING) or ""
				local teCtrl = gui.create("WITextEntry", self.m_propertiesBox)
				local wrapper = teCtrl:Wrap("editable_entry")
				wrapper:SetText(locName)
				teCtrl:SetText(default)

				local val = get_key_value(name)
				if val ~= nil then
					teCtrl:SetText(tostring(val))
				end

				teCtrl:AddCallback("OnTextEntered", function(pEntry)
					set_key_value(name, pEntry:GetText())
					self:ReloadParticle()
				end)

				ctrl = wrapper
			elseif type == "enum" then
				local default = kvData:GetValue("default", udm.TYPE_INT32) or 0
				local menu = gui.create("WIDropDownMenu", self.m_propertiesBox)
				local udmValues = kvData:Get("values")
				local n = udmValues:GetSize()
				for i = 0, n - 1 do
					local val = udmValues:GetArrayValue(i, udm.TYPE_STRING)
					menu:AddOption(val, tostring(i))
				end
				local wrapper = menu:Wrap("editable_entry")
				wrapper:SetText(locName)

				local val = get_key_value(name)
				if val ~= nil then
					local idx = alpha_mode_to_enum(val)
					if idx ~= nil then
						menu:SelectOption(idx)
					end
				end
				menu:AddCallback("OnOptionSelected", function(el, option)
					local val = menu:GetOptionValue(menu:GetSelectedOption())
					set_key_value(name, val)
					self:ReloadParticle()
				end)

				ctrl = wrapper
			elseif type == "srgba" then
				local default = kvData:GetValue("default", udm.TYPE_VECTOR4) or Vector4(1, 1, 1, 1)
				default = Color(default)
				local colorCtrl = gui.create("pfm_color_entry", self.m_propertiesBox)
				local wrapper = colorCtrl:Wrap("editable_entry")
				wrapper:SetText(locName)

				local val = get_key_value(name)
				if val ~= nil then
					colorCtrl:SetColor(Color(val))
				end

				colorCtrl:GetColorProperty():AddCallback(function(oldCol, newCol)
					set_key_value(name, tostring(newCol))
					self:ReloadParticle()
				end)

				ctrl = wrapper
			else
				console.print_warning(
					"Unsupported particle field type '"
						.. type
						.. "' for key '"
						.. name
						.. "' of operator '"
						.. opType
						.. "'! Ignoring..."
				)
			end
			if util.is_valid(ctrl) then
				table.insert(self.m_properties, ctrl)
			end
		end
	end
	--[[local keyValues = op:GetKeyValues()
	for key,val in pairs(keyValues) do
		-- TODO: Init element by type??
		local te = gui.create("WITextEntry",self.m_propertiesBox)
		te:AddCallback("OnTextEntered",function(pEntry)
			
		end)
		te:Wrap("editable_entry"):SetText(text)
		table.insert(self.m_properties,te)
	end]]
end
function gui.PFMParticleEditor:DestroyParticleSystem()
	-- if(util.is_valid(self.m_particleSystem)) then self.m_particleSystem:Remove() end
end
function gui.PFMParticleEditor:LoadParticleSystem(fileName, ptName, updateViewport)
	if updateViewport == nil then
		updateViewport = true
	end

	game.precache_particle_system(fileName)
	if updateViewport then
		self.m_viewport:SetParticleSystem(ptName)
	end

	local ent = self.m_viewport:GetEntity()
	if util.is_valid(ent) then
		local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
		if ptC ~= nil then
			self.m_particleSystem = ptC:GetEntity()
			self.m_childParticleSystem = self:FindChildParticleSystem(ptName)
		end
	end

	self.m_particleFileName = fileName
	self.m_particleName = ptName

	self:ReloadParticleProperties()
end
function gui.PFMParticleEditor:SaveParticleSystem()
	local particleSystems = {}

	--local success = game.save_particle_system("particles/ciri/fireplace_2.pptsys",particleSystems)
end
function gui.PFMParticleEditor:GetParticleSystem()
	return util.is_valid(self.m_particleSystem) and self.m_particleSystem:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
		or nil
end
function gui.PFMParticleEditor:GetTargetParticleSystem()
	if self.m_childParticleSystem ~= nil then
		return self.m_childParticleSystem
	end
	if util.is_valid(self.m_particleSystem) then
		return self.m_particleSystem:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	end
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
function gui.PFMParticleEditor:CreateParticleSystem(fileName, ptName)
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
			local pContext = gui.open_context_menu(self)
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
function gui.PFMParticleEditor:AddInitializer(initializer)
	self:AddProperty("initializer", initializer)
end
function gui.PFMParticleEditor:AddOperator(operator)
	self:AddProperty("operator", operator)
end
function gui.PFMParticleEditor:AddEmitter(emitter)
	self:AddProperty("emitter", emitter)
end
function gui.PFMParticleEditor:AddProperty(propertyType, property)
	local ptC = self:GetTargetParticleSystem()
	if ptC == nil or ptC:FindInitializerByType(property) then
		return
	end
	local propName = property
	if propertyType == "initializer" then
		property = ptC:AddInitializer(property, {})
	elseif propertyType == "operator" then
		property = ptC:AddOperator(property, {})
	elseif propertyType == "renderer" then
		property = ptC:AddRenderer(property, {})
	end
	if property == nil then
		return
	end

	local ptUdmData = self:GetParticleEffectUdmData(self.m_particleName)
	local props = ptUdmData:Get(propertyType .. "s")
	props:Resize(props:GetSize() + 1)
	local udmEl = props:Get(props:GetSize() - 1)
	udmEl:SetValue("name", udm.TYPE_STRING, propName)

	local el = self:PopulateProperty(ptC, propertyType, property)

	self.m_operatorData[el].udmOperator = udmEl
end
function gui.PFMParticleEditor:RemoveProperty(propertyType, property)
	local ptUdmData = self:GetParticleEffectUdmData(self.m_particleName)
	local props = ptUdmData:Get(propertyType .. "s")
	for i, child in ipairs(props:GetArrayValues()) do
		local name = child:GetValue("name", udm.TYPE_STRING) or ""
		if name == property then
			props:RemoveValue(i - 1)
			break
		end
	end

	self:ReloadParticleSystem(self.m_ptName)
	self:UpdateSaveButton(false)
end
function gui.PFMParticleEditor:ReloadParticleSystem(ptName)
	local ptC = self:GetTargetParticleSystem()
	if util.is_valid(ptC) then
		local name = ptName
		ptC:Clear()

		local res, err = game.register_particle_system(
			name,
			self.m_udmData:Get("particleSystemDefinitions"):Get(name):Get("assetData")
		)
		if res then
			ptC:InitializeFromParticleSystemDefinition(name)
			ptC:Start()
		else
			self:LogWarn("Failed to register particle system '" .. name .. "': " .. err)
		end
	end
end
function gui.PFMParticleEditor:PopulateProperty(ptC, propertyType, property)
	local type = property:GetType()
	local el = self.m_propertyItems[propertyType]:AddItem(locale.get_text("pts_" .. type))
	self.m_operatorData[el] = {
		operatorType = propertyType,
		type = type,
	}
	el:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu(self)
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("remove"), function()
				self.m_propertyItems[propertyType]:ScheduleUpdate()
				self.m_operatorData[el] = nil
				util.remove(el, true)
				self:RemoveProperty(propertyType, type)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	return el
end
function gui.PFMParticleEditor:PopulateParticleProperties()
	local pt = self:GetTargetParticleSystem()
	local ptC = util.is_valid(ent) and ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM) or nil
	if ptC == nil then
		return
	end
	for _, initializer in ipairs(ptC:GetInitializers()) do
		self:PopulateProperty(ptC, "initializer", initializer)
	end
	for _, op in ipairs(ptC:GetOperators()) do
		self:PopulateProperty(ptC, "operator", op)
	end
	for _, renderer in ipairs(ptC:GetRenderers()) do
		self:PopulateProperty(ptC, "renderer", renderer)
	end
end
function gui.PFMParticleEditor:ReloadParticle()
	local pt = self:GetTargetParticleSystem()
	if util.is_valid(ent) == false then
		return
	end
	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if toggleC ~= nil then
		toggleC:TurnOff()
		toggleC:TurnOn()
	end
	self.m_viewport:Render()
end
function gui.PFMParticleEditor:ClearAttributes()
	for _, el in ipairs(self.m_properties) do
		if el:IsValid() then
			el:Remove()
		end
	end
	self.m_properties = {}
end
function gui.PFMParticleEditor:SetKeyValue(key, val)

	-- Remove particle and re-create
end
gui.register("pfm_particle_editor", gui.PFMParticleEditor)
