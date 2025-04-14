--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../slider.lua")
include("../treeview.lua")
include("../weightslider.lua")
include("../controls_menu/controls_menu.lua")
include("../entry_edit_window.lua")
include("/gui/wimodeldialog.lua")
include("/gui/collapsiblegroup.lua")
include("/gui/optional_overlay.lua")
include("/pfm/raycast.lua")
include("/pfm/component_manager.lua")
include("/pfm/component_actions.lua")
include("/pfm/util.lua")
include("/gui/pfm/controls_menu/property_controls.lua")

util.register_class("gui.PFMActorEditor", gui.Base)

include("actor.lua")
include("actor_presets.lua")
include("collections.lua")
include("selection.lua")
include("ui.lua")
include("util.lua")
include("animation.lua")
include("actor_components.lua")
include("draganddrop.lua")
include("constraints.lua")
include("bone_merge.lua")

engine.load_library("pr_ik")

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
		pfm.get_project_manager():CallCallbacks("PopulateActorCreationMenu", self, pContext)

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

		-- Scene
		local sceneItem, sceneMenu = pContext:AddSubMenu(locale.get_text("pfm_scene"))
		sceneItem:SetName("scene")

		addPresetModelActorOption(
			"articulated_actor",
			sceneMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR,
			"pfm_create_new_articulated_actor"
		)
		addPresetActorOption("camera", sceneMenu, gui.PFMActorEditor.ACTOR_PRESET_TYPE_CAMERA, "pfm_create_new_camera")
		if hasSkyComponent == false then
			addPresetActorOption("sky", sceneMenu, gui.PFMActorEditor.ACTOR_PRESET_TYPE_SKY, "pfm_add_sky")
		end

		local subItem = sceneMenu:AddItem(locale.get_text("pfm_create_new_scene"), function()
			local pFileDialog = pfm.create_file_open_dialog(function(el, fileName)
				if fileName == nil then
					return
				end
				if self:IsValid() == false then
					return
				end
				local actor = self:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_SCENEBUILD, {
					["project"] = fileName,
				})
				pfm.undoredo.push("add_actor", pfm.create_command("add_actor", self:GetFilmClip(), { actor }))
			end)
			pFileDialog:SetRootPath("projects")
			pFileDialog:SetExtensions({
				pfm.Project.FORMAT_EXTENSION_BINARY,
				pfm.Project.FORMAT_EXTENSION_ASCII,
			})
			pFileDialog:Update()
		end)
		subItem:SetTooltip(locale.get_text("pfm_create_new_scene_desc"))
		subItem:SetName("scene")

		-- Props
		local propItem, propMenu = pContext:AddSubMenu(locale.get_text("pfm_props"))
		propItem:SetName("prop")

		addPresetModelActorOption(
			"static_prop",
			propMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP,
			"pfm_create_new_static_prop"
		)
		addPresetModelActorOption(
			"dynamic_prop",
			propMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_DYNAMIC_PROP,
			"pfm_create_new_dynamic_prop"
		)

		-- Effects
		local effectsItem, effectsMenu = pContext:AddSubMenu(locale.get_text("pfm_effects"))
		effectsItem:SetName("effects")

		addPresetActorOption(
			"particle_system",
			effectsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_PARTICLE_SYSTEM,
			"pfm_create_new_particle_system"
		)
		addPresetActorOption("decal", effectsMenu, gui.PFMActorEditor.ACTOR_PRESET_TYPE_DECAL, "pfm_create_new_decal")
		if hasFogComponent == false then
			addPresetActorOption(
				"fog_controller",
				effectsMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_FOG,
				"pfm_create_new_fog_controller"
			)
		end
		addPresetActorOption(
			"shader_override",
			effectsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_SHADER_OVERRIDE,
			"pfm_create_new_shader_override"
		)
		addPresetActorOption(
			"shader_input",
			effectsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_SHADER_INPUT,
			"pfm_create_new_shader_input"
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
		addPresetActorOption(
			"volume",
			effectsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_VOLUME,
			"pfm_create_new_volume"
		)

		-- Lights
		local lightsItem, lightsMenu = pContext:AddSubMenu(locale.get_text("pfm_lights"))
		lightsItem:SetName("lights")

		addPresetActorOption(
			"spot_light",
			lightsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_SPOT_LIGHT,
			"pfm_create_new_spot_light"
		)
		addPresetActorOption(
			"point_light",
			lightsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_POINT_LIGHT,
			"pfm_create_new_point_light"
		)
		addPresetActorOption(
			"directional_light",
			lightsMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_DIRECTIONAL_LIGHT,
			"pfm_create_new_directional_light"
		)

		local pBakingItem, pBakingMenu = pContext:AddSubMenu(locale.get_text("pfm_baking"))
		pBakingItem:SetName("baking")
		if hasLightmapperComponent == false then
			addPresetActorOption(
				"lightmapper",
				pBakingMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_LIGHTMAPPER,
				"pfm_create_lightmapper"
			)
		end
		addPresetActorOption(
			"reflection_probe",
			pBakingMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_REFLECTION_PROBE,
			"pfm_create_reflection_probe"
		)

		if hasVrManagerComponent == false then
			local pVrItem, pVrMenu = pContext:AddSubMenu(locale.get_text("virtual_reality"))
			pVrItem:SetName("virtual_reality")
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
			pVrMenu:Update()
		end

		-- Misc
		local miscItem, miscMenu = pContext:AddSubMenu(locale.get_text("pfm_misc"))
		miscItem:SetName("misc")

		addPresetActorOption("actor", miscMenu, gui.PFMActorEditor.ACTOR_PRESET_TYPE_ACTOR, "pfm_create_new_actor")

		addPresetActorOption(
			"greenscreen",
			miscMenu,
			gui.PFMActorEditor.ACTOR_PRESET_TYPE_GREENSCREEN,
			"pfm_create_greenscreen"
		)

		if tool.get_filmmaker():IsDeveloperModeEnabled() then
			local pConstraintItem, pConstraintMenu = pContext:AddSubMenu(locale.get_text("pfm_constraints"))
			pConstraintItem:SetName("constraints")
			addPresetActorOption(
				"copy_location_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_LOCATION,
				"pfm_create_copy_location_constraint"
			)
			addPresetActorOption(
				"copy_rotation_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_ROTATION,
				"pfm_create_copy_rotation_constraint"
			)
			addPresetActorOption(
				"copy_scale_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_COPY_SCALE,
				"pfm_create_copy_scale_constraint"
			)
			addPresetActorOption(
				"limit_distance_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_DISTANCE,
				"pfm_create_limit_distance_constraint"
			)
			addPresetActorOption(
				"limit_location_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_LOCATION,
				"pfm_create_limit_location_constraint"
			)
			addPresetActorOption(
				"limit_rotation_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_ROTATION,
				"pfm_create_limit_rotation_constraint"
			)
			addPresetActorOption(
				"limit_scale_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LIMIT_SCALE,
				"pfm_create_limit_scale_constraint"
			)
			addPresetActorOption(
				"look_at_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_LOOK_AT,
				"pfm_create_look_at_constraint"
			)
			addPresetActorOption(
				"child_of_constraint",
				pConstraintMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF,
				"pfm_create_child_of_constraint"
			)
			pConstraintMenu:Update()

			addPresetActorOption(
				"animation_driver",
				miscMenu,
				gui.PFMActorEditor.ACTOR_PRESET_TYPE_ANIMATION_DRIVER,
				"pfm_create_animation_driver"
			)
		end
		sceneMenu:Update()
		propMenu:Update()
		effectsMenu:Update()
		lightsMenu:Update()
		pBakingMenu:Update()
		miscMenu:Update()

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

	local resizer = gui.create("WIResizer", self.m_contents)
	self.m_centralDivider = resizer

	local dataVBox
	local scrollContainer =
		gui.create("WIScrollContainer", self.m_contents, 0, 0, self.m_contents:GetWidth(), self.m_contents:GetHeight())
	scrollContainer:AddCallback("SetSize", function(el)
		if self:IsValid() and util.is_valid(dataVBox) then
			dataVBox:SetWidth(el:GetWidth())
		end
	end)

	dataVBox = gui.create("WIVBox", scrollContainer, 0, 0, scrollContainer:GetWidth(), scrollContainer:GetHeight())
	dataVBox:SetFixedWidth(true)

	self.m_propertyContainer = dataVBox
	self.m_componentPropertyGroups = {}
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
	self.m_collectionItems = {}
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
				w = math.max(w, treeScrollContainerBg:GetWidth())
				self.m_tree:SetWidth(w)
			end
		end)
	end)
	--[[self.m_data = gui.create("WITable",dataVBox,0,0,dataVBox:GetWidth(),dataVBox:GetHeight(),0,0,1,1)

	self.m_data:SetRowHeight(self.m_tree:GetRowHeight())
	self.m_data:SetSelectableMode(gui.Table.SELECTABLE_MODE_SINGLE)]]

	self.m_componentManager = pfm.ComponentManager()

	-- self.m_leftRightWeightSlider = gui.create("WIPFMWeightSlider", self.m_animSetControls)
	self.m_specialPropertyIcons = {}

	local pm = tool.get_filmmaker()
	pm:AddCallback("OnGameViewReloaded", function()
		self:InitAnimManagerListeners()
	end)
	self:InitAnimManagerListeners()

	self:SetMouseInputEnabled(true)
