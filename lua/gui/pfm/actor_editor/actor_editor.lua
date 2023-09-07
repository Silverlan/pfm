--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../slider.lua")
include("../treeview.lua")
include("../weightslider.lua")
include("../controls_menu.lua")
include("../entry_edit_window.lua")
include("/gui/wimodeldialog.lua")
include("/pfm/raycast.lua")
include("/pfm/component_manager.lua")
include("/pfm/component_actions.lua")
include("/pfm/util.lua")

util.register_class("gui.PFMActorEditor", gui.Base)

include("actor.lua")
include("actor_presets.lua")
include("collections.lua")
include("selection.lua")
include("ui.lua")
include("util.lua")
include("animation.lua")
include("actor_components.lua")

function gui.PFMActorEditor:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 128)

	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(54, 54, 54))

	self.navBar = gui.create("WIHBox", self)
	self:InitializeNavigationBar()

	self.navBar:SetHeight(32)
	self.navBar:SetAnchor(0, 0, 1, 0)
	self.m_activeControls = {}

	self.m_btTools = gui.PFMButton.create(self, "gui/pfm/icon_gear", "gui/pfm/icon_gear_activated", function()
		print("TODO")
	end)
	self.m_btTools:SetName("new_actor_button")
	self.m_btTools:SetX(self:GetWidth() - self.m_btTools:GetWidth())
	local function addPresetActorOption(id, subMenu, type, locId, callback)
		local subItem = subMenu:AddItem(locale.get_text(locId), function()
			local actor = self:CreatePresetActor(type)
			if callback ~= nil then
				callback()
			end

			pfm.undoredo.push("add_actor", pfm.create_command("add_actor", self:GetFilmClip(), { actor }))
		end)
		subItem:SetTooltip(locale.get_text(locId .. "_desc"))
		subItem:SetName(id)
	end
	local function addPresetModelActorOption(id, subMenu, type, locId)
		local subItem = subMenu:AddItem(locale.get_text(locId), function()
			gui.open_model_dialog(function(dialogResult, mdlName)
				if dialogResult ~= gui.DIALOG_RESULT_OK then
					return
				end
				if self:IsValid() == false then
					return
				end
				local actor = self:CreatePresetActor(type, { ["modelName"] = mdlName })
				pfm.undoredo.push("add_actor", pfm.create_command("add_actor", self:GetFilmClip(), { actor }))
			end)
		end)
		subItem:SetTooltip(locale.get_text(locId .. "_desc"))
		subItem:SetName(id)
	end
	self.m_btTools:SetupContextMenu(function(pContext)
		addPresetModelActorOption(
			"static_prop",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP,
			"pfm_create_new_static_prop"
		)
		addPresetModelActorOption(
			"dynamic_prop",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_DYNAMIC_PROP,
			"pfm_create_new_dynamic_prop"
		)
		addPresetModelActorOption(
			"articulated_actor",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR,
			"pfm_create_new_articulated_actor"
		)

		addPresetActorOption("camera", pContext, gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA, "pfm_create_new_camera")
		addPresetActorOption(
			"particle_system",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_PARTICLE_SYSTEM,
			"pfm_create_new_particle_system"
		)
		addPresetActorOption(
			"spot_light",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_SPOT_LIGHT,
			"pfm_create_new_spot_light"
		)
		addPresetActorOption(
			"point_light",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_POINT_LIGHT,
			"pfm_create_new_point_light"
		)
		addPresetActorOption(
			"directional_light",
			pContext,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_DIRECTIONAL_LIGHT,
			"pfm_create_new_directional_light"
		)
		--[[pContext:AddItem(locale.get_text("pfm_create_new_volume_simple"),function()
			local actor = self:CreateNewActor()
			if(actor == nil) then return end
			local mdlC = self:CreateNewActorComponent(actor,"pfm_model",false,function(mdlC) actor:ChangeModel("cube_volumetric") end)
			self:CreateNewActorComponent(actor,"pfm_volumetric",false)

			local transform = actor:GetTransform()
			transform:SetScale(Vector(10,10,10))
			actor:SetTransform(transform)
			self:UpdateActorComponents(actor)
		end)]]
		addPresetActorOption("volume", pContext, gui.PFMActorEditor.ACTOR_PRESET_TYPE_VOLUME, "pfm_create_new_volume")
		addPresetActorOption("actor", pContext, gui.PFMActorEditor.ACTOR_PRESET_TYPE_ACTOR, "pfm_create_new_actor")

		local filmClip = self:GetFilmClip()
		local hasSkyComponent = false
		local hasFogComponent = false
		local hasLightmapperComponent = false
		local hasVrManagerComponent = false
		if filmClip ~= nil then
			for _, actor in ipairs(filmClip:GetActorList()) do
				local c = actor:FindComponent("pfm_sky")
				if c ~= nil then
					hasSkyComponent = true
				end
				local c = actor:FindComponent("fog_controller")
				if c ~= nil then
					hasFogComponent = true
				end
				local c = actor:FindComponent("pfm_baked_lighting")
				if c ~= nil then
					hasLightmapperComponent = true
				end
				local c = actor:FindComponent("pfm_vr_manager")
				if c ~= nil then
					hasVrManagerComponent = true
				end
			end
		end

		local pBakingItem, pBakingMenu = pContext:AddSubMenu(locale.get_text("pfm_baking"))
		pBakingItem:SetName("baking")
		if hasLightmapperComponent == false then
			addPresetActorOption(
				"lightmapper",
				pBakingMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_LIGHTMAPPER,
				"pfm_create_lightmapper",
				pBakingMenu
			)
		end
		addPresetActorOption(
			"reflection_probe",
			pBakingMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_REFLECTION_PROBE,
			"pfm_create_reflection_probe",
			pBakingMenu
		)
		pBakingMenu:Update()
		if hasSkyComponent == false then
			addPresetActorOption("sky", pContext, gui.PFMActorEditor.ACTOR_PRESET_TYPE_SKY, "pfm_add_sky")
		end
		if hasFogComponent == false then
			addPresetActorOption(
				"fog_controller",
				pContext,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_FOG,
				"pfm_create_new_fog_controller"
			)
		end
		addPresetActorOption("decal", pContext, gui.PFMActorEditor.ACTOR_PRESET_TYPE_DECAL, "pfm_create_new_decal")

		local pVrItem, pVrMenu = pContext:AddSubMenu(locale.get_text("virtual_reality"))
		pVrItem:SetName("virtual_reality")
		if hasVrManagerComponent == false then
			addPresetActorOption(
				"vr_manager",
				pVrMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_VR_MANAGER,
				"pfm_create_vr_manager",
				function()
					local actor = self:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA, {
						name = "vr_camera",
						collection = gui.PFMActorEditor.COLLECTION_VR,
						updateActorComponents = false,
					})
					self:CreateNewActorComponent(actor, "pfm_vr_camera", false)
					self:UpdateActorComponents(actor)
				end
			)
		end
		pVrMenu:Update()

		if tool.get_filmmaker():IsDeveloperModeEnabled() then
			local pConstraintItem, pConstraintMenu = pContext:AddSubMenu(locale.get_text("constraints"))
			pConstraintItem:SetName("constraints")
			addPresetActorOption(
				"copy_location_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION,
				"pfm_create_copy_location_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"copy_rotation_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION,
				"pfm_create_copy_rotation_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"copy_scale_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE,
				"pfm_create_copy_scale_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"limit_distance_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE,
				"pfm_create_limit_distance_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"limit_location_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION,
				"pfm_create_limit_location_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"limit_rotation_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION,
				"pfm_create_limit_rotation_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"limit_scale_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE,
				"pfm_create_limit_scale_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"look_at_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT,
				"pfm_create_look_at_constraint",
				pConstraintMenu
			)
			addPresetActorOption(
				"child_of_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF,
				"pfm_create_child_of_constraint",
				pConstraintMenu
			)
			pConstraintMenu:Update()

			addPresetActorOption(
				"animation_driver",
				pContext,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_ANIMATION_DRIVER,
				"pfm_create_animation_driver"
			)
		end

		--[[local pEntsItem,pEntsMenu = pContext:AddSubMenu(locale.get_text("pfm_add_preset"))
		local types = ents.get_registered_entity_types()
		table.sort(types)
		for _,typeName in ipairs(types) do
			pEntsMenu:AddItem(typeName,function()
				local actor = self:CreateNewActor()
				if(actor == nil) then return end
				-- TODO: Add entity core components

				self:AddActorToScene(actor)
			end)
		end
		pEntsMenu:Update()]]

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
	end, true)

	self.m_contents = gui.create(
		"WIHBox",
		self,
		0,
		self.m_btTools:GetBottom(),
		self:GetWidth(),
		self:GetHeight() - self.m_btTools:GetBottom(),
		0,
		0,
		1,
		1
	)
	self.m_contents:SetAutoFillContents(true)

	local treeScrollContainerBg = gui.create("WIRect", self.m_contents, 0, 0, 64, 128)
	treeScrollContainerBg:SetColor(Color(38, 38, 38))
	local treeScrollContainer = gui.create("WIScrollContainer", treeScrollContainerBg, 0, 0, 64, 128, 0, 0, 1, 1)
	self.m_treeScrollContainer = treeScrollContainer
	--treeScrollContainer:SetFixedSize(true)
	--[[local bg = gui.create("WIRect",treeScrollContainer,0,0,treeScrollContainer:GetWidth(),treeScrollContainer:GetHeight(),0,0,1,1)
	bg:SetColor(Color(38,38,38))
	treeScrollContainer:SetBackgroundElement(bg)]]

	local resizer = gui.create("WIResizer", self.m_contents)
	self.m_centralDivider = resizer
	local dataVBox = gui.create("WIVBox", self.m_contents)
	dataVBox:SetFixedSize(true)
	dataVBox:SetAutoFillContentsToWidth(true)
	dataVBox:SetAutoFillContentsToHeight(true)

	local propertiesHBox = gui.create("WIHBox", dataVBox)
	propertiesHBox:SetAutoFillContents(true)
	self.m_propertiesHBox = propertiesHBox

	local propertiesLabelsVBox = gui.create("WIVBox", propertiesHBox)
	propertiesLabelsVBox:SetAutoFillContentsToWidth(true)
	propertiesLabelsVBox:SetName("property_labels")
	self.m_propertiesLabelsVBox = propertiesLabelsVBox

	gui.create("WIResizer", propertiesHBox)

	local propertiesElementsVBox = gui.create("WIVBox", propertiesHBox)
	propertiesElementsVBox:SetName("base_property_controls")
	propertiesElementsVBox:SetAutoFillContentsToWidth(true)
	self.m_propertiesElementsVBox = propertiesElementsVBox

	gui.create("WIResizer", dataVBox)

	local animSetControls
	local scrollContainer = gui.create("WIScrollContainer", dataVBox)
	scrollContainer:AddCallback("SetSize", function(el)
		if self:IsValid() and util.is_valid(animSetControls) then
			animSetControls:SetWidth(el:GetWidth())
		end
	end)

	animSetControls =
		gui.create("WIPFMControlsMenu", scrollContainer, 0, 0, scrollContainer:GetWidth(), scrollContainer:GetHeight())
	animSetControls:SetName("property_controls")
	animSetControls:SetAutoFillContentsToWidth(true)
	animSetControls:SetAutoFillContentsToHeight(false)
	animSetControls:SetFixedHeight(false)
	animSetControls:AddCallback("OnControlAdded", function(el, name, ctrl, wrapper)
		if wrapper ~= nil then
			wrapper:AddCallback("OnValueChanged", function()
				local filmmaker = tool.get_filmmaker()
				filmmaker:TagRenderSceneAsDirty()
			end)
		end
	end)
	self.m_animSetControls = animSetControls

	self.m_sliderControls = {}

	self.m_tree = gui.create(
		"WIPFMTreeView",
		treeScrollContainer,
		0,
		0,
		treeScrollContainer:GetWidth(),
		treeScrollContainer:GetHeight()
	)
	self.m_tree:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)
	self.m_tree:SetName("actor_tree")
	self.m_treeElementToActorData = {}
	self.m_actorUniqueIdToTreeElement = {}
	self.m_tree:AddCallback("OnItemSelectChanged", function(tree, el, selected)
		local queue = {}
		if self.m_dirtyActorEntries ~= nil then
			for uniqueId, _ in pairs(self.m_dirtyActorEntries) do
				table.insert(queue, uniqueId)
			end
		end
		for _, uniqueId in ipairs(queue) do
			self:InitializeDirtyActorComponents(uniqueId)
		end
		self:ScheduleUpdateSelectedEntities()
	end)
	self.m_tree:AddCallback("OnContentsWidthDirty", function()
		time.create_simple_timer(0.0, function()
			if self:IsValid() and util.is_valid(self.m_tree) then
				local w = self.m_tree:CalcContentsWidth()
				local scrollBar = treeScrollContainer:GetVerticalScrollBar()
				if util.is_valid(scrollBar) and scrollBar:IsVisible() then
					w = w + 20
				end
				self.m_tree:SetWidth(w)
			end
		end)
	end)
	--[[self.m_data = gui.create("WITable",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)

	self.m_data:SetRowHeight(self.m_tree:GetRowHeight())
	self.m_data:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)]]

	self.m_componentManager = pfm.ComponentManager()

	self.m_leftRightWeightSlider = gui.create("WIPFMWeightSlider", self.m_animSetControls)
	self.m_specialPropertyIcons = {}

	local animManager = tool.get_filmmaker():GetAnimationManager()
	self.m_callbacks = {}
	table.insert(
		self.m_callbacks,
		animManager:AddCallback("OnChannelAdded", function(actor, path)
			local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
			local componentId = (componentName ~= nil) and ents.get_component_id(componentName) or nil
			if componentId == nil then
				return
			end
			self:UpdatePropertyIcons(
				actor:GetUniqueId(),
				componentId,
				"ec/" .. componentName .. "/" .. pathName:GetString()
			)
		end)
	)
	table.insert(
		self.m_callbacks,
		animManager:AddCallback("OnChannelRemoved", function(actor, path)
			local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
			local componentId = (componentName ~= nil) and ents.get_component_id(componentName) or nil
			if componentId == nil then
				return
			end
			self:UpdatePropertyIcons(
				actor:GetUniqueId(),
				componentId,
				"ec/" .. componentName .. "/" .. pathName:GetString()
			)
		end)
	)

	self:SetMouseInputEnabled(true)