end
function gui.PFMActorEditor:ClearEmptyComponentPropertyGroups()
	local tNew = {}
	for uuid, actorGroupData in pairs(self.m_componentPropertyGroups) do
		local tNewGroups = {}
		local n = 0
		for ctype, group in pairs(actorGroupData.componentGroups) do
			if not group.collapsibleGroup:IsValid() or group.controlElement:GetControlCount() == 0 then
				util.remove(group.collapsibleGroup)
			else
				tNewGroups[ctype] = group
				n = n + 1
			end
		end
		if n == 0 then
			util.remove(actorGroupData.collapsibleGroup)
		else
			actorGroupData.componentGroups = tNewGroups
			tNew[uuid] = actorGroupData
		end
	end
	self.m_componentPropertyGroups = tNew
end
function gui.PFMActorEditor:AddComponentPropertyGroup(actor, udmComponent)
	local uuid = tostring(actor:GetUniqueId())
	local ctype = (type(udmComponent) == "string") and udmComponent or udmComponent:GetType()
	if
		self.m_componentPropertyGroups[uuid] ~= nil
		and self.m_componentPropertyGroups[uuid].componentGroups[ctype] ~= nil
	then
		return self.m_componentPropertyGroups[uuid].componentGroups[ctype]
	end
	local actorGroup
	if self.m_componentPropertyGroups[uuid] ~= nil then
		actorGroup = self.m_componentPropertyGroups[uuid].collapsibleGroup
	end
	if util.is_valid(actorGroup) == false then
		local collapsible = gui.create("WICollapsibleGroup", self.m_propertyContainer)
		collapsible:SetAutoAlignToParent(true, false)
		collapsible:SetGroupName(actor:GetName())
		collapsible:Expand()
		actorGroup = collapsible
		self.m_componentPropertyGroups[uuid] = { collapsibleGroup = collapsible, componentGroups = {} }
	end
	local collapsible = actorGroup:AddGroup(locale.get_text("c_" .. ctype))
	collapsible:Expand()
	local collapsibleContents = collapsible:GetContents()

	local animSetControls = gui.create(
		"WIPFMPropertyControls",
		collapsibleContents,
		0,
		0,
		collapsibleContents:GetWidth(),
		collapsibleContents:GetHeight()
	)
	animSetControls:SetAutoAlignToParent(true, false)
	animSetControls:SetName("property_controls")
	animSetControls:GetControlsMenu():AddCallback("OnControlAdded", function(el, name, ctrl, wrapper)
		if wrapper ~= nil then
			wrapper:AddCallback("OnValueChanged", function()
				local filmmaker = tool.get_filmmaker()
				filmmaker:TagRenderSceneAsDirty()
			end)
		end
	end)

	self.m_componentPropertyGroups[uuid].componentGroups[ctype] = {
		collapsibleGroup = collapsible,
		controlElement = animSetControls:GetControlsMenu(),
	}
	return self.m_componentPropertyGroups[uuid].componentGroups[ctype]
end
function gui.PFMActorEditor:ClearAnimManagerListeners()
	if self.m_animManagerListeners == nil then
		return
	end
	util.remove(self.m_animManagerListeners)
	self.m_animManagerListeners = nil