end
function gui.PFMActorEditor:GetToolIconElement()
	return self.m_btTools
end
function gui.PFMActorEditor:GetCentralDivider()
	return self.m_centralDivider
end
function gui.PFMActorEditor:GetTree()
	return self.m_tree
end
function gui.PFMActorEditor:GetActorItem(actor)
	for item, actorData in pairs(self.m_treeElementToActorData) do
		if util.is_same_object(actorData.actor, actor) then
			return item
		end
	end
end
function gui.PFMActorEditor:TagRenderSceneAsDirty(dirty)
	tool.get_filmmaker():TagRenderSceneAsDirty(dirty)
end
function gui.PFMActorEditor:GetTimelineMode()
	local timeline = tool.get_filmmaker():GetTimeline()
	if util.is_valid(timeline) == false then
		return gui.PFMTimeline.EDITOR_CLIP
	end
	return timeline:GetEditor()
end
function gui.PFMActorEditor:GetMemberInfo(actor, path)
	return pfm.get_member_info(path, actor:FindEntity())
end
function gui.PFMActorEditor:ScheduleUpdateSelectedEntities()
	if self.m_updateSelectedEntities then
		return
	end
	self:EnableThinking()
	self.m_updateSelectedEntities = true
end
function gui.PFMActorEditor:OnThink()
	if self.m_updateSelectedEntities then
		self:UpdateSelectedEntities()
	end
	if self.m_controlOverlayUpdateRequired then
		self.m_controlOverlayUpdateRequired = nil
		self:UpdateAnimatedPropertyOverlays()
	end
	if self.m_dirtyActorComponents ~= nil then
		for uniqueId, components in pairs(self.m_dirtyActorComponents) do
			for componentId, _ in pairs(components) do
				self:RemoveActorComponentEntry(uniqueId, componentId)
			end
			self:SetActorDirty(uniqueId)
			self:InitializeDirtyActorComponents(uniqueId)
		end
		self.m_dirtyActorComponents = nil
	end
	if self.m_updatePropertyIcons then
		self.m_updatePropertyIcons = nil
		self:UpdateConstraintPropertyIcons()
	end
	self:DisableThinking()
end
function gui.PFMActorEditor:GetFilmClip()
	return self.m_filmClip
end
function gui.PFMActorEditor:SetActorDirty(uniqueId)
	if type(uniqueId) ~= "string" then
		uniqueId = tostring(uniqueId)
	end
	self.m_dirtyActorEntries = self.m_dirtyActorEntries or {}
	self.m_dirtyActorEntries[uniqueId] = true
end
function gui.PFMActorEditor:SetActorComponentDirty(uniqueId, componentId)
	if type(uniqueId) ~= "string" then
		uniqueId = tostring(uniqueId)
	end
	self.m_dirtyActorComponents = self.m_dirtyActorComponents or {}
	self.m_dirtyActorComponents[uniqueId] = self.m_dirtyActorComponents[uniqueId] or {}
	self.m_dirtyActorComponents[uniqueId][componentId] = true
	self:EnableThinking()
end
function gui.PFMActorEditor:OnActorPropertyChanged(entActor)
	local pm = pfm.get_project_manager()
	local vp = util.is_valid(pm) and pm:GetViewport() or nil
	local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
	if rt == nil then
		return
	end
	rt:MarkActorAsDirty(entActor)
end
function gui.PFMActorEditor:DeleteSelectedActors()
	local ids = {}
	for _, actor in ipairs(self:GetSelectedActors()) do
		if actor:IsValid() then
			table.insert(ids, tostring(actor:GetUniqueId()))
		end
	end

	self:RemoveActors(ids)
end
function gui.PFMActorEditor:CopyToClipboard(actors)
	actors = actors or self:GetSelectedActors()
	local el = udm.create_element()
	self:WriteActorsToUdmElement(self:GetFilmClip(), actors, el)
	util.set_clipboard_string(el:ToAscii(udm.ASCII_SAVE_FLAG_NONE))
end
function gui.PFMActorEditor:PasteFromClipboard(keepOriginalUuids)
	local res, err = udm.parse(util.get_clipboard_string())
	if res == false then
		console.print_warning("Failed to parse UDM: ", err)
		return
	end
	local data = res:GetAssetData():GetData()
	self:RestoreActorsFromUdmElement(self:GetFilmClip(), data, keepOriginalUuids)
end
function gui.PFMActorEditor:WriteActorsToUdmElement(...)
	return pfm.get_project_manager():WriteActorsToUdmElement(...)
end
function gui.PFMActorEditor:RestoreActorsFromUdmElement(...)
	return pfm.get_project_manager():RestoreActorsFromUdmElement(...)
end
function gui.PFMActorEditor:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
		local pContext = gui.open_context_menu()
		if util.is_valid(pContext) == false then
			return
		end
		pContext:SetPos(input.get_cursor_pos())

		pContext
			:AddItem(locale.get_text("pfm_copy_actors"), function()
				self:CopyToClipboard()
			end)
			:SetName("copy_actors")
		pContext
			:AddItem(locale.get_text("pfm_paste_actors"), function()
				self:PasteFromClipboard()
			end)
			:SetName("paste_actors")
		pContext:Update()
		return util.EVENT_REPLY_HANDLED
	end
end
function gui.PFMActorEditor:Reload()
	if self.m_filmClip == nil then
		return
	end
	self:Setup(self.m_filmClip)
end
function gui.PFMActorEditor:Clear()
	-- if(util.is_same_object(filmClip,self.m_filmClip)) then return end
	util.remove(self.m_filmClipCallbacks)

	debug.start_profiling_task("pfm_populate_actor_editor")
	asset.clear_unused()
	self.m_tree:Clear()
	self.m_treeElementToActorData = {}
	self.m_actorUniqueIdToTreeElement = {}
	self.m_filmClipCallbacks = {}
end
function gui.PFMActorEditor:OnEditorChannelKeyframeAdded(actor, targetPath, valueBaseIndex)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()

	animManager:SetAnimationDirty(actor) -- TODO: Move this to core filmmaker
	pfm.tag_render_scene_as_dirty()

	self:UpdateActorProperty(actor, targetPath)
end
function gui.PFMActorEditor:UpdateChannelValue(data, editorChannel)
	-- TODO: Mark as dirty, then update lazily?
	--[[local udmChannel = data.udmChannel
	local rebuildGraphCurves = false
	local curve = editorChannel:GetGraphCurve()
	local editorKeys = curve:GetEditorKeys()
	if editorKeys == nil or graphData.numValues ~= editorKeys:GetTimeCount() then
		-- Number of keyframe keys has changed, we'll have to rebuild the entire curve
		self:RebuildGraphCurve(graphIdx, graphData)
	elseif data.fullUpdateRequired then
		rebuildGraphCurves = true
	elseif data.keyIndex ~= nil then
		-- We only have to rebuild the two curve segments connected to the key
		self:ReloadGraphCurveSegment(graphIdx, data.keyIndex)
		rebuildGraphCurves = true

		-- Also update key data point position
		if data.oldKeyIndex ~= nil then
			self:ReloadGraphCurveSegment(graphIdx, data.oldKeyIndex)
			rebuildGraphCurves = true
			graphData.curve:SwapDataPoints(data.oldKeyIndex, data.keyIndex)
			graphData.curve:UpdateDataPoints()
		else
			graphData.curve:UpdateDataPoint(data.keyIndex + 1)
		end
	elseif data.oldKeyIndex ~= nil then
		-- Key was deleted; Perform full update
		-- TODO: If multiple keys are deleted at once, only do this once instead of for every single key
		self:RebuildGraphCurve(graphIdx, graphData)
	end

	if rebuildGraphCurves then
		local indices = self:FindGraphDataIndices(data.actor, udmChannel:GetTargetPath(), data.typeComponentIndex)
		for _, graphIdx in ipairs(indices) do
			self:RebuildGraphCurve(graphIdx, self.m_graphs[graphIdx], true)
		end
	end]]
end
function gui.PFMActorEditor:Setup(filmClip)
	self:Clear()
	self.m_filmClip = filmClip

	local function add_change_listener(identifier, fc)
		table.insert(self.m_filmClipCallbacks, filmClip:AddChangeListener(identifier, fc))
	end
	add_change_listener("OnActorRemoved", function(filmClip, uuid, partOfBatch)
		if partOfBatch then
			return
		end
		self:OnActorsRemoved(filmClip, { uuid })
	end)
	add_change_listener("OnActorsRemoved", function(filmClip, uuids)
		self:OnActorsRemoved(filmClip, uuids)
	end)
	add_change_listener("OnGroupAdded", function(filmClip, group)
		self:OnCollectionAdded(group)
	end)
	add_change_listener("OnGroupRemoved", function(filmClip, groupUuid)
		self:OnCollectionRemoved(groupUuid)
	end)
	add_change_listener("OnActorComponentAdded", function(filmClip, actor, componentType)
		if self.m_skipComponentCallbacks then
			return
		end
		self:OnActorComponentAdded(filmClip, actor, componentType)
	end)
	add_change_listener("OnActorComponentRemoved", function(filmClip, actor, componentType)
		if self.m_skipComponentCallbacks then
			return
		end
		self:OnActorComponentRemoved(filmClip, actor, componentType)
	end)
	add_change_listener(
		"OnEditorChannelKeyframeAdded",
		function(filmClip, track, animationClip, editorChannel, keyData, keyframeIndex, valueBaseIndex)
			self:OnEditorChannelKeyframeAdded(animationClip:GetActor(), editorChannel:GetTargetPath(), valueBaseIndex)
		end
	)

	local function add_actors(parent, parentItem, root)
		local itemGroup = self:AddCollectionItem(parentItem or self.m_tree, parent, root)
		if root then
			itemGroup:SetText("Scene")
			itemGroup:Expand()
		end
		for _, group in ipairs(parent:GetGroups()) do
			add_actors(group, itemGroup)
		end
		for _, actor in ipairs(parent:GetActors()) do
			local itemActor = self:AddActor(actor, itemGroup)
			local itemParent = util.is_valid(itemActor) and itemActor:GetParentItem() or nil
			if util.is_valid(itemParent) then
				itemParent:Collapse()
			end
		end
	end

	local function add_film_clip(filmClip, root)
		add_actors(filmClip:GetScene(), nil, root)
		for _, trackGroup in ipairs(filmClip:GetTrackGroups()) do
			for _, track in ipairs(trackGroup:GetTracks()) do
				for _, filmClip in ipairs(track:GetFilmClips()) do
					add_film_clip(filmClip)
				end
			end
		end
	end
	add_film_clip(filmClip, true)

	--[[for _,actor in ipairs(filmClip:GetActorList()) do
		self:AddActor(actor)
	end]]
	asset.clear_unused()
	debug.stop_profiling_task()
end
function gui.PFMActorEditor:AddProperty(name, child, fInitPropertyEl)
	--[[local elLabelContainer
	local elProperty
	local elHeight = 24
	child:AddCallback("OnSelected",function()
		print("OnSelected")
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
			elProperty:AddCallback("OnRemove",function() util.remove(elLabelContainer) end)
		end
	end)
	local function cleanUp()
		util.remove(elLabelContainer,true)
		util.remove(elProperty,true)
	end
	child:AddCallback("OnDeselected",cleanUp)
	child:AddCallback("OnRemove",cleanUp)]]

	local elHeight = 24
	local elLabelContainer = gui.create("WIBase", self.m_propertiesLabelsVBox)
	elLabelContainer:SetHeight(elHeight)

	local elLabel = gui.create("WIText", elLabelContainer)
	elLabel:SetName(name)
	elLabel:SetText(name)
	elLabel:SetColor(Color(200, 200, 200))
	elLabel:SetFont("pfm_medium")
	elLabel:SizeToContents()
	elLabel:CenterToParentY()
	elLabel:SetX(5)

	local elProperty = fInitPropertyEl(self.m_propertiesElementsVBox)
	if util.is_valid(elProperty) then
		elProperty:SetHeight(elHeight)
		elProperty:AddCallback("OnRemove", function()
			util.remove(elLabelContainer)
		end)
	end
	return elProperty
end
function gui.PFMActorEditor:GetActiveControls()
	return self.m_activeControls
end
function gui.PFMActorEditor:UpdateActorProperty(actor, path)
	local uid = tostring(actor:GetUniqueId())
	if self.m_activeControls[uid] == nil then
		return
	end
	local t = self.m_activeControls[uid]
	if t[path] == nil then
		return
	end
	local ac = t[path]
	self:UpdateControlValue(ac.controlData)
end
function gui.PFMActorEditor:UpdateControlValue(controlData)
	if controlData.updateControlValue == nil then
		return
	end
	self.m_skipUpdateCallback = true
	controlData.updateControlValue()
	self.m_skipUpdateCallback = nil
end
function gui.PFMActorEditor:UpdateControlValues()
	for uid, t in pairs(self.m_activeControls) do
		for path, ac in pairs(t) do
			self:UpdateControlValue(ac.controlData)
		end
	end
end
function gui.PFMActorEditor:ApplyComponentChannelValue(actorEditor, component, controlData, oldValue, value)
	local actor = component:GetActor()
	if actor ~= nil and controlData.path ~= nil then
		actorEditor:UpdateAnimationChannelValue(actor, controlData.path, oldValue, value)
	end