end
function gui.PFMActorEditor:InitAnimManagerListeners()
	self:ClearAnimManagerListeners()

	self.m_animManagerListeners = {}
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager == nil then
		return
	end
	table.insert(
		self.m_animManagerListeners,
		animManager:AddEventListener(ents.PFMAnimationManager.EVENT_ON_CHANNEL_ADDED, function(actor, path)
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
		self.m_animManagerListeners,
		animManager:AddEventListener(ents.PFMAnimationManager.EVENT_ON_CHANNEL_REMOVED, function(actor, path)
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
function gui.PFMActorEditor:GetActorItems()
	local t = {}
	for item, actorData in pairs(self.m_treeElementToActorData) do
		if item:IsValid() then
			table.insert(t, item)
		end
	end
	return t
end
function gui.PFMActorEditor:TagRenderSceneAsDirty(dirty)
	tool.get_filmmaker():TagRenderSceneAsDirty(dirty)
end
function gui.PFMActorEditor:GetTimelineMode()
	return tool.get_filmmaker():GetTimelineMode()
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
	if self.m_clearEmptyComponentPropertyGroups then
		self:ClearEmptyComponentPropertyGroups()
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
		self:ResolveConstraintItems()
	end
	if self.m_constraintItemsDirty ~= nil then
		self.m_constraintItemsDirty = nil
		self:ResolveConstraintItems()
	end
	if self.m_updatePropertyIcons then
		self.m_updatePropertyIcons = nil
		self:UpdateConstraintPropertyIcons()
	end
	self:DisableThinking()
end
function gui.PFMActorEditor:SetConstraintPropertyIconsDirty()
	self.m_updatePropertyIcons = true
	self:EnableThinking()
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
	self.m_collectionItems = {}
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
function gui.PFMActorEditor:OnAnimationChannelMathExpressionChanged(channel, track, animationClip, self, oldExpr, expr)
	local actor = animationClip:GetActor()
	local targetPath = channel:GetTargetPath()
	local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
	local componentId = (componentName ~= nil) and ents.get_component_id(componentName) or nil
	if componentId == nil then
		return
	end
	self:UpdatePropertyIcons(tostring(actor:GetUniqueId()), componentId, targetPath)
end
function gui.PFMActorEditor:OnGraphCurveAnimationDataChanged(filmClip, graphCurve, animClip, channel, valueBaseIndex)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()

	local actor = animClip:GetActor()
	local targetPath = channel:GetTargetPath()
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
	add_change_listener(
		"OnAnimationChannelMathExpressionChanged",
		function(filmClip, track, animationClip, channel, oldExpr, expr)
			self:OnAnimationChannelMathExpressionChanged(channel, track, animationClip, self, oldExpr, expr)
		end
	)
	add_change_listener(
		"OnGraphCurveAnimationDataChanged",
		function(filmClip, graphCurve, animClip, channel, valueBaseIndex)
			self:OnGraphCurveAnimationDataChanged(filmClip, graphCurve, animClip, channel, valueBaseIndex)
		end
	)

	local function add_actors(parent, parentItem, root)
		local itemGroup = self:AddCollectionItem(parentItem or self.m_tree, parent, root)
		if root then
			itemGroup:SetText("Scene")
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

	-- TODO: Get rid of this timer
	time.create_simple_timer(0.1, function()
		if self:IsValid() then
			local elRoot = self.m_tree:GetRoot()
			local el = elRoot:GetItems()[1]
			elRoot:Update()
			if util.is_valid(el) then
				-- Expand top-most item
				el:Expand()
			end
			self:ResolveConstraintItems()
		end
	end)

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
function gui.PFMActorEditor:ApplyComponentChannelValue(
	actorEditor,
	component,
	controlData,
	udmType,
	oldValue,
	value,
	final
)
	local actor = component:GetActor()
	if actor ~= nil and controlData.path ~= nil then
		actorEditor:UpdateAnimationChannelValue(actor, controlData.path, udmType, oldValue, value, nil, final)
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

	local function get_translated_value(controlData)
		local val = controlData.getValue()
		if val ~= nil then
			if controlData.translateToInterface ~= nil then
				val = controlData.translateToInterface(val)
			end
		end
		return val
	end

	local ctrl
	local container
	local animSetControls = self:AddComponentPropertyGroup(actor, udmComponent).controlElement
	if controlData.path ~= nil then
		local displayName, description = pfm.util.get_localized_property_name(udmComponent:GetType(), memberInfo.name)
		if memberInfo:HasFlag(ents.ComponentInfo.MemberInfo.FLAG_READ_ONLY_BIT) then
			local elText, wrapper, c = animSetControls:AddText(baseMemberName, displayName, controlData.default or "")
			if controlData.getValue ~= nil then
				controlData.updateControlValue = function()
					if elText:IsValid() == false then
						return
					end
					local val = get_translated_value(controlData)
					if val ~= nil then
						elText:SetText(val)
					end
				end
			end
			ctrl = wrapper
			container = c
		elseif memberInfo.type == ents.MEMBER_TYPE_ELEMENT then
			local bt, wrapper, c = animSetControls:AddButton(
				locale.get_text("edit") .. " " .. displayName,
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
								udmComponent:SyncUdmPropertyToEntity(memberInfo.name, true)
							end
							-- c:OnMemberValueChanged(memberIdx)
							return true
						end, rootPath)
					end
				end
			)
			ctrl = bt
			container = c
		else
			local propInfo = {}
			if memberInfo:IsEnum() then
				local enumValues = {}
				for i, v in ipairs(memberInfo:GetEnumValues()) do
					local name = memberInfo:ValueToEnumName(v)
					if name ~= "Count" then
						table.insert(enumValues, { tostring(v), name })
					end
				end
				propInfo.enumValues = enumValues
			end
			propInfo.defaultValue = controlData.default
			propInfo.minValue = memberInfo.minValue
			propInfo.maxValue = memberInfo.maxValue
			propInfo.unit = controlData.unit
			propInfo.specializationType = memberInfo.specializationType
			local translateToInterface = function(val)
				if controlData.translateToInterface ~= nil then
					val = controlData.translateToInterface(val)
				end
				return val
			end
			local translateFromInterface = function(val)
				if controlData.translateFromInterface ~= nil then
					val = controlData.translateFromInterface(val)
				end
				return val
			end
			if udm.is_numeric_type(memberInfo.type) then
				local channel = self:GetAnimationChannel(actorData.actor, controlData.path, false)
				local hasExpression = (channel ~= nil and channel:GetExpression() ~= nil)
				if hasExpression == false then
					if memberInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_DISTANCE then
						propInfo.unit = locale.get_text("symbol_meters")
						translateToInterface = function(val)
							return util.units_to_metres(val)
						end
						translateFromInterface = function(val)
							return util.metres_to_units(val)
						end
					elseif
						memberInfo.specializationType
						== ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_LIGHT_INTENSITY
					then
						-- TODO
						propInfo.unit = locale.get_text("symbol_lumen") --(self:GetIntensityType() == ents.LightComponent.INTENSITY_TYPE_CANDELA) and locale.get_text("symbol_candela") or locale.get_text("symbol_lumen")
					end
				end
			end
			if memberInfo.specializationType == ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE then
				local meta = memberInfo.metaData or udm.create_element()
				propInfo.basePath = meta:GetValue("basePath")
				propInfo.rootPath = meta:GetValue("rootPath")
				propInfo.stripExtension = meta:GetValue("stripExtension")
				propInfo.extensions = meta:Get("extensions"):ToTable()
				propInfo.assetType = meta:GetValue("assetType")
			end
			local wrapper = animSetControls:AddPropertyControl(memberInfo.type, memberInfo.name, displayName, propInfo)
			if wrapper ~= nil then
				pfm.call_event_listeners(
					"OnActorPropertyControlAdded",
					actor,
					controlData.path,
					memberInfo.type,
					wrapper,
					animSetControls
				)
				wrapper:SetValueTranslationFunctions(translateToInterface, translateFromInterface)

				ctrl = wrapper:GetWrapperElement()
				container = wrapper:GetContainerElement()
				local val = false
				if controlData.getValue ~= nil then
					val = controlData.getValue()
				end
				wrapper:SetValue(val)
				wrapper:SetOnChangeValueHandler(function(val, isFinal, initialValue)
					if self.m_skipUpdateCallback then
						return
					end
					if controlData.set ~= nil then
						local inputData
						if initialValue ~= nil then
							inputData = {
								initialValue = initialValue,
							}
						end
						controlData.set(udmComponent, val, nil, nil, isFinal, inputData)
					end
				end)

				controlData.updateControlValue = function()
					local val = controlData.getValue()
					if val ~= nil then
						wrapper:SetValue(val)
					end
				end
			end
		end
	end
	if util.is_valid(ctrl) == false then
		if controlData.addControl then
			ctrl = controlData.addControl(animSetControls, function(value)
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
			local propData = { actorData = actorData, controlData = controlData }
			self:PopulatePropertyContextMenu(context, { propData }, propData)
		end)

		local identifier = memberInfo.name:replace("/", "_")
		ctrl:SetName(identifier)

		local metaInfoOpt = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_OPTIONAL)
		if metaInfoOpt ~= nil and util.is_valid(container) then
			local elCheckbox = gui.create("WICheckbox")
			elCheckbox:SetTooltip(locale.get_text("pfm_click_toggle_property"))
			container:AddIcon(elCheckbox)

			local componentName, memberName =
				ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(controlData.path))
			local optPropName = "ec/" .. componentName .. "/" .. metaInfoOpt.enabledProperty
			local elOverlay
			local cb
			local function initCallback()
				if cb ~= nil then
					return
				end
				local c = actor:FindComponent(componentName)
				cb = c:AddChangeListener(metaInfoOpt.enabledProperty, function(c, newVal)
					elOverlay:SetVisible(not newVal)
					elCheckbox:SetChecked(newVal)
				end)
			end
			initCallback()

			local toggling = false
			local function toggle()
				if toggling then
					return
				end
				toggling = true
				local curVal = actor:GetMemberValue(optPropName) or false
				local cmd =
					pfm.create_command("set_actor_property", actor, optPropName, curVal, not curVal, udm.TYPE_BOOLEAN)

				cmd:Execute()

				initCallback()
				toggling = false
			end

			local curVal = actor:GetMemberValue(optPropName) or false
			elOverlay = gui.create("WIOptionalOverlay", ctrl, 0, 0, ctrl:GetWidth(), ctrl:GetHeight(), 0, 0, 1, 1)
			elOverlay:SetZPos(100)
			elOverlay:SetVisible(not curVal)
			elCheckbox:SetChecked(curVal)
			elOverlay:AddCallback("OnRemove", function()
				util.remove(cb)
			end)
			elOverlay:AddCallback("OnClicked", toggle)
			elOverlay:SetText(memberName:GetBack())

			elCheckbox:AddCallback("OnChange", toggle)
		end
	end
	self:SetComponentPropertyGroupsDirty()
	self:UpdateControlValue(controlData)
	self:CallCallbacks("OnControlSelected", actor, udmComponent, controlData, ctrl, container)
	return ctrl, container