end
function gui.PFMActorEditor:OnControlSelected(actor, actorData, udmComponent, controlData)
	local memberInfo = self:GetMemberInfo(actor, controlData.path)
	if memberInfo == nil then
		-- TODO: Members can become invalid if, for example, an actor's model has changed. In this case, the entire tree in the actor editor should be reloaded!
		console.print_warning(
			"Attempted to access member info for property '"
				.. controlData.path
				.. "' for actor '"
				.. tostring(actor)
				.. "', but member is no longer valid!"
		)
		return
	end

	local baseMemberName = memberInfo.name
	local t = string.split(baseMemberName, "/")
	baseMemberName = t[#t]

	local ctrl
	if controlData.path ~= nil then
		if memberInfo:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_READ_ONLY_BIT) then
			local elText, wrapper =
				self.m_animSetControls:AddText(baseMemberName, memberInfo.name, controlData.default or "")
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if elText:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						elText:SetText(val)
					end
				end
			end
			ctrl = wrapper
		elseif memberInfo.type == ents.MEMBER_TYPE_ENTITY then
			local elText, wrapper = self.m_animSetControls:AddTextEntry(
				baseMemberName,
				memberInfo.name,
				controlData.default or "",
				function(el)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						local ref = ents.UniversalEntityReference(util.Uuid(el:GetText()))
						controlData.set(udmComponent, ref, nil, nil, true)
					end
				end
			)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if elText:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						local uuid = val:GetUuid()
						if uuid ~= nil then
							if uuid:IsValid() then
								elText:SetText(tostring(uuid))
							else
								elText:SetText("-")
							end
						end
					end
				end
			end
			ctrl = wrapper
		elseif memberInfo.type == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
			local elText, wrapper = self.m_animSetControls:AddTextEntry(
				baseMemberName,
				memberInfo.name,
				controlData.default or "",
				function(el)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						local ref = ents.UniversalMemberReference(el:GetText())
						controlData.set(udmComponent, ref, nil, nil, true)
					end
				end
			)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if elText:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						local path = val:GetPath()
						if path ~= nil then
							elText:SetText(path)
						else
							elText:SetText("-")
						end
					end
				end
			end
			ctrl = wrapper
		elseif memberInfo.type == ents.MEMBER_TYPE_ELEMENT then
			local bt = self.m_animSetControls:AddButton(
				locale.get_text("edit") .. " " .. baseMemberName,
				memberInfo.name,
				function()
					local filmmaker = tool.get_filmmaker()
					local tab, el = filmmaker:OpenWindow("element_viewer")
					filmmaker:GoToWindow("element_viewer")
					if util.is_valid(el) then
						local elUdm = controlData.getValue()
						local rootPath
						if memberInfo.metaData ~= nil then
							rootPath = memberInfo.metaData:GetValue("rootPath", udm.TYPE_STRING)
						end
						el:InitializeFromUdmElement(elUdm, nil, function()
							local entActor, c, memberIdx, info = controlData.getActor()
							if info == nil then
								return true
							end
							if controlData.set ~= nil then
								controlData.set(udmComponent, elUdm)
							end
							-- c:OnMemberValueChanged(memberIdx)
							return true
						end, rootPath)
					end
				end
			)
			ctrl = bt
		elseif memberInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_COLOR then
			local colField, wrapper = self.m_animSetControls:AddColorField(
				baseMemberName,
				memberInfo.name,
				(controlData.default and Color(controlData.default)) or Color.White,
				function(oldCol, newCol)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						controlData.set(udmComponent, newCol)
					end
				end
			)
			colField:AddCallback("OnUserInputEnded", function()
				local col = colField:GetColor()
				if controlData.set ~= nil then
					controlData.set(udmComponent, col, nil, nil, true)
				end
			end)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if colField:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						colField:SetColor(Color(val))
					end
				end
			end
			ctrl = wrapper
		elseif memberInfo.type == udm.TYPE_STRING then
			if memberInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE then
				local meta = memberInfo.metaData or udm.create_element()
				if meta ~= nil then
					if meta:GetValue("assetType") == "model" then
						ctrl = self:AddProperty(memberInfo.name, child, function(parent)
							local el = gui.create("WIFileEntry", parent)
							if controlData.getValue ~= nil then
								controlData.updateControlValue = function()
									if el:IsValid() == false then
										return
									end
									local val = controlData.getValue()
									if val ~= nil then
										el:SetValue(val)
									end
								end
							end
							el:SetBrowseHandler(function(resultHandler)
								gui.open_model_dialog(function(dialogResult, mdlName)
									if dialogResult ~= gui.DIALOG_RESULT_OK then
										return
									end
									resultHandler(mdlName)
								end)
							end)
							el:AddCallback("OnValueChanged", function(el, value)
								if self.m_skipUpdateCallback then
									return
								end
								if controlData.set ~= nil then
									controlData.set(udmComponent, value, nil, nil, true)
								end
							end)
							return el
						end)
					end
				end
				if util.is_valid(ctrl) == false then
					ctrl = self:AddProperty(memberInfo.name, child, function(parent)
						local el = gui.create("WIFileEntry", parent)
						if controlData.getValue ~= nil then
							controlData.updateControlValue = function()
								if el:IsValid() == false then
									return
								end
								local val = controlData.getValue()
								if val ~= nil then
									el:SetValue(val)
								end
							end
						end
						el:SetBrowseHandler(function(resultHandler)
							local pFileDialog = gui.create_file_open_dialog(function(el, fileName)
								if fileName == nil then
									return
								end
								local basePath = meta:GetValue("basePath") or ""
								resultHandler(basePath .. el:GetFilePath(true))
							end)
							local rootPath = meta:GetValue("rootPath")
							if rootPath ~= nil then
								pFileDialog:SetRootPath(rootPath)
							end
							local extensions = meta:Get("extensions"):ToTable()
							if #extensions > 0 then
								pFileDialog:SetExtensions(extensions)
							end
							pFileDialog:Update()
						end)
						el:AddCallback("OnValueChanged", function(el, value)
							if self.m_skipUpdateCallback then
								return
							end
							if controlData.set ~= nil then
								controlData.set(udmComponent, value, nil, nil, true)
							end
						end)
						return el
					end)
				end
			else
				local elText, wrapper = self.m_animSetControls:AddTextEntry(
					baseMemberName,
					memberInfo.name,
					controlData.default or "",
					function(el)
						if self.m_skipUpdateCallback then
							return
						end
						if controlData.set ~= nil then
							controlData.set(udmComponent, el:GetText(), nil, nil, true)
						end
					end
				)
				if controlData.getValue ~= nil then
					controlData.updateControlValue = function()
						if elText:IsValid() == false then
							return
						end
						local val = controlData.getValue()
						if val ~= nil then
							elText:SetText(val)
						end
					end
				end
				ctrl = wrapper
			end
		elseif memberInfo.type == udm.TYPE_BOOLEAN then
			local elToggle, wrapper = self.m_animSetControls:AddToggleControl(
				baseMemberName,
				memberInfo.name,
				controlData.default or false,
				function(oldChecked, checked)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						controlData.set(udmComponent, checked, nil, nil, true)
					end
				end
			)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if elToggle:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						elToggle:SetChecked(val)
					end
				end
			else
				elToggle:SetChecked(false)
			end
			ctrl = wrapper
		elseif udm.is_numeric_type(memberInfo.type) then
			if memberInfo:IsEnum() then
				local enumValues = {}
				local defaultValueIndex
				for i, v in ipairs(memberInfo:GetEnumValues()) do
					local name = memberInfo:ValueToEnumName(v)
					if name ~= "Count" then
						table.insert(enumValues, { tostring(v), name })
						if v == memberInfo.default then
							defaultValueIndex = i - 1
						end
					end
				end
				local el, wrapper = self.m_animSetControls:AddDropDownMenu(
					baseMemberName,
					memberInfo.name,
					enumValues,
					tostring(defaultValueIndex),
					function(el)
						if self.m_skipUpdateCallback then
							return
						end
						if controlData.set ~= nil then
							controlData.set(
								udmComponent,
								tonumber(el:GetOptionValue(el:GetSelectedOption())),
								nil,
								nil,
								true
							)
						end
					end
				)
				ctrl = wrapper
				controlData.updateControlValue = function()
					if ctrl:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						local idx = el:FindOptionIndex(tostring(val))
						if idx ~= nil then
							el:SelectOption(idx)
						else
							el:SetText(tostring(val))
						end
					end
				end
			else
				if memberInfo.minValue ~= nil then
					controlData.min = memberInfo.minValue
				end
				if memberInfo.maxValue ~= nil then
					controlData.max = memberInfo.maxValue
				end
				if memberInfo.default ~= nil then
					controlData.default = memberInfo.default
				end

				if memberInfo.type == udm.TYPE_BOOLEAN then
					controlData.min = controlData.min and 1 or 0
					controlData.max = controlData.max and 1 or 0
					controlData.default = controlData.default and 1 or 0
				end

				local channel = self:GetAnimationChannel(actorData.actor, controlData.path, false)
				local hasExpression = (channel ~= nil and channel:GetExpression() ~= nil)
				if hasExpression == false then
					if memberInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_DISTANCE then
						controlData.unit = locale.get_text("symbol_meters")
						controlData.translateToInterface = function(val)
							return util.units_to_metres(val)
						end
						controlData.translateFromInterface = function(val)
							return util.metres_to_units(val)
						end
					elseif
						memberInfo.specializationType
						== ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_LIGHT_INTENSITY
					then
						-- TODO
						controlData.unit = locale.get_text("symbol_lumen") --(self:GetIntensityType() == ents.LightComponent.INTENSITY_TYPE_CANDELA) and locale.get_text("symbol_candela") or locale.get_text("symbol_lumen")
					end
				end
				ctrl = self:AddSliderControl(udmComponent, controlData)
				if controlData.unit then
					ctrl:SetUnit(controlData.unit)
				end

				controlData.updateControlValue = function()
					if ctrl:IsValid() == false then
						return
					end
					local val = controlData.getValue()
					if val ~= nil then
						ctrl:SetValue(val)
					end
				end

				-- pfm.log("Attempted to add control for member with path '" .. controlData.path .. "' of actor '" .. tostring(actor) .. "', but member type " .. tostring(memberInfo.specializationType) .. " is unknown!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
			end
		elseif memberInfo.type == udm.TYPE_EULER_ANGLES then
			local val = EulerAngles()
			local el, wrapper = self.m_animSetControls:AddTextEntry(
				baseMemberName,
				memberInfo.name,
				tostring(val),
				function(el)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						controlData.set(udmComponent, EulerAngles(el:GetText()), nil, nil, true)
					end
				end
			)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if el:IsValid() == false then
						return
					end
					local val = controlData.getValue() or EulerAngles()
					if val ~= nil then
						el:SetText(tostring(val))
					end
				end
			end
			ctrl = wrapper
		elseif memberInfo.type == udm.TYPE_QUATERNION then
			local val = EulerAngles()
			local el, wrapper = self.m_animSetControls:AddTextEntry(
				baseMemberName,
				memberInfo.name,
				tostring(val),
				function(el)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						controlData.set(udmComponent, EulerAngles(el:GetText()):ToQuaternion(), nil, nil, true)
					end
				end
			)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if el:IsValid() == false then
						return
					end
					local val = controlData.getValue() or Quaternion()
					if val ~= nil then
						el:SetText(tostring(val:ToEulerAngles()))
					end
				end
			end
			ctrl = wrapper
		elseif udm.is_vector_type(memberInfo.type) or udm.is_matrix_type(memberInfo.type) then
			local type = udm.get_class_type(memberInfo.type)
			local val = type()
			if controlData.getValue ~= nil then
				val = controlData.getValue() or val
			end
			local el, wrapper = self.m_animSetControls:AddTextEntry(
				baseMemberName,
				memberInfo.name,
				tostring(val),
				function(el)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						controlData.set(udmComponent, type(el:GetText()), nil, nil, true)
					end
				end
			)
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if el:IsValid() == false then
						return
					end
					local val = controlData.getValue() or type()
					if val ~= nil then
						el:SetText(tostring(val))
					end
				end
			end
			ctrl = wrapper
		else
			return ctrl
		end
	end
	if util.is_valid(ctrl) == false then
		if controlData.addControl then
			ctrl = controlData.addControl(self.m_animSetControls, function(value)
				self:ApplyComponentChannelValue(self, udmComponent, controlData, nil, value)
			end)
		else
			ctrl = self:AddSliderControl(udmComponent, controlData)
			if controlData.unit then
				ctrl:SetUnit(controlData.unit)
			end
		end
	end
	if ctrl ~= nil then
		ctrl:AddCallback("PopulateContextMenu", function(ctrl, context)
			self:PopulatePropertyContextMenu(context, actorData, controlData)
		end)

		local identifier = memberInfo.name:replace("/", "_")
		ctrl:SetName(identifier)
	end
	self:SetPropertyAnimationOverlaysDirty()
	self:UpdateControlValue(controlData)
	self:CallCallbacks("OnControlSelected", actor, udmComponent, controlData, ctrl)
	return ctrl
end
function gui.PFMActorEditor:AddIkController(actor, boneName, chainLength)
	pfm.log(
		"Adding ik controller for bone '"
			.. boneName
			.. "' of actor '"
			.. tostring(actor)
			.. "' with chain length "
			.. chainLength
			.. "...",
		pfm.LOG_CATEGORY_PFM,
		pfm.LOG_SEVERITY_DEBUG
	)
	if chainLength <= 1 then
		pfm.log(
			"Chain length of " .. chainLength .. " is not long enough! Ik Controller will not be created.",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_DEBUG
		)
		return false
	end

	local solverC = self:CreateNewActorComponent(actor, "ik_solver", false)
	self:CreateNewActorComponent(actor, "pfm_fbik", false)
	if solverC == nil then
		pfm.log(
			"Failed to add ik_solver component! Ik Controller will not be created.",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_DEBUG
		)
		return false
	end

	local ent = actor:FindEntity()
	if util.is_valid(ent) == false then
		pfm.log(
			"Actor entity is not valid! Ik Controller will not be created.",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_DEBUG
		)
		return false
	end
	local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()
	local boneId = mdl:LookupBone(boneName)
	if boneId == -1 then
		pfm.log(
			"Bone '"
				.. boneName
				.. "' could not be found in model '"
				.. mdl:GetName()
				.. "'! Ik Controller will not be created.",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_DEBUG
		)
		return false
	end

	ent:AddComponent("ik_solver")
	self:UpdateActorComponents(actor)

	ent = actor:FindEntity()
	local ikSolverC = util.is_valid(ent) and ent:AddComponent("ik_solver") or nil
	if ikSolverC == nil then
		pfm.log(
			"Actor entity does not have ik_solver component! Ik Controller will not be created.",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_DEBUG
		)
		return false
	end
	local bone = skeleton:GetBone(boneId)

	ikSolverC:AddIkSolverByChain(boneName, chainLength)

	local udmRigData = solverC:GetMemberValue("rigConfig")
	-- udmRigData:Clear()
	udmRigData:Merge(ikSolverC:GetMemberValue("rigConfig"):Get(), udm.MERGE_FLAG_BIT_DEEP_COPY)

	local memberId = ikSolverC:GetMemberIndex("IkRig")
	if memberId ~= nil then
		ikSolverC:OnMemberValueChanged(memberId)
	end

	local componentId = ents.find_component_id("ik_solver")
	if componentId ~= nil then
		self:ReloadActorComponentEntries(actor, componentId)
	end

	return true
end
function gui.PFMActorEditor:ReloadActorComponentEntries(actor, componentId)
	self:RemoveActorComponentEntry(tostring(actor:GetUniqueId()), componentId)
	self:SetActorDirty(tostring(actor:GetUniqueId()))
	self:InitializeDirtyActorComponents(tostring(actor:GetUniqueId()))
end
function gui.PFMActorEditor:PopulatePropertyContextMenu(context, actorData, controlData)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager ~= nil then
		local type = controlData.type
		local exprIcon
		local enable_expr_icon
		local function clear_expression()
			local pm = pfm.get_project_manager()
			local animManager = pm:GetAnimationManager()
			if animManager == nil then
				return
			end
			animManager:SetValueExpression(actorData.actor, controlData.path)

			local anim, channel, animClip = animManager:FindAnimationChannel(actorData.actor, controlData.path)
			if animClip ~= nil then
				local channel = animClip:GetChannel(controlData.path)
				if channel ~= nil then
					channel:SetExpression()
				end
			end
			enable_expr_icon(false)
		end
		enable_expr_icon = function(enabled)
			self:DoUpdatePropertyIcons(actorData, controlData)
		end
		local pm = pfm.get_project_manager()
		local animManager = pm:GetAnimationManager()
		if animManager ~= nil and animManager:GetValueExpression(actorData.actor, controlData.path) ~= nil then
			enable_expr_icon(true)
		end

		local expr = animManager:GetValueExpression(actorData.actor, controlData.path)
		if expr ~= nil then
			context
				:AddItem(locale.get_text("pfm_clear_expression"), function()
					clear_expression()
				end)
				:SetName("clear_expression")
			context
				:AddItem(locale.get_text("pfm_copy_expression"), function()
					util.set_clipboard_string(expr)
				end)
				:SetName("copy_expression")
		end
		context
			:AddItem(locale.get_text("pfm_set_expression"), function()
				self:OpenPropertyExpressionWindow(actorData, controlData)
			end)
			:SetName("set_expression")
		if controlData.path ~= nil then
			context
				:AddItem(locale.get_text("pfm_copy_property_path"), function()
					util.set_clipboard_string(ents.create_uri(actorData.actor:GetUniqueId(), controlData.path))
				end)
				:SetName("copy_property_path")
		end
		local anim, channel = animManager:FindAnimationChannel(actorData.actor, controlData.path, false)
		if channel ~= nil then
			context
				:AddItem(locale.get_text("pfm_clear_animation"), function()
					animManager:RemoveChannel(actorData.actor, controlData.path)
					local entActor = actorData.actor:FindEntity()
					if util.is_valid(entActor) == false then
						return
					end
					local actorC = entActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
					if actorC ~= nil then
						actorC:ApplyComponentMemberValue(controlData.path)
					end

					local animC = entActor:GetComponent(ents.COMPONENT_PANIMA)
					if animC ~= nil then
						animC:ReloadAnimation()
					end

					self:SetPropertyAnimationOverlaysDirty()
				end)
				:SetName("clear_animation")
			if tool.get_filmmaker():IsDeveloperModeEnabled() then
				context
					:AddItem("Make Animated", function()
						tool.get_filmmaker():MakeActorPropertyAnimated(actorData.actor, controlData.path)

						self:SetPropertyAnimationOverlaysDirty()
					end)
					:SetName("make_animated")
			end
		end
	end

	local props = self:GetSelectedProperties()
	local hasControlData = false
	for i, propOther in ipairs(props) do
		if propOther.controlData == controlData then
			if i ~= 1 then
				-- Make sure that the context menu property is the first in the list
				local tmp = props[1]
				props[1] = propOther
				props[i] = tmp
			end
			hasControlData = true
			break
		end
	end

	if hasControlData == false then
		table.insert(props, 1, { actorData = actorData, controlData = controlData })
	end
	if #props > 0 then
		local constraintProps = props
		if #constraintProps > 2 then
			constraintProps = { { actorData = actorData, controlData = controlData } }
		end -- If more than two properties are selected, we'll only show self-contained constraints for the property that was clicked

		local prop0 = constraintProps[1]
		local prop1 = constraintProps[2]
		if prop0.controlData == controlData then
			local constraintTypes = {}
			local function is_valid_constraint_type(type)
				return udm.is_convertible(type, udm.TYPE_VECTOR3)
					and udm.is_numeric_type(type) == false
					and type ~= udm.TYPE_STRING
			end
			if is_valid_constraint_type(prop0.controlData.type) then
				table.insert(
					constraintTypes,
					{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION, "limit_location", false }
				)
				table.insert(
					constraintTypes,
					{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE, "limit_scale", false }
				)

				if
					#constraintProps > 1
					and udm.is_convertible(prop1.controlData.type, udm.TYPE_VECTOR3)
					and udm.is_numeric_type(prop1.controlData.type) == false
				then
					table.insert(
						constraintTypes,
						{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION, "copy_location", true }
					)
					table.insert(
						constraintTypes,
						{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE, "copy_scale", true }
					)
					table.insert(
						constraintTypes,
						{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE, "limit_distance", true }
					)
					table.insert(
						constraintTypes,
						{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF, "child_of", true }
					)
				end
			end
			if prop0.controlData.type == udm.TYPE_EULER_ANGLES or prop0.controlData.type == udm.TYPE_QUATERNION then
				table.insert(
					constraintTypes,
					{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION, "limit_rotation", false }
				)
				if #constraintProps > 1 and is_valid_constraint_type(prop1.controlData.type) then
					table.insert(
						constraintTypes,
						{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION, "copy_rotation", true }
					)
					table.insert(
						constraintTypes,
						{ gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT, "look_at", true }
					) -- TODO: Only add look_at constraint to list if rotation property has associated position property
				end
			end

			if #constraintTypes > 0 then
				local ctItem, ctMenu = context:AddSubMenu(locale.get_text("pfm_add_constraint"))
				ctItem:SetName("add_constraint")
				for _, typeInfo in ipairs(constraintTypes) do
					ctMenu
						:AddItem(locale.get_text("c_constraint_" .. typeInfo[2]), function()
							local actor = self:CreatePresetActor(typeInfo[1], {
								["updateActorComponents"] = false,
							})
							local ctC = actor:FindComponent("constraint")
							if ctC ~= nil then
								ctC:SetMemberValue(
									"drivenObject",
									udm.TYPE_STRING,
									ents.create_uri(prop0.actorData.actor:GetUniqueId(), prop0.controlData.path)
								)
								if typeInfo[3] == true and prop1.controlData ~= nil then
									ctC:SetMemberValue(
										"driver",
										udm.TYPE_STRING,
										ents.create_uri(prop1.actorData.actor:GetUniqueId(), prop1.controlData.path)
									)
								end
								self:UpdateActorComponents(actor)
							end

							local pm = pfm.get_project_manager()
							local animManager = pm:GetAnimationManager()
							if animManager == nil then
								return
							end
							-- Constraints require there to be an animation channel with at least one animation value
							animManager:InitChannelWithBaseValue(
								prop0.actorData.actor,
								prop0.controlData.path,
								true,
								prop0.controlData.type
							)
						end)
						:SetName("constraint_" .. typeInfo[2])
				end
				ctMenu:Update()
			end
		end
	end

	if
		util.is_valid(controlData.treeElement)
		and controlData.treeElement.__elDriverActorData ~= nil
		and util.is_valid(controlData.treeElement.__elDriverActorData.icon)
	then
		-- Don't allow adding driver if there already is one
	elseif #props > 0 then
		local prop = props[1]
		if controlData.type < udm.TYPE_COUNT then
			context
				:AddItem(locale.get_text("pfm_add_driver"), function()
					local actor = self:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_ANIMATION_DRIVER, {
						["updateActorComponents"] = false,
					})
					local ctC = actor:FindComponent("animation_driver")
					if ctC ~= nil then
						ctC:SetMemberValue(
							"drivenObject",
							udm.TYPE_STRING,
							ents.create_uri(prop.actorData.actor:GetUniqueId(), prop.controlData.path)
						)
						self:UpdateActorComponents(actor)

						local nameCountMap = {}
						local function get_var_name(baseName)
							if nameCountMap[baseName] == nil then
								nameCountMap[baseName] = 1
								return baseName
							end
							nameCountMap[baseName] = nameCountMap[baseName] + 1
							return baseName .. nameCountMap[baseName]
						end

						local ctrl, ctrlData, componentData, actorData = self:GetPropertyControl(
							actor:GetUniqueId(),
							"animation_driver",
							"ec/animation_driver/parameters"
						)
						local elUdm = ctrlData.getValue()
						local params = ctC:GetMemberValue("parameters")
						if util.is_valid(params) then
							local udmConstants = params:Add("constants")
							local udmReferences = params:Add("references")

							-- Add the selected properties, components and actors as input parameters for the expression
							local actors = {}
							for _, propParam in ipairs(props) do
								local uuid = propParam.actorData.actor:GetUniqueId()
								local uri = ents.create_uri(uuid, propParam.controlData.path)
								udmReferences:SetValue(
									get_var_name(util.Path.CreateFilePath(propParam.controlData.path):GetFileName()),
									udm.TYPE_STRING,
									uri
								)

								local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(
									panima.Channel.Path(propParam.controlData.path)
								)
								actors[tostring(uuid)] = actors[tostring(uuid)] or {}
								actors[tostring(uuid)][componentName] = true
							end

							local pm = pfm.get_project_manager()
							local session = pm:GetSession()
							local schema = session:GetSchema()
							for uuid, components in pairs(actors) do
								local actor = udm.dereference(schema, uuid)
								if actor ~= nil then
									udmReferences:SetValue(
										get_var_name("e_" .. actor:GetName()),
										udm.TYPE_STRING,
										ents.create_entity_uri(util.Uuid(uuid))
									)

									for componentName, _ in pairs(components) do
										udmReferences:SetValue(
											get_var_name("c_" .. componentName),
											udm.TYPE_STRING,
											ents.create_component_uri(util.Uuid(uuid), componentName)
										)
									end
								end
							end

							if controlData.set ~= nil then
								elUdm:Clear()
								elUdm:Merge(params, udm.MERGE_FLAG_BIT_DEEP_COPY)

								ctrlData.set(actorData.actor:FindComponent("animation_driver"), elUdm)
							end
						end
					end
				end)
				:SetName("driver")
		end
	end

	if controlData.type == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
		context
			:AddItem(locale.get_text("pfm_go_to_property"), function()
				local val = controlData.getValue()
				if val == nil then
					return
				end
				local uuid = tostring(val:GetUuid())
				local componentName = val:GetComponentName()
				local propName = val:GetMemberName()
				if componentName == nil or propName == nil then
					return
				end
				local pm = pfm.get_project_manager()
				local session = pm:GetSession()
				local schema = session:GetSchema()
				local actor = udm.dereference(schema, uuid)
				if actor == nil then
					return
				end
				self:SelectActor(actor, true, "ec/" .. componentName .. "/" .. propName)
			end)
			:SetName("go_to_property")
	end
end
function gui.PFMActorEditor:AddControl(
	entActor,
	component,
	actorData,
	componentData,
	udmComponent,
	item,
	controlData,
	identifier
)
	local actor = udmComponent:GetActor()
	local memberInfo = (actor ~= nil) and self:GetMemberInfo(actor, controlData.path) or nil
	if memberInfo == nil then
		return
	end
	controlData.translateToInterface = controlData.translateToInterface or function(val)
		return val
	end
	controlData.translateFromInterface = controlData.translateFromInterface or function(val)
		return val
	end

	local isBaseProperty = not ents.is_member_type_animatable(memberInfo.type)
	local baseItem = isBaseProperty and componentData.itemBaseProps or item

	local componentName, memberName =
		ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(controlData.path))
	local isAnimatedComponent = (componentName == "animated")

	local memberComponents = string.split(memberName:GetString(), "/")
	local isBone = (#memberComponents >= 2 and memberComponents[1] == "bone")

	local propertyPathComponents = string.split(controlData.name, "/")
	local subPath = "ec/" .. componentName .. "/"

	--[[local metaInfo = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_PARENT)
	if(metaInfo ~= nil) then
		local id = "ec/" .. componentName .. "/" .. metaInfo.parentProperty
		id = util.Path.CreateFilePath(id)
		id:PopBack()
		id = id:GetString()
		id = id:sub(1,#id -1)
		local item = self.m_tree:GetRoot():GetItemByIdentifier(id,true)
		if(item ~= nil) then subPath = subPath .. "bone/" table.remove(propertyPathComponents,1) baseItem = item end
	end]]

	local iPathPropName = 2
	if isBone then
		-- We want the bones to show in a hierarchical order.
		-- This is currently not possible with the component property system, so
		-- for now it's hardcoded here.
		local boneName = memberComponents[2]
		local mdl = entActor:GetModel()
		local skeleton = (mdl ~= nil) and mdl:GetSkeleton() or nil
		local bone = (skeleton ~= nil) and skeleton:GetBone(skeleton:LookupBone(boneName)) or nil
		local parent = (bone ~= nil) and bone:GetParent() or nil
		if parent ~= nil then
			local id = "ec/animated/bone/" .. parent:GetName()
			local itemActor = self:GetActorEntry(tostring(entActor:GetUuid()))
			local item = util.is_valid(itemActor) and itemActor:GetItemByIdentifier(id, true) or nil
			if item ~= nil then
				subPath = subPath .. "bone/"
				table.remove(propertyPathComponents, 1)
				iPathPropName = iPathPropName - 1
				baseItem = item
			end
		end
	end

	for i = 1, #propertyPathComponents - 1 do
		local cname = propertyPathComponents[i]
		subPath = subPath .. cname

		local cnameItem = baseItem:GetItemByIdentifier(subPath)
		local childItem
		if util.is_valid(cnameItem) then
			childItem = cnameItem
		else
			childItem = baseItem:AddItem(cname, nil, nil, subPath)
			childItem:SetName(util.Path.CreateFilePath(subPath):GetBack())
		end
		baseItem = childItem
		subPath = subPath .. "/"
		if isBone and i == iPathPropName then
			childItem.__boneMouseEvent = childItem.__boneMouseEvent
				or childItem:AddCallback("OnMouseEvent", function(tex, button, state, mods)
					if button == input.MOUSE_BUTTON_RIGHT then
						if state == input.STATE_PRESS then
							local boneName = memberComponents[2]
							local mdlName = actor:GetModel()
							local mdl = (mdlName ~= nil) and game.load_model(mdlName) or nil
							local boneId = (mdl ~= nil) and mdl:LookupBone(boneName) or -1
							if boneId ~= -1 then
								local skeleton = mdl:GetSkeleton()
								local bone = skeleton:GetBone(boneId)
								local numParents = 0
								local parent = bone:GetParent()

								while parent ~= nil do
									numParents = numParents + 1
									parent = parent:GetParent()
								end

								if numParents >= 2 then
									local pContext = gui.open_context_menu()
									if util.is_valid(pContext) == false then
										return
									end
									pContext:SetPos(input.get_cursor_pos())

									local ikItem, ikMenu =
										pContext:AddSubMenu(locale.get_text("pfm_actor_editor_add_ik_control"))
									ikItem:SetName("add_ik_control")
									parent = bone:GetParent():GetParent()
									for i = 2, numParents do
										local subItem = ikMenu:AddItem(
											locale.get_text(
												"pfm_actor_editor_add_ik_control_chain",
												{ i + 1, parent:GetName() }
											),
											function()
												self:AddIkController(actor, boneName, i + 1)
											end
										)
										subItem:SetName("ik_control_chain_" .. tostring(i + 1))
										parent = parent:GetParent()
									end
									ikMenu:Update()

									pContext:Update()
								end
							end
						end
						return util.EVENT_REPLY_HANDLED
					end
				end)
		end
	end

	local displayName = propertyPathComponents[#propertyPathComponents]

	local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(identifier))
	local description
	if componentName ~= nil then
		local propName = string.camel_case_to_snake_case(pathName:GetString())
		local locId = "c_" .. componentName .. "_p_" .. propName
		local res, text = locale.get_text(locId, true)
		if res == true then
			displayName = text
		end

		local res, textDesc = locale.get_text(locId .. "_desc", true)
		if res == true then
			description = textDesc
		end
	end

	local child = baseItem:AddItem(displayName, nil, nil, identifier)
	child:SetName(util.Path.CreateFilePath(identifier):GetBack())
	if description ~= nil then
		child:SetTooltip(description)
	end
	child:AddCallback("OnMouseEvent", function(tex, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())

			self:PopulatePropertyContextMenu(pContext, actorData, controlData)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end)

	local ctrl
	local selectedCount = 0
	local fOnSelected = function(item)
		self:CallCallbacks("OnPropertySelected", udmComponent, item, controlData.name, true)
		local itemParent = item:GetParentItem()
		while util.is_valid(itemParent) do
			local udmEl = self:GetCollectionUdmObject(itemParent)
			if util.get_type_name(udmEl) == "Actor" then
				local itemActor = self:GetCollectionTreeItem(tostring(udmEl:GetUniqueId()))
				if util.is_valid(itemActor) then
					itemActor:SetSelected(true, false)
				end
				break
			end
			itemParent = itemParent:GetParentItem()
		end

		selectedCount = selectedCount + 1
		if selectedCount > 1 or util.is_valid(ctrl) then
			return
		end
		ctrl = self:OnControlSelected(actor, actorData, udmComponent, controlData)
		if ctrl ~= nil then
			local uid = tostring(actor:GetUniqueId())
			self.m_activeControls[uid] = self.m_activeControls[uid] or {}
			self.m_activeControls[uid][controlData.path] = {
				actor = actor,
				control = ctrl,
				controlData = controlData,
			}
		end
	end
	local fOnDeselected = function()
		self:CallCallbacks("OnPropertySelected", udmComponent, item, controlData.name, false)
		selectedCount = selectedCount - 1
		if selectedCount > 0 then
			return
		end
		self:CallCallbacks("OnControlDeselected", udmComponent, controlData, ctrl)
		if actor:IsValid() then
			local uid = tostring(actor:GetUniqueId())
			if self.m_activeControls[uid] ~= nil then
				self.m_activeControls[uid][controlData.path] = nil
				if table.is_empty(self.m_activeControls[uid]) then
					self.m_activeControls[uid] = nil
				end
			end
		end
		if util.is_valid(ctrl) == false then
			return
		end
		ctrl:Remove()
	end
	if controlData.type == "bone" then
		local function add_item(parent, name)
			local item = parent:AddItem(name)
			item:AddCallback("OnSelected", fOnSelected)
			item:AddCallback("OnDeselected", fOnDeselected)
			return item
		end

		local childPos = child:AddItem("pos")
		add_item(childPos, "x")
		add_item(childPos, "y")
		add_item(childPos, "z")

		local childRot = child:AddItem("rot")
		add_item(childRot, "x")
		add_item(childRot, "y")
		add_item(childRot, "z")
	else
		child:AddCallback("OnSelected", fOnSelected)
		child:AddCallback("OnDeselected", fOnDeselected)
	end
	return ctrl, child
end
function gui.PFMActorEditor:GetActorEntry(uuid)
	return self.m_actorUniqueIdToTreeElement[tostring(uuid)]
end
function gui.PFMActorEditor:GetActorData(uuid)
	local el = self:GetActorEntry(uuid)
	if util.is_valid(el) == false then
		return
	end
	return self.m_treeElementToActorData[el]
end
function gui.PFMActorEditor:GetPropertyEntry(uuid, componentType, propertyName)
	local elComponent, componentData, actorData = self:GetComponentEntry(uuid, componentType)
	if elComponent == nil then
		return
	end
	if componentData.items[propertyName] == nil then
		return
	end
	return componentData.items[propertyName].treeElement,
		componentData.items[propertyName].controlData,
		componentData,
		actorData
end
function gui.PFMActorEditor:GetPropertyControl(uuid, componentType, propertyName)
	local elComponent, componentData, actorData = self:GetComponentEntry(uuid, componentType)
	if elComponent == nil then
		return
	end
	if componentData.items[propertyName] == nil then
		return
	end
	return componentData.items[propertyName].control,
		componentData.items[propertyName].controlData,
		componentData,
		actorData
end
function gui.PFMActorEditor:UpdateConstraintPropertyIcons()
	if self.m_specialPropertyIcons["constraints"] ~= nil then
		for _, ctInfo in ipairs(self.m_specialPropertyIcons["constraints"]) do
			util.remove(ctInfo.icon)
		end
	end
	self.m_specialPropertyIcons["constraints"] = {}

	local function find_property_object_entry(elActor, componentType, propName)
		local actorData = self.m_treeElementToActorData[elActor]
		if actorData == nil then
			return
		end
		local c = actorData.actor:FindComponent(componentType)
		if c == nil then
			return
		end
		local drivenObject = c:GetMemberValue(propName)
		if drivenObject == nil then
			return
		end
		local ref = ents.parse_uri(drivenObject)
		if ref == nil then
			return
		end
		local uuid = ref:GetUuid()
		local componentType = ref:GetComponentName()
		local propName = ref:GetMemberName()
		propName = "ec/" .. componentType .. "/" .. propName
		local el, ctrlData, componentDataDriven, actorDataDriven = self:GetPropertyEntry(uuid, componentType, propName)
		if util.is_valid(el) == false then
			return
		end
		return el, actorData, uuid, propName
	end

	local function find_driven_object_entry(elActor, componentType)
		return find_property_object_entry(elActor, componentType, "drivenObject")
	end

	local function add_icon(elActor, componentType, icon)
		local el, actorData, uuid, propName = find_driven_object_entry(elActor, componentType)
		if el ~= nil then
			local icon = el:AddIcon(icon)
			if util.is_valid(icon) then
				icon:SetName(componentType)
				icon:SetCursor(gui.CURSOR_SHAPE_HAND)
				icon:SetMouseInputEnabled(true)
				icon:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
					if button == input.MOUSE_BUTTON_LEFT then
						if state == input.STATE_PRESS then
							self:SelectActor(actorData.actor, true, "ec/" .. componentType .. "/drivenObject")
						end
						return util.EVENT_REPLY_HANDLED
					elseif button == input.MOUSE_BUTTON_RIGHT then
						if state == input.STATE_PRESS then
							local pContext = gui.open_context_menu()
							if util.is_valid(pContext) == false then
								return
							end
							pContext:SetPos(input.get_cursor_pos())

							pContext
								:AddItem(locale.get_text("pfm_go_to_driver_property"), function()
									local elDriver, actorData, uuidDriver, propNameDriver =
										find_property_object_entry(elActor, "constraint", "driver")
									if uuidDriver ~= nil then
										local pm = pfm.get_project_manager()
										local session = pm:GetSession()
										local schema = session:GetSchema()
										local actorDriver = udm.dereference(schema, tostring(uuidDriver))
										if actorDriver ~= nil then
											self:SelectActor(actorDriver, true, propNameDriver)
										end
									end
								end)
								:SetName("go_to_driver_property")
							pContext
								:AddItem(locale.get_text("remove"), function()
									self:RemoveActors({ tostring(actorData.actor:GetUniqueId()) })
								end)
								:SetName("remove")
							pContext:Update()
						end
						return util.EVENT_REPLY_HANDLED
					end
				end)
				table.insert(self.m_specialPropertyIcons["constraints"], {
					icon = icon,
					actorUuid = uuid,
					componentType = componentType,
					property = propName,
				})
				return icon, actorData, el
			end
		end
	end

	self:IterateActors(function(el)
		local icon, actorData, elDrivenObject = add_icon(el, "constraint", "gui/pfm/icon_constraint")
		if icon ~= nil then
			local constraintType
			for _, ctName in ipairs({
				"copy_location",
				"copy_rotation",
				"copy_scale",
				"limit_distance",
				"limit_location",
				"limit_rotation",
				"limit_scale",
				"look_at",
			}) do
				if actorData.actor:HasComponent("constraint_" .. ctName) then
					constraintType = ctName
					break
				end
			end

			local constraintName
			if constraintType ~= nil then
				local valid, n = locale.get_text("c_constraint_" .. constraintType, nil, true)
				if valid then
					constraintName = n
				end
			end

			constraintName = constraintName or locale.get_text("unknown")

			local elDriver, actorData, uuidDriver, propNameDriver =
				find_property_object_entry(el, "constraint", "driver")
			local actorDriver
			if uuidDriver ~= nil then
				local pm = pfm.get_project_manager()
				local session = pm:GetSession()
				local schema = session:GetSchema()
				actorDriver = udm.dereference(schema, tostring(uuidDriver))
			end
			if actorDriver ~= nil then
				icon:SetTooltip(
					locale.get_text("pfm_constraint_to", { constraintName, propNameDriver, actorDriver:GetName() })
				)
			else
				icon:SetTooltip(locale.get_text("pfm_constraint", { constraintName }))
			end

			elDrivenObject.__elConstraintActorData = elDrivenObject.__elConstraintActorData or {}
			for i = #elDrivenObject.__elConstraintActorData, 1, -1 do
				local data = elDrivenObject.__elConstraintActorData[i]
				if data.icon:IsValid() == false then
					table.remove(elDrivenObject.__elConstraintActorData, i)
				end
			end

			table.insert(elDrivenObject.__elConstraintActorData, {
				icon = icon,
				constraintActorElement = el,
			})
		end

		local icon, actorData, elDrivenObject = add_icon(el, "animation_driver", "gui/pfm/icon_driver")
		if icon ~= nil then
			icon:SetTooltip(locale.get_text("pfm_animation_driver"))
			elDrivenObject.__elDriverActorData = {
				icon = icon,
				driverActorElement = el,
			}
		end
	end)