end
function gui.PFMActorEditor:SetComponentPropertyGroupsDirty()
	self.m_clearEmptyComponentPropertyGroups = true
	self:EnableThinking()
end
function gui.PFMActorEditor:AddIkController(actor, boneName, chainLength)
	self:LogDebug(
		"Adding ik controller for bone '"
			.. boneName
			.. "' of actor '"
			.. tostring(actor)
			.. "' with chain length "
			.. chainLength
			.. "..."
	)
	if chainLength <= 1 then
		self:LogDebug("Chain length of " .. chainLength .. " is not long enough! Ik Controller will not be created.")
		return false
	end

	local solverC = self:CreateNewActorComponent(actor, "ik_solver", false)
	self:CreateNewActorComponent(actor, "pfm_fbik", false)
	if solverC == nil then
		self:LogDebug("Failed to add ik_solver component! Ik Controller will not be created.")
		return false
	end

	local ent = actor:FindEntity()
	if util.is_valid(ent) == false then
		self:LogDebug("Actor entity is not valid! Ik Controller will not be created.")
		return false
	end
	local mdl = ent:GetModel()
	local skeleton = mdl:GetSkeleton()
	local boneId = mdl:LookupBone(boneName)
	if boneId == -1 then
		self:LogDebug(
			"Bone '"
				.. boneName
				.. "' could not be found in model '"
				.. mdl:GetName()
				.. "'! Ik Controller will not be created."
		)
		return false
	end

	ent:AddComponent("ik_solver")
	self:UpdateActorComponents(actor)

	ent = actor:FindEntity()
	local ikSolverC = util.is_valid(ent) and ent:AddComponent("ik_solver") or nil
	if ikSolverC == nil then
		self:LogDebug("Actor entity does not have ik_solver component! Ik Controller will not be created.")
		return false
	end
	local bone = skeleton:GetBone(boneId)

	ikSolverC:AddIkSolverByChain(boneName, chainLength)
	solverC:SyncUdmPropertyFromEntity("rigConfig", false)

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
local function get_constraint_interface_target_property_name(propName)
	local identifierPropPath = util.Path.CreateFilePath(propName)
	if identifierPropPath:GetBack() == "pose" then
		-- If the constraint refers to a pose property, we'll just defer it to the position
		-- (Otherwise we'd have to duplicate it for the rotation as well)
		identifierPropPath:PopBack()
		identifierPropPath = identifierPropPath + "position"
	end
	return identifierPropPath:GetString()
end
-- This will move all constraint items in the actor editor to the
-- (driven) property items they are associated with.
function gui.PFMActorEditor:ResolveConstraintItems()
	local constraintItems = {}
	for _, itemConstraint in ipairs(self:GetActorItems()) do
		if itemConstraint:IsValid() then
			table.insert(constraintItems, itemConstraint)
		end
	end
	for _, itemConstraint in ipairs(constraintItems) do
		local uuidItem = itemConstraint:GetName()
		local actor = pfm.dereference(uuidItem)
		if actor ~= nil then
			local constraint = actor:FindComponent("constraint")
			if constraint ~= nil then
				local drivenObject = constraint:GetMemberValue("drivenObject")
				local ref = (drivenObject ~= nil) and ents.parse_uri(drivenObject) or nil
				if ref == nil then
					return {}
				end
				local uuid = tostring(ref:GetUuid())
				local componentType = ref:GetComponentName()
				local propName = ref:GetMemberName()
				local drivenObjectActor = pfm.dereference(uuid)
				if drivenObjectActor ~= nil then
					local itemDriven = self:GetActorComponentItem(drivenObjectActor, componentType)
					if util.is_valid(itemDriven) then
						local drivenComponent = drivenObjectActor:FindComponent(componentType)
						if drivenComponent ~= nil then
							local identifierPropPath = get_constraint_interface_target_property_name(propName)
							local identifier = "ec/" .. componentType .. "/" .. identifierPropPath
							local itemTarget = itemDriven:FindItemByIdentifier(identifier, true)
							if util.is_valid(itemTarget) then
								-- We don't want the constraint to be automatically selected when the
								-- property is selected
								itemTarget:SetAutoSelectChildren(false)

								itemTarget:AttachItem(itemConstraint)
								itemConstraint:ScheduleUpdate()
								itemTarget:ScheduleUpdate()
							end
						end
					end
				end
			end
		end
	end
end
function gui.PFMActorEditor:AddContextMenuConstraintOptions(context, prop0, prop1)
	local actor1
	local propertyPath1
	if prop1 ~= nil then
		actor1 = prop1.actor
		propertyPath1 = prop1.path
	end

	local ent = prop0.actor:FindEntity()
	local memberInfo = util.is_valid(ent) and pfm.get_member_info(prop0.path, ent) or nil
	if memberInfo ~= nil then
		local constraintTypes = pfm.util.find_applicable_constraint_types(memberInfo, actor1, propertyPath1)
		if #constraintTypes > 0 then
			for _, type in ipairs(constraintTypes) do
				local name = gui.PFMActorEditor.constraint_type_to_name(type)
				context
					:AddItem(locale.get_text("c_constraint_" .. name), function()
						self:AddConstraint(type, prop0.actor, prop0.path, actor1, propertyPath1)
					end)
					:SetName("constraint_" .. name)
			end
			return true
		end
	end
	return false
end
function gui.PFMActorEditor:PopulatePropertyContextMenu(context, propDatas, clickedPropData)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	if animManager ~= nil then
		--[[local enable_expr_icon
		enable_expr_icon = function(enabled)
			self:DoUpdatePropertyIcons(actorData, clickedControlData)
		end
		local pm = pfm.get_project_manager()
		local animManager = pm:GetAnimationManager()
		if animManager ~= nil and animManager:GetValueExpression(actorData.actor, clickedControlData.path) ~= nil then
			enable_expr_icon(true)
		end]]

		local hasExpr = false
		for _, pd in ipairs(propDatas) do
			if animManager:GetValueExpression(pd.actorData.actor, pd.controlData.path) ~= nil then
				hasExpr = true
				break
			end
		end
		if hasExpr then
			context
				:AddItem(locale.get_text("pfm_clear_expression"), function()
					local cmd = pfm.create_command("composition")
					for _, pd in ipairs(propDatas) do
						cmd:AddSubCommand(
							"set_property_expression",
							tostring(pd.actorData.actor:GetUniqueId()),
							pd.controlData.path,
							nil,
							pd.controlData.type
						)
					end
					pfm.undoredo.push("set_property_expression", cmd)()
				end)
				:SetName("clear_expression")
			if #propDatas == 1 then
				context
					:AddItem(locale.get_text("pfm_copy_expression"), function()
						local expr = animManager:GetValueExpression(
							clickedPropData.actorData.actor,
							clickedPropData.controlData.path
						)
						if expr == nil then
							return
						end
						util.set_clipboard_string(expr)
					end)
					:SetName("copy_expression")
			end
		end
		if #propDatas == 1 then
			context
				:AddItem(locale.get_text("pfm_set_expression"), function()
					self:OpenPropertyExpressionWindow(clickedPropData.actorData, clickedPropData.controlData)
				end)
				:SetName("set_expression")
		end
		if #propDatas == 1 and clickedPropData.controlData.path ~= nil then
			context
				:AddItem(locale.get_text("pfm_copy_property_path"), function()
					util.set_clipboard_string(
						ents.create_uri(clickedPropData.actorData.actor:GetUniqueId(), clickedPropData.controlData.path)
					)
				end)
				:SetName("copy_property_path")
		end
		local cdsWithAnimData = {}
		local cdsWithoutAnimData = {}
		for _, pd in ipairs(propDatas) do
			local anim, channel = animManager:FindAnimationChannel(pd.actorData.actor, pd.controlData.path, false)
			if channel ~= nil then
				table.insert(cdsWithAnimData, {
					actorData = pd.actorData,
					controlData = pd.controlData,
					anim = anim,
					channel = channel,
				})
			else
				table.insert(cdsWithoutAnimData, {
					actorData = pd.actorData,
					controlData = pd.controlData,
				})
			end
		end
		if #cdsWithAnimData > 0 then
			context
				:AddItem(locale.get_text("pfm_clear_animation"), function()
					tool.get_filmmaker()
					local cmd = pfm.create_command("composition")
					local actors = {}
					for _, cdData in ipairs(cdsWithAnimData) do
						local controlData = cdData.controlData
						tool.get_filmmaker():MakeActorPropertyAnimated(
							cdData.actorData.actor,
							controlData.path,
							controlData.type,
							false,
							nil,
							cmd
						)
						actors[cdData.actorData.actor] = true
					end
					pfm.undoredo.push("clear_property_animation", cmd)()
					for actor, _ in pairs(actors) do
						tool.get_filmmaker():UpdateActorAnimationState(actor, false)
					end
				end)
				:SetName("clear_animation")
		end
		if #cdsWithoutAnimData > 0 then
			context
				:AddItem(locale.get_text("pfm_make_animated"), function()
					local cmd = pfm.create_command("composition")
					local actors = {}
					for _, cdData in ipairs(cdsWithoutAnimData) do
						tool.get_filmmaker():MakeActorPropertyAnimated(
							cdData.actorData.actor,
							cdData.controlData.path,
							cdData.controlData.type,
							nil,
							nil,
							cmd
						)
						actors[cdData.actorData.actor] = true
					end
					pfm.undoredo.push("make_property_animated", cmd)()
					for actor, _ in pairs(actors) do
						tool.get_filmmaker():UpdateActorAnimationState(actor, true)
					end
				end)
				:SetName("make_animated")

			local controlDataMemberInfos = {}
			for _, pd in ipairs(propDatas) do
				local memberInfo = self:GetMemberInfo(pd.actorData.actor, pd.controlData.path)
				if memberInfo ~= nil and memberInfo.default ~= nil then
					table.insert(controlDataMemberInfos, {
						memberInfo = memberInfo,
						actorData = pd.actorData,
						controlData = pd.controlData,
					})
				end
			end

			if #controlDataMemberInfos > 0 then
				context
					:AddItem(locale.get_text("pfm_set_to_default"), function()
						local cmd = pfm.create_command("composition")
						for _, cdInfo in ipairs(controlDataMemberInfos) do
							local controlData = cdInfo.controlData
							local memberInfo = self:GetMemberInfo(cdInfo.actorData.actor, controlData.path)
							if memberInfo ~= nil and memberInfo.default ~= nil then
								tool.get_filmmaker():ChangeActorPropertyValue(
									cdInfo.actorData.actor,
									controlData.path,
									memberInfo.type,
									controlData.getValue(),
									memberInfo.default,
									nil,
									nil,
									cmd
								)
							end
						end
						pfm.undoredo.push("change_animation_value", cmd)()
					end)
					:SetName("reset_to_base_value")
			end
		end
	end

	local function init_props(props)
		local hasControlData = false
		for i, propOther in ipairs(props) do
			if propOther.controlData == clickedPropData.controlData then
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
			table.insert(props, 1, { actorData = clickedPropData.actorData, controlData = clickedPropData.controlData })
		end
	end

	local props = self:GetSelectedPoseProperties()
	init_props(props)
	if #props > 0 then
		local constraintProps = props
		if #constraintProps > 2 then
			constraintProps = { { actorData = clickedPropData.actorData, controlData = clickedPropData.controlData } }
		end -- If more than two properties are selected, we'll only show self-contained constraints for the property that was clicked
		if constraintProps[1].controlData == clickedPropData.controlData then
			local t = {}
			for _, propData in ipairs(constraintProps) do
				table.insert(t, {
					actor = propData.actorData.actor,
					path = propData.controlData.path,
				})
			end

			local ctItem, ctMenu = context:AddSubMenu(locale.get_text("pfm_add_constraint"))
			ctItem:SetName("add_constraint")
			if self:AddContextMenuConstraintOptions(context, t[1], t[2]) == false then
				context:RemoveSubMenu(ctMenu)
			else
				ctMenu:Update()
			end
		end
	end

	props = self:GetSelectedProperties()
	init_props(props)
	if
		#propDatas == 1
		and util.is_valid(clickedPropData.controlData.treeElement)
		and clickedPropData.controlData.treeElement.__elDriverActorData ~= nil
		and util.is_valid(clickedPropData.controlData.treeElement.__elDriverActorData.icon)
	then
		-- Don't allow adding driver if there already is one
	elseif #props > 0 then
		local prop = props[1]
		if clickedPropData.controlData.type < udm.TYPE_COUNT then
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

							if clickedPropData.controlData.set ~= nil then
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

	if #propDatas == 1 and clickedPropData.controlData.type == ents.MEMBER_TYPE_COMPONENT_PROPERTY then
		context
			:AddItem(locale.get_text("pfm_go_to_property"), function()
				local val = clickedPropData.controlData.getValue()
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

	local isBaseProperty = false -- not ents.is_member_type_animatable(memberInfo.type)
	local baseItem = item -- isBaseProperty and componentData.itemBaseProps or item

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

	local displayName, description = pfm.util.get_localized_property_name(identifier)

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

			self:PopulatePropertyContextMenu(pContext, self:GetSelectedProperties(), {
				actorData = actorData,
				controlData = controlData,
			})
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		elseif button == input.MOUSE_BUTTON_LEFT then
			if state == input.STATE_PRESS then
				self:StartConstraintDragAndDropMode(child, controlData.path)
			else
				self:EndConstraintDragAndDropMode()
			end
		end
	end)

	local ctrl
	local container
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
		ctrl, container = self:OnControlSelected(actor, actorData, udmComponent, controlData)
		if ctrl ~= nil then
			local uid = tostring(actor:GetUniqueId())
			self.m_activeControls[uid] = self.m_activeControls[uid] or {}
			self.m_activeControls[uid][controlData.path] = {
				actor = actor,
				control = ctrl,
				container = container,
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
		if util.is_valid(container) == false then
			return
		end
		container:Remove()
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
function gui.PFMActorEditor:GetPropertyEntries(uuid, componentType)
	local elComponent, componentData, actorData = self:GetComponentEntry(uuid, componentType)
	if elComponent == nil then
		return {}
	end
	local t = {}
	for _, itemData in pairs(componentData.items) do
		table.insert(t, itemData.treeElement)
	end
	return t
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

	local function get_property_entry_data(uuid, componentType, propName, resolvePoseProperty)
		local identifierPropPath = propName
		if resolvePoseProperty then
			identifierPropPath = get_constraint_interface_target_property_name(identifierPropPath)
		end
		propName = "ec/" .. componentType .. "/" .. identifierPropPath
		local el, ctrlData, componentDataDriven, actorDataDriven = self:GetPropertyEntry(uuid, componentType, propName)
		if util.is_valid(el) == false then
			return
		end
		return {
			element = el,
			actorUuid = uuid,
			propertyName = propName,
		}
	end
	local function find_property_object_entry(elActor, componentType, propName)
		local actorData = self.m_treeElementToActorData[elActor]
		if actorData == nil then
			return {}
		end
		local c = actorData.actor:FindComponent(componentType)
		if c == nil then
			return {}
		end
		local drivenObject = c:GetMemberValue(propName)
		if drivenObject == nil then
			return {}
		end
		local ref = ents.parse_uri(drivenObject)
		if ref == nil then
			return {}
		end
		local uuid = ref:GetUuid()
		local componentType = ref:GetComponentName()
		local propName = ref:GetMemberName()

		local t = {}
		local ent = actorData.actor:FindEntity()
		if util.is_valid(ent) then
			local c = ent:GetComponent(componentType)
			if c ~= nil then
				local propertyPath = "ec/" .. componentType .. "/" .. propName
				local memberInfo = pfm.get_member_info(propertyPath, ent)
				if memberInfo ~= nil then
					local metaInfoPose = memberInfo:FindTypeMetaData(ents.ComponentInfo.MemberInfo.TYPE_META_DATA_POSE)
					if metaInfoPose ~= nil then
						local tPos = get_property_entry_data(uuid, componentType, metaInfoPose.posProperty)
						local tRot = get_property_entry_data(uuid, componentType, metaInfoPose.rotProperty)
						if tPos ~= nil then
							tPos.actorData = actorData
							tPos.originalProperty = propertyPath
							table.insert(t, tPos)
						end
						if tRot ~= nil then
							tRot.actorData = actorData
							tRot.originalProperty = propertyPath
							table.insert(t, tRot)
						end
						return t
					end
				end
			end
		end

		local tEntry = get_property_entry_data(uuid, componentType, propName, true)
		if tEntry == nil then
			return {}
		end
		tEntry.actorData = actorData
		tEntry.originalProperty = tEntry.propertyName
		table.insert(t, tEntry)
		return t
	end

	local function find_driven_object_entry(elActor, componentType)
		return find_property_object_entry(elActor, componentType, "drivenObject")
	end

	local function add_icon(elActor, componentType, icon)
		local tIcons = {}
		local tDriven = find_driven_object_entry(elActor, componentType)
		if #tDriven > 0 then
			for _, drivenData in ipairs(tDriven) do
				local icon = drivenData.element:AddIcon(icon)
				if util.is_valid(icon) then
					icon:SetName(componentType)
					icon:SetCursor(gui.CURSOR_SHAPE_HAND)
					icon:SetMouseInputEnabled(true)
					icon:AddCallback("OnMouseEvent", function(wrapper, button, state, mods)
						if button == input.MOUSE_BUTTON_LEFT then
							if state == input.STATE_PRESS then
								self:SelectActor(
									drivenData.actorData.actor,
									true,
									"ec/" .. componentType .. "/drivenObject"
								)
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
										local tDriver = find_property_object_entry(elActor, "constraint", "driver")
										if #tDriver > 0 then
											local driverData = tDriver[1]
											local pm = pfm.get_project_manager()
											local session = pm:GetSession()
											local schema = session:GetSchema()
											local actorDriver = udm.dereference(schema, tostring(driverData.actorUuid))
											if actorDriver ~= nil then
												self:SelectActor(actorDriver, true, driverData.propertyName)
											end
										end
									end)
									:SetName("go_to_driver_property")
								pContext
									:AddItem(locale.get_text("remove"), function()
										self:RemoveConstraint(drivenData.actorData.actor)
									end)
									:SetName("remove")
								pContext:Update()
							end
							return util.EVENT_REPLY_HANDLED
						end
					end)
					table.insert(self.m_specialPropertyIcons["constraints"], {
						icon = icon,
						actorUuid = drivenData.actorUuid,
						componentType = componentType,
						property = drivenData.propertName,
					})
					table.insert(tIcons, {
						icon = icon,
						actorData = drivenData.actorData,
						element = drivenData.element,
						property = drivenData.propertyName,
					})
				end
			end
		end
		return tIcons
	end

	self:IterateActors(function(el)
		local tIcons = add_icon(el, "constraint", "gui/pfm/icon_constraint")
		for _, iconData in ipairs(tIcons) do
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
				"child_of",
			}) do
				if iconData.actorData.actor:HasComponent("constraint_" .. ctName) then
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

			local tDriver = find_property_object_entry(el, "constraint", "driver")
			local actorDriver
			if #tDriver > 0 then
				local pm = pfm.get_project_manager()
				local session = pm:GetSession()
				local schema = session:GetSchema()
				actorDriver = udm.dereference(schema, tostring(tDriver[1].actorUuid))
			end
			if actorDriver ~= nil then
				iconData.icon:SetTooltip(
					locale.get_text(
						"pfm_constraint_to",
						{ constraintName, tDriver[1].originalProperty, actorDriver:GetName() }
					)
				)
			else
				iconData.icon:SetTooltip(locale.get_text("pfm_constraint", { constraintName }))
			end

			local elDrivenObject = iconData.element
			elDrivenObject.__elConstraintActorData = elDrivenObject.__elConstraintActorData or {}
			for i = #elDrivenObject.__elConstraintActorData, 1, -1 do
				local data = elDrivenObject.__elConstraintActorData[i]
				if data.icon:IsValid() == false then
					table.remove(elDrivenObject.__elConstraintActorData, i)
				end
			end

			table.insert(elDrivenObject.__elConstraintActorData, {
				icon = iconData.icon,
				constraintActorElement = el,
			})
		end

		local tIcons = add_icon(el, "animation_driver", "gui/pfm/icon_driver")
		for _, iconData in ipairs(tIcons) do
			iconData.icon:SetTooltip(locale.get_text("pfm_animation_driver"))
			iconData.element.__elDriverActorData = {
				icon = iconData.icon,
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

	self:SetConstraintPropertyIconsDirty()
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
		self:CallCallbacks("OnCameraLinkModeEnded", actor)
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
		self:CallCallbacks("OnCameraLinkModeEntered", actor)
	end
end
function gui.PFMActorEditor:SaveUiState(data)
	local udmTree = data:Add("tree")
	local function get_items(parent)
		local t = {}
		for _, item in ipairs(parent:GetItems()) do
			if item:IsValid() and (item:IsExpanded() or item:IsSelected()) then
				local tChildren = get_items(item)
				table.insert(t, {
					item = item,
					children = tChildren,
				})
			end
		end
		return t
	end

	local function write_items(t, udmParent)
		for _, itemInfo in ipairs(t) do
			local item = itemInfo.item
			local identifier = item:GetIdentifier()
			local udmItem = udmParent:Add(identifier)
			if item:IsExpanded() then
				udmItem:SetValue("expanded", udm.TYPE_BOOLEAN, true)
			end
			if item:IsSelected() then
				udmItem:SetValue("selected", udm.TYPE_BOOLEAN, true)
			end
			if item:IsExpanded() and #itemInfo.children > 0 then
				local udmChild = udmItem:Add("children")
				write_items(itemInfo.children, udmChild)
			end
		end
	end
	local targetItems = get_items(self.m_tree:GetRoot())
	write_items(targetItems, udmTree)
end
function gui.PFMActorEditor:RestoreUiState(data)
	local udmTree = data:Get("tree")
	if udmTree:IsValid() == false then
		return
	end
	local function read_items(parent, udmParent)
		for name, udmChild in pairs(udmParent:GetChildren()) do
			local child = parent:GetItemByIdentifier(name, false)
			if util.is_valid(child) then
				if udmChild:GetValue("expanded") then
					child:Expand()
					child:Update()
				end
				if udmChild:GetValue("selected") then
					child:Select(false)
				end
				read_items(child, udmChild:Get("children"))
			end
		end
	end
	read_items(self.m_tree:GetRoot(), udmTree)
end
function gui.PFMActorEditor:OnRemove()
	util.remove(self.m_cbCamLinkGameplayCb)
	util.remove(self.m_cameraLinkOutlineElement)
	util.remove(self.m_filmClipCallbacks)
	self:ClearAnimManagerListeners()
end
function gui.PFMActorEditor:CopyAnimationData(actor)
	local panimaAnim = actor:GetPanimaAnimation()
	if panimaAnim == nil then
		return
	end
	local udmEl = udm.create_element()
	local pfmCopy = udmEl:Add("pfm_copy")
	pfmCopy:SetValue("type", udm.TYPE_STRING, "animation")

	local udmData = pfmCopy:Add("data")
	local udmAnimation = udmData:Add("animation")
	panimaAnim:Save(udmAnimation)

	local ent = actor:FindEntity()
	local mdl = util.is_valid(ent) and ent:GetModel() or nil
	if mdl ~= nil then
		local baseValues = {}
		local function addBaseValue(propertyPath, valueType)
			local val = actor:GetMemberValue(propertyPath)
			if val == nil then
				return
			end
			table.insert(baseValues, {
				targetPath = propertyPath,
				value = val,
				valueType = valueType,
			})
		end
		local skel = mdl:GetSkeleton()
		for _, bone in ipairs(skel:GetBones()) do
			local basePath = "ec/animated/bone/" .. bone:GetName() .. "/"
			addBaseValue(basePath .. "position", udm.TYPE_VECTOR3)
			addBaseValue(basePath .. "rotation", udm.TYPE_QUATERNION)
			addBaseValue(basePath .. "scale", udm.TYPE_VECTOR3)
		end

		for _, flexC in ipairs(mdl:GetFlexControllers()) do
			addBaseValue("ec/flex/" .. flexC.name, udm.TYPE_FLOAT)
		end

		local udmBaseValues = udmData:AddArray("baseValues", #baseValues, udm.TYPE_ELEMENT)
		for i, valueData in ipairs(baseValues) do
			local udmBaseValue = udmBaseValues:Get(i - 1)
			udmBaseValue:SetValue("targetPath", udm.TYPE_STRING, valueData.targetPath)
			udmBaseValue:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueData.valueType))
			udmBaseValue:SetValue("value", valueData.valueType, valueData.value)
		end
	end

	util.set_clipboard_string(udmEl:ToAscii(udm.ASCII_SAVE_FLAG_NONE))