end
function gui.PFMActorEditor:ShowPropertyInGraphEditor(propertyName)
	local timeline = tool.get_filmmaker():GetTimeline()
	if util.is_valid(timeline) == false then
		return
	end
	timeline:SetEditor(gui.PFMTimeline.EDITOR_GRAPH)
	local graphEditor = timeline:GetGraphEditor()
	if util.is_valid(graphEditor) == false then
		return
	end
	local tree = graphEditor:GetPropertyList()
	if util.is_valid(tree) == false then
		return
	end
	tree:DeselectAll()
	local item = tree:GetRoot():GetItemByIdentifier(propertyName)
	if util.is_valid(item) then
		item:Select()
	end
	graphEditor:FitViewToDataRange()
end
function gui.PFMActorEditor:UpdatePropertyIcons(uuid, componentId, propPath)
	local itemC, ctrlData, componentData, actorData = self:GetPropertyEntry(uuid, componentId, propPath)
	if itemC == nil then
		return
	end
	return self:DoUpdatePropertyIcons(actorData, ctrlData)
end
function gui.PFMActorEditor:DoUpdatePropertyIcons(actorData, controlData)
	local cData = actorData.componentData[controlData.componentId]
	if
		cData == nil
		or cData.items[controlData.path] == nil
		or util.is_valid(cData.items[controlData.path].treeElement) == false
	then
		return
	end
	local el = cData.items[controlData.path].treeElement
	el:ClearIcons()
	local channel = self:GetAnimationChannel(actorData.actor, controlData.path, false)
	if channel ~= nil then
		local icon = el:AddUniqueIcon("gui/pfm/icon_animated")
		if util.is_valid(icon) then
			icon:SetName("animated")
			icon:SetCursor(gui.CURSOR_SHAPE_HAND)
			icon:SetMouseInputEnabled(true)
			icon:SetTooltip(locale.get_text("pfm_animated"))
			util.remove(icon.__cbShowAnim)
			icon.__cbShowAnim = icon:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
				if button == input.MOUSE_BUTTON_LEFT then
					if state == input.STATE_PRESS then
						el:Select()
						time.create_simple_timer(0.0, function()
							if self:IsValid() then
								self:ShowPropertyInGraphEditor(controlData.name)
							end
						end)
					end
					return util.EVENT_REPLY_HANDLED
				end
			end)
		end
	end
	local hasExpression = (channel ~= nil and channel:GetExpression() ~= nil)
	if hasExpression then
		local icon = el:AddUniqueIcon("gui/pfm/icon_math_expression")
		if util.is_valid(icon) then
			icon:SetName("math_expr")
			icon:SetCursor(gui.CURSOR_SHAPE_HAND)
			icon:SetMouseInputEnabled(true)
			icon:SetTooltip(locale.get_text("pfm_math_expression", { channel:GetExpression() }))
			util.remove(icon.__cbEditMathExpression)
			icon.__cbEditMathExpression = icon:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
				if button == input.MOUSE_BUTTON_LEFT then
					if state == input.STATE_PRESS then
						self:OpenPropertyExpressionWindow(actorData, controlData)
					end
					return util.EVENT_REPLY_HANDLED
				end
			end)
		end
	end

	self.m_updatePropertyIcons = true
	self:EnableThinking()