end
function gui.PFMActorEditor:PasteAnimationData(actor)
	local res, err = udm.parse(util.get_clipboard_string())
	if res == false then
		console.print_warning("Failed to parse UDM: ", err)
		return
	end
	local data = res:GetAssetData():GetData()
	local pfmCopy = data:Get("pfm_copy")
	local type = pfmCopy:GetValue("type", udm.TYPE_STRING)
	if type ~= "animation" then
		console.print_warning("Incorrect type: " .. tostring(type))
		return
	end
	local udmData = pfmCopy:Get("data")
	local udmAnimation = udmData:Get("animation")

	local anim = panima.Animation.load(udmAnimation)
	if anim == nil then
		console.print_warning("Failed to load animation data!")
		return
	end
	local cmd = pfm.create_command("composition")
	for _, channel in ipairs(anim:GetChannels()) do
		local times = channel:GetTimes()
		local values = channel:GetValues()
		local propertyPath = channel:GetTargetPath():ToUri(false)
		local valueType = channel:GetValueType()
		local res, subCmd = cmd:AddSubCommand("add_editor_channel", actor, propertyPath, valueType)
		if res == pfm.Command.RESULT_SUCCESS then
			subCmd:AddSubCommand("add_animation_channel", actor, propertyPath, valueType)
		end
		cmd:AddSubCommand("set_animation_channel_range_data", actor, propertyPath, times, values, valueType)
	end

	local udmBaseValues = udmData:Get("baseValues")
	local n = udmBaseValues:GetSize()
	for i = 0, n - 1 do
		local udmBaseValue = udmBaseValues:Get(i)
		local targetPath = udmBaseValue:GetValue("targetPath", udm.TYPE_STRING)
		local strValueType = udmBaseValue:GetValue("valueType", udm.TYPE_STRING)
		local valueType = udm.string_to_type(strValueType)
		if valueType ~= nil then
			local value = udmBaseValue:GetValue("value", valueType)
			cmd:AddSubCommand("set_actor_property", actor, targetPath, nil, value, valueType)
		end
	end
	pfm.undoredo.push("init_anim", cmd)()