end
function gui.PFMActorEditor:ToggleCameraLink(actor)
	util.remove(self.m_cameraLinkOutlineElement)
	util.remove(self.m_cbCamLinkGameplayCb)

	local filmmaker = tool.get_filmmaker()
	local entActor = actor:FindEntity()
	local vp = filmmaker:GetViewport()
	if util.is_valid(vp) == false or util.is_valid(entActor) == false then
		return
	end
	local cam = vp:GetCamera()
	if util.is_valid(cam) == false then
		return
	end
	local ent = cam:GetEntity()
	if ent:HasComponent("pfm_camera_actor_link") then
		ent:RemoveComponent("pfm_camera_actor_link")
		if self.m_camLinkOrigFov ~= nil then
			cam:SetFOV(self.m_camLinkOrigFov)
			self.m_camLinkOrigFov = nil
		end
		if self.m_camLinkOrigPose ~= nil then
			vp:SetWorkCameraPose(self.m_camLinkOrigPose)
			self.m_camLinkOrigPose = nil
		end
		self:TagRenderSceneAsDirty()
	else
		local c = cam:GetEntity():AddComponent("pfm_camera_actor_link")

		local vpInner = vp:GetViewport()
		local el = gui.create("WIOutlinedRect", vpInner, 0, 0, vpInner:GetWidth(), vpInner:GetHeight(), 0, 0, 1, 1)
		el:SetColor(pfm.get_color_scheme_color("green"))
		el:SetZPos(10)
		self.m_cameraLinkOutlineElement = el

		if c ~= nil then
			c:SetTargetActor(entActor)
			local lightSpotC = entActor:GetComponent(ents.COMPONENT_LIGHT_SPOT)
			if lightSpotC ~= nil then
				self.m_camLinkOrigFov = cam:GetFOV()
				self.m_camLinkOrigPose = cam:GetEntity():GetPose()
				cam:SetFOV(lightSpotC:GetOuterConeAngle())
			end
			local camC = entActor:GetComponent(ents.COMPONENT_CAMERA)
			if camC ~= nil then
				cam:SetFOV(camC:GetFOV())
			end
			vp:SetWorkCameraPose(entActor:GetPose())
			self:TagRenderSceneAsDirty()
		end
		local vp = tool.get_filmmaker():GetViewport()
		if util.is_valid(vp) then
			vp:SetGameplayMode(true)
			self.m_cbCamLinkGameplayCb = input.add_callback("OnMouseInput", function(button, action, mods)
				if action == input.STATE_PRESS then
					self:ToggleCameraLink(actor)
					if vp:IsValid() then
						vp:SetGameplayMode(false)
					end
				end
			end)
		end
	end
end
function gui.PFMActorEditor:OnRemove()
	util.remove(self.m_cbCamLinkGameplayCb)
	util.remove(self.m_cameraLinkOutlineElement)
	util.remove(self.m_callbacks)
	util.remove(self.m_filmClipCallbacks)
end
gui.register("WIPFMActorEditor", gui.PFMActorEditor)

pfm.populate_actor_context_menu = function(pContext, actor, copyPasteSelected, hitMaterial)
	-- Components
	local entActor = actor:FindEntity()
	if util.is_valid(entActor) then
		local existingComponents = {}
		local newComponentMap = {}
		for _, componentId in ipairs(ents.get_registered_component_types()) do
			local info = ents.get_component_info(componentId)
			local name = info.name
			if actor:HasComponent(name) == false then
				if entActor:HasComponent(name) then
					table.insert(existingComponents, name)
				else
					newComponentMap[name] = true
				end
			end
		end
		for _, name in ipairs(ents.find_installed_custom_components()) do
			newComponentMap[name] = true
		end
		local newComponents = {}
		for name, _ in pairs(newComponentMap) do
			table.insert(newComponents, name)
		end
		for _, list in ipairs({ existingComponents, newComponents }) do
			for i, name in ipairs(list) do
				local displayName = name
				local valid, n = locale.get_text("c_" .. name, nil, true)
				if valid then
					displayName = n
				end
				list[i] = { name, displayName }
			end
			table.sort(list, function(a, b)
				return a[2] < b[2]
			end)
		end
		if #existingComponents > 0 then
			local pComponentsItem, pComponentsMenu = pContext:AddSubMenu(locale.get_text("pfm_add_component"))
			pComponentsItem:SetName("add_component")
			for _, nameInfo in ipairs(existingComponents) do
				pComponentsMenu
					:AddItem(nameInfo[2], function()
						local filmmaker = tool.get_filmmaker()
						local actorEditor = util.is_valid(filmmaker) and filmmaker:GetActorEditor() or nil
						if util.is_valid(actorEditor) == false then
							return
						end
						pfm.undoredo.push(
							"create_component",
							pfm.create_command("create_component", actor, nameInfo[1])
						)()
					end)
					:SetName(nameInfo[1])
			end
			pComponentsMenu:Update()
		end
		if #newComponents > 0 then
			local pComponentsItem, pComponentsMenu = pContext:AddSubMenu(locale.get_text("pfm_add_new_component"))
			pComponentsItem:SetName("add_new_component")
			debug.start_profiling_task("pfm_populate_component_list")
			for _, nameInfo in ipairs(newComponents) do
				pComponentsMenu
					:AddItem(nameInfo[2], function()
						local filmmaker = tool.get_filmmaker()
						local actorEditor = util.is_valid(filmmaker) and filmmaker:GetActorEditor() or nil
						if util.is_valid(actorEditor) == false then
							return
						end
						pfm.undoredo.push(
							"create_component",
							pfm.create_command("create_component", actor, nameInfo[1])
						)()
					end)
					:SetName(nameInfo[1])
			end
			pComponentsMenu:Update()
			debug.stop_profiling_task()
		end
	end
	--

	local uniqueId = tostring(actor:GetUniqueId())
	pContext
		:AddItem(locale.get_text("pfm_export_animation"), function()
			local entActor = actor:FindEntity()
			if util.is_valid(entActor) == false then
				return
			end
			local filmmaker = tool.get_filmmaker()
			filmmaker:ExportAnimation(entActor)
		end)
		:SetName("export_animation")

	local entActor = actor:FindEntity()
	local renderC = util.is_valid(entActor) and entActor:GetComponent(ents.COMPONENT_RENDER) or nil
	local mdl = util.is_valid(entActor) and entActor:GetModel() or nil
	if renderC ~= nil and mdl ~= nil then
		local materials = {}
		local hasMaterials = false
		for _, mesh in ipairs(renderC:GetRenderMeshes()) do
			local mat = mdl:GetMaterial(mesh:GetSkinTextureIndex())
			if util.is_valid(mat) then
				local name = mat:GetName()
				if #name > 0 then
					materials[name] = mat
					hasMaterials = true
				end
			end
		end

		if hasMaterials then
			local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_edit_material"))
			pItem:SetName("edit_material")
			for matPath, _ in pairs(materials) do
				local matName = file.get_file_name(matPath)
				local item = pSubMenu:AddItem(matName, function()
					tool.get_filmmaker():OpenMaterialEditor(matPath, mdl:GetName())
				end)
				local normMatPath = string.replace(matPath, "/", "_")
				item:SetName(normMatPath)

				if hitMaterial ~= nil and matPath == hitMaterial:GetName() then
					local el = gui.create("WIOutlinedRect", item, 0, 0, item:GetWidth(), item:GetHeight(), 0, 0, 1, 1)
					el:SetColor(pfm.get_color_scheme_color("green"))
				end
			end
			pSubMenu:Update()
		end

		pContext
			:AddItem(locale.get_text("pfm_export_model"), function()
				local exportInfo = game.Model.ExportInfo()
				local result, err = mdl:Export(exportInfo)
				if result then
					print("Model exported successfully!")
					local filePath = err
					util.open_path_in_explorer(file.get_file_path(filePath), file.get_file_name(filePath))
				else
					console.print_warning("Unable to export model: ", err)
				end
			end)
			:SetName("export_model")

		pContext
			:AddItem(locale.get_text("pfm_edit_ik_rig"), function()
				local filmmaker = tool.get_filmmaker()
				local tab, el = filmmaker:OpenWindow("ik_rig_editor")
				filmmaker:GoToWindow("ik_rig_editor")
				if util.is_valid(el) then
					el:SetReferenceModel(mdl:GetName())
				end
			end)
			:SetName("edit_ik_rig")
	end
	local actors
	if copyPasteSelected == nil then
		actors = { actor }
	end
	pContext
		:AddItem(locale.get_text("pfm_copy_actors"), function()
			local filmmaker = tool.get_filmmaker()
			local actorEditor = filmmaker:GetActorEditor()
			if util.is_valid(actorEditor) == false then
				return
			end
			actorEditor:CopyToClipboard(actors)
		end)
		:SetName("copy_actors")
	pContext
		:AddItem(locale.get_text("pfm_paste_actors"), function()
			local filmmaker = tool.get_filmmaker()
			local actorEditor = filmmaker:GetActorEditor()
			if util.is_valid(actorEditor) == false then
				return
			end
			actorEditor:PasteFromClipboard()
		end)
		:SetName("paste_actors")
	local mdl = actor:GetModel()
	if mdl ~= nil then
		pContext
			:AddItem(locale.get_text("pfm_pack_model"), function()
				pfm.pack_models({ mdl })
			end)
			:SetName("pack_model")
		pContext
			:AddItem(locale.get_text("pfm_copy_model_path_to_clipboard"), function()
				util.set_clipboard_string(mdl)
			end)
			:SetName("copy_model_path_to_clipboard")
		pContext
			:AddItem(locale.get_text("pfm_show_in_explorer"), function()
				local filePath = asset.find_file(mdl, asset.TYPE_MODEL)
				if filePath == nil then
					return
				end
				util.open_path_in_explorer(
					asset.get_asset_root_directory(asset.TYPE_MODEL) .. "/" .. file.get_file_path(filePath),
					file.get_file_name(filePath)
				)
			end)
			:SetName("show_in_explorer")
	end
	pContext
		:AddItem(locale.get_text("pfm_move_work_camera_to_actor"), function()
			local filmmaker = tool.get_filmmaker()
			local filmClip = filmmaker:GetActiveFilmClip()
			if filmClip == nil then
				return
			end
			local actor = filmClip:FindActorByUniqueId(uniqueId)
			if actor == nil then
				return
			end
			local pm = pfm.get_project_manager()
			local vp = util.is_valid(pm) and pm:GetViewport() or nil
			if util.is_valid(vp) == false then
				return
			end
			vp:SetWorkCameraPose(actor:GetAbsolutePose())
			tool.get_filmmaker():TagRenderSceneAsDirty()
		end)
		:SetName("move_work_camera_to_actor")
	pContext
		:AddItem(locale.get_text("pfm_move_actor_to_work_camera"), function()
			local filmmaker = tool.get_filmmaker()
			local pm = pfm.get_project_manager()
			local vp = util.is_valid(pm) and pm:GetViewport() or nil
			if util.is_valid(vp) == false then
				return
			end
			local ent = actor:FindEntity()
			if ent == nil then
				return
			end
			local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
			if actorC == nil then
				return
			end
			local pose = vp:GetWorkCameraPose()
			if pose == nil then
				return
			end
			filmmaker:SetActorTransformProperty(actorC, "position", pose:GetOrigin(), true)
		end)
		:SetName("move_actor_to_work_camera")
	pContext
		:AddItem(locale.get_text("pfm_toggle_camera_link"), function()
			local filmmaker = tool.get_filmmaker()
			local actorEditor = filmmaker:GetActorEditor()
			if util.is_valid(actorEditor) == false then
				return
			end
			actorEditor:ToggleCameraLink(actor)
		end)
		:SetName("toggle_camera_link")
	pContext
		:AddItem(locale.get_text("pfm_retarget"), function()
			local ent = actor:FindEntity()
			if ent == nil then
				return
			end
			local filmmaker = tool.get_filmmaker()
			gui.open_model_dialog(function(dialogResult, mdlName)
				if dialogResult ~= gui.DIALOG_RESULT_OK then
					return
				end
				if util.is_valid(ent) == false then
					return
				end
				local filmmaker = tool.get_filmmaker()
				local actorEditor = filmmaker:GetActorEditor()
				if util.is_valid(actorEditor) == false then
					return
				end
				filmmaker:RetargetActor(ent, mdlName)

				local impostorC = actorEditor:CreateNewActorComponent(actor, "impersonatee", false)
				impostorC:SetMemberValue("impostorModel", udm.TYPE_STRING, mdlName)
				actorEditor:CreateNewActorComponent(actor, "retarget_rig", false)
				actorEditor:CreateNewActorComponent(actor, "retarget_morph", false)
				actorEditor:UpdateActorComponents(actor)
				filmmaker:TagRenderSceneAsDirty()
			end)
		end)
		:SetName("retarget")

	tool.get_filmmaker():CallCallbacks("PopulateActorContextMenu", pContext, actor)
	if tool.get_filmmaker():IsDeveloperModeEnabled() then
		pContext:AddItem("Assign entity to x", function()
			x = actor:FindEntity()
		end)
		pContext:AddItem("Assign entity to y", function()
			y = actor:FindEntity()
		end)
	end
	pContext
		:AddItem(locale.get_text("pfm_copy_id"), function()
			util.set_clipboard_string(tostring(actor:GetUniqueId()))
		end)
		:SetName("copy_id")
end