end
gui.register("WIPFMActorEditor", gui.PFMActorEditor)

pfm.populate_actor_component_context_menu = function(pContext, actor, t, localeId)
	if t == nil then
		local componentMap = {}
		for _, componentId in ipairs(ents.get_registered_component_types()) do
			local info = ents.get_component_info(componentId)
			if bit.band(info.flags, ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR) == 0 and #info.category > 0 then
				local t = componentMap
				for _, name in ipairs(string.split(info.category, "/")) do
					t.children = t.children or {}
					t.children[name] = t.children[name] or {}
					t = t.children[name]
				end

				local name = info.name
				if actor:HasComponent(name) == false then
					table.insert(t, name)
				end
			end
		end
		t = componentMap
	end
	if t.children ~= nil then
		local tChildren = {}
		for name, sub in pairs(t.children) do
			local childLocaleId = name
			if localeId ~= nil then
				childLocaleId = localeId .. "_" .. childLocaleId
			end
			local res, displayName = locale.get_text("c_category_" .. childLocaleId, true)
			if res == false then
				displayName = name
			end

			table.insert(tChildren, {
				name = name,
				displayName = displayName,
				localeId = childLocaleId,
				components = sub,
			})
		end
		table.sort(tChildren, function(a, b)
			return a.displayName < b.displayName
		end)
		local hiddenCategories = {
			["gameplay"] = true,
			["debug"] = true,
			["util"] = true,
			["physics"] = true,
			["ui"] = true,
			["editor"] = true,
			["ai"] = true,
		}
		for _, sub in ipairs(tChildren) do
			if hiddenCategories[sub.name] ~= true then
				local pComponentsItem, pComponentsMenu = pContext:AddSubMenu(sub.displayName)
				pComponentsItem:SetName(sub.name)
				pfm.populate_actor_component_context_menu(pComponentsMenu, actor, sub.components, sub.localeId)
				pComponentsMenu:Update()
			end
		end
	end

	local list = {}
	for i, name in ipairs(t) do
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

	for _, nameInfo in ipairs(list) do
		pContext
			:AddItem(nameInfo[2], function()
				local filmmaker = pfm.get_project_manager()
				local actorEditor = util.is_valid(filmmaker) and filmmaker:GetActorEditor() or nil
				if util.is_valid(actorEditor) == false then
					return
				end
				pfm.undoredo.push("create_component", pfm.create_command("create_component", actor, nameInfo[1]))()
			end)
			:SetName(nameInfo[1])
	end
end

pfm.populate_actor_context_menu = function(pContext, actor, copyPasteSelected, hitMaterial)
	pfm.get_project_manager():CallCallbacks("PopulateActorContextMenu", pContext, actor)

	-- Components
	local entActor = actor:FindEntity()
	if util.is_valid(entActor) then
		--[[for _, name in ipairs(ents.find_installed_custom_components()) do
			newComponentMap[name] = true
		end]]
		local pComponentsItem, pComponentsMenu = pContext:AddSubMenu(locale.get_text("pfm_add_component"))
		pComponentsItem:SetName("add_component")
		pfm.populate_actor_component_context_menu(pComponentsMenu, actor)
		pComponentsMenu:Update()
	end
	--

	local uniqueId = tostring(actor:GetUniqueId())
	pContext
		:AddItem(locale.get_text("pfm_export_animation"), function()
			local entActor = actor:FindEntity()
			if util.is_valid(entActor) == false then
				return
			end
			local filmmaker = pfm.get_project_manager()
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
					pfm.get_project_manager():OpenMaterialEditor(matPath, mdl:GetName())
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
				local filmmaker = pfm.get_project_manager()
				local tab, el = filmmaker:OpenWindow("ik_rig_editor")
				filmmaker:GoToWindow("ik_rig_editor")
				if util.is_valid(el) then
					el:SetReferenceModel(mdl:GetName())
				end
			end)
			:SetName("edit_ik_rig")

		pContext
			:AddItem(locale.get_text("pfm_copy_animation_data"), function()
				local filmmaker = pfm.get_project_manager()
				local actorEditor = filmmaker:GetActorEditor()
				if util.is_valid(actorEditor) == false then
					return
				end
				actorEditor:CopyAnimationData(actor)
			end)
			:SetName("copy_animation_data")
		pContext
			:AddItem(locale.get_text("pfm_paste_animation_data"), function()
				local filmmaker = pfm.get_project_manager()
				local actorEditor = filmmaker:GetActorEditor()
				if util.is_valid(actorEditor) == false then
					return
				end
				actorEditor:PasteAnimationData(actor)
			end)
			:SetName("paste_animation_data")
	end
	local actors
	if copyPasteSelected == nil then
		actors = { actor }
	end
	pContext
		:AddItem(locale.get_text("pfm_copy_actors"), function()
			local filmmaker = pfm.get_project_manager()
			local actorEditor = filmmaker:GetActorEditor()
			if util.is_valid(actorEditor) == false then
				return
			end
			actorEditor:CopyToClipboard(actors)
		end)
		:SetName("copy_actors")
	pContext
		:AddItem(locale.get_text("pfm_paste_actors"), function()
			local filmmaker = pfm.get_project_manager()
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
				local job = pfm.pack_models({ mdl })
				if job ~= false then
					job:Start()
					job:Wait()
				end
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

		local mdlObj = game.get_model(mdl)
		if mdlObj ~= nil then
			local pSeqItem, pSeqMenu = pContext:AddSubMenu(
				locale.get_text("pfm_import_sequence"),
				nil,
				function(pItem, pMenu)
					local animNames = mdlObj:GetAnimationNames()
					table.sort(animNames)
					for _, animName in ipairs(animNames) do
						pMenu:AddItem(animName, function()
							pfm.get_project_manager():ImportSequence(actor, animName)
						end)
					end
					pMenu:Update()
				end
			)
			pSeqItem:SetName("import_sequence")
		end
	end
	pContext
		:AddItem(locale.get_text("pfm_move_work_camera_to_actor"), function()
			local filmmaker = pfm.get_project_manager()
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
			pfm.get_project_manager():TagRenderSceneAsDirty()
		end)
		:SetName("move_work_camera_to_actor")
	pContext
		:AddItem(locale.get_text("pfm_move_actor_to_work_camera"), function()
			local filmmaker = pfm.get_project_manager()
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
			local filmmaker = pfm.get_project_manager()
			local actorEditor = filmmaker:GetActorEditor()
			if util.is_valid(actorEditor) == false then
				return
			end
			actorEditor:ToggleCameraLink(actor)
		end)
		:SetName("toggle_camera_link")
	pContext
		:AddItem("Dissolve Anim", function()
			local cmd = pfm.create_command("composition")
			actor:DissolveSingleValueAnimationChannels(cmd)
			pfm.undoredo.push("dissolve", cmd)()
		end)
		:SetName("dissolve_single_value_channels")
	pContext
		:AddItem(locale.get_text("pfm_retarget"), function()
			local ent = actor:FindEntity()
			if ent == nil then
				return
			end
			local filmmaker = pfm.get_project_manager()
			gui.open_model_dialog(function(dialogResult, mdlName)
				if dialogResult ~= gui.DIALOG_RESULT_OK then
					return
				end
				if util.is_valid(ent) == false then
					return
				end
				local filmmaker = pfm.get_project_manager()
				local actorEditor = filmmaker:GetActorEditor()
				if util.is_valid(actorEditor) == false then
					return
				end
				-- filmmaker:RetargetActor(ent, mdlName)

				local collection = gui.PFMActorEditor.COLLECTION_ACTORS
				local group = actor:GetParent()
				if group ~= nil and group.TypeName == "Group" then
					collection = group:GetName()
				end
				local impostor = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR, {
					name = actor:GetName() .. "_retarget",
					collection = collection,
					updateActorComponents = false,
					modelName = mdlName,
					enableIk = false,
				})
				actorEditor:CreateNewActorComponent(impostor, "impostor", false)
				actorEditor:UpdateActorComponents(impostor)

				local cmd = pfm.create_command("composition")
				cmd:AddSubCommand("add_actor", actorEditor:GetFilmClip(), { impostor })
				local res, subCmd = cmd:AddSubCommand("composition")
				subCmd:AddSubCommand("create_component", actor, "impersonatee")
				subCmd:AddSubCommand("create_component", actor, "retarget_rig")
				subCmd:AddSubCommand("create_component", actor, "retarget_morph")
				subCmd:AddSubCommand(
					"set_actor_property",
					actor,
					"ec/impersonatee/impostorTarget",
					nil,
					ents.UniversalEntityReference(impostor:GetUniqueId()),
					ents.MEMBER_TYPE_ENTITY
				)
				subCmd:Execute()
				pfm.undoredo.push("retarget", cmd)
			end)
		end)
		:SetName("retarget")

	if pfm.get_project_manager():IsDeveloperModeEnabled() then
		pContext:AddItem("Assign entity to x", function()
			_G.x = actor:FindEntity()
		end)
		pContext:AddItem("Assign entity to y", function()
			_G.y = actor:FindEntity()
		end)
		pContext:AddItem("Assign animation to a", function()
			local animManager = tool.get_filmmaker():GetAnimationManager()
			local anim = animManager:FindAnimation(actor)
			_G.a = anim
		end)
	end
	pContext
		:AddItem(locale.get_text("pfm_copy_id"), function()
			util.set_clipboard_string(tostring(actor:GetUniqueId()))
		end)
		:SetName("copy_id")
end
