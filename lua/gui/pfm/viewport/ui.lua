-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function gui.PFMCoreViewportBase:InitializeViewport(parent)
	gui.PFMBaseViewport.InitializeViewport(self, parent)
	local vpContainer = gui.create("WIBase", parent)
	self.m_vpContainer = vpContainer

	self.m_viewport =
		gui.create("WIViewport", vpContainer, 0, 0, vpContainer:GetWidth(), vpContainer:GetHeight(), 0, 0, 1, 1)
	self.m_viewport:SetMovementControlsEnabled(false)
	self.m_viewport:SetName("viewport")

	self.m_viewport:SetType(gui.WIViewport.VIEWPORT_TYPE_3D)

	-- This controls the behavior that allows controlling the camera while holding the right mouse button down
	self.m_viewport:SetMouseInputEnabled(true)
	self.m_cbClickMouseInput = self.m_viewport:AddCallback("OnMouseEvent", function(el, mouseButton, state, mods)
		return self:OnViewportMouseEvent(el, mouseButton, state, mods)
	end)
	self:SetCameraMode(gui.PFMCoreViewportBase.CAMERA_MODE_PLAYBACK)

	gui.mark_as_drag_and_drop_target(self.m_viewport, "ModelCatalog")
end
function gui.PFMCoreViewportBase:InitializeSettings(parent)
	gui.PFMBaseViewport.InitializeSettings(self, parent)
	local p = self.m_settingsBox
	p:SetName("vp_settings")

	--[[local ctrlRt,wrapper = p:AddDropDownMenu(locale.get_text("pfm_viewport_rt_enabled"),"rt_enabled",{
		{"disabled",locale.get_text("disabled")},
		{"cycles",locale.get_text("pfm_render_engine_cycles")},
		{"luxcorerender",locale.get_text("pfm_render_engine_luxcorerender")}
	},0)]]
	-- Live raytracing
	local ctrlRt = p:AddDropDownMenu(locale.get_text("pfm_viewport_rt_enabled"), "rt_enabled", {
		{ "0", locale.get_text("disabled") },
		{ "1", locale.get_text("enabled") },
	}, 0)
	self.m_ctrlRt = ctrlRt
	-- wrapper:SetUseAltMode(true)
	self.m_ctrlRt:AddCallback("OnOptionSelected", function(el, idx)
		local pm = pfm.get_project_manager()
		if util.is_valid(pm) and pm:CheckBuildKernels() then
			return
		end
		local val = el:GetOptionValue(idx)
		if val == "0" then
			val = nil
			if util.is_valid(self.m_ctrlViewportMode) then
				self.m_ctrlViewportMode:SelectOption("auto")
			end
			if util.is_valid(self.m_ctrlViewportContainer) then
				self.m_ctrlViewportContainer:SetVisible(false)
			end
			self.m_refreshRtView:SetVisible(false)
		else
			val = "cycles"
			local pfm = pfm.get_project_manager()
			local renderTab = pfm:GetRenderTab()
			if util.is_valid(renderTab) then
				val = renderTab:GetRenderSettings():GetRenderEngine()
			end
			if util.is_valid(self.m_ctrlViewportContainer) then
				self.m_ctrlViewportContainer:SetVisible(true)
			end
			self.m_refreshRtView:SetVisible(true)
		end
		self:SetRtViewportRenderer(val)
	end)

	local options = {
		{ "auto", "Auto" },
		{ "realtime", "Realtime" },
		{ "render", "Render" },
	}
	local ctrlViewportMode, wrapper, container
	ctrlViewportMode, wrapper, container =
		p:AddDropDownMenu(locale.get_text("pfm_viewport_mode"), "viewport_mode", options, "auto")
	self.m_ctrlViewportMode = ctrlViewportMode
	self.m_ctrlViewportContainer = container
	self.m_ctrlViewportMode:AddCallback("OnOptionSelected", function(el, idx)
		local vpMode = self.m_ctrlViewportMode:GetOptionValue(self.m_ctrlViewportMode:GetSelectedOption())
		if util.is_valid(self.m_rtViewport) == false then
			if vpMode ~= "auto" then
				self.m_ctrlViewportMode:SelectOption("auto")
			end
			return
		end
		if vpMode == "auto" then
			if util.is_valid(self.m_rtViewport) then
				vpMode = "render"
			else
				vpMode = "realtime"
			end
		end

		if vpMode == "realtime" then
			self.m_rtViewport:SetZPos(-10)
			pfm.get_project_manager():SetOverlaySceneEnabled(false)
		else
			self.m_rtViewport:SetZPos(10)
			pfm.get_project_manager():SetOverlaySceneEnabled(true)
		end
	end)
	self.m_ctrlViewportContainer:SetVisible(false)

	self.m_ctrlToneMapping = p:AddDropDownMenu(locale.get_text("pfm_viewport_tonemapping"), "tonemapping", {
		{ "gamma_correction", locale.get_text("gamma_correction") },
		{ "reinhard", "Reinhard" },
		{ "hejil_richard", "Hejil-Richard" },
		{ "uncharted", "Uncharted" },
		{ "aces", "Aces" },
		{ "gran_turismo", "Gran Turismo" },
	}, "uncharted")
	self.m_ctrlToneMapping:AddCallback("OnOptionSelected", function(el, idx)
		console.run("cl_render_tone_mapping " .. tostring(idx))
		pfm.tag_render_scene_as_dirty()
	end)

	self.m_ctrlTransformSpace = p:AddDropDownMenu(locale.get_text("pfm_transform_space"), "transform_space", {
		{ "global", locale.get_text("pfm_transform_space_global") },
		{ "local", locale.get_text("pfm_transform_space_local") },
		{ "view", locale.get_text("pfm_transform_space_view") },
	}, "global")
	self.m_ctrlTransformSpace:AddCallback("OnOptionSelected", function(el, idx)
		self:ReloadManipulatorMode()
	end)

	self.m_ctrlTransformKeyframes =
		p:AddDropDownMenu(locale.get_text("pfm_transform_keyframes"), "transform_keyframes", {
			{ "0", locale.get_text("no") },
			{ "1", locale.get_text("yes") },
		}, 0)

	local gridSteps = { 0, 1, 2, 4, 8, 16, 32, 64, 128 }
	options = {}
	for _, v in ipairs(gridSteps) do
		table.insert(options, { tostring(v), tostring(v) })
	end
	self.m_ctrlSnapToGridSpacing =
		p:AddDropDownMenu(locale.get_text("pfm_transform_snap_to_grid_spacing"), "snap_to_grid_spacing", options, "0")
	self.m_ctrlSnapToGridSpacing:AddCallback("OnOptionSelected", function(el, idx)
		local spacing =
			toint(self.m_ctrlSnapToGridSpacing:GetOptionValue(self.m_ctrlSnapToGridSpacing:GetSelectedOption()))
		self:SetSnapToGridSpacing(spacing)
	end)

	local angSteps = { 0, 1, 2, 5, 10, 15, 45, 90 }
	options = {}
	for _, v in ipairs(angSteps) do
		table.insert(options, { tostring(v), tostring(v) })
	end
	self.m_ctrlAngularSpacing =
		p:AddDropDownMenu(locale.get_text("pfm_transform_angular_spacing"), "angular_spacing", options, "0")
	self.m_ctrlAngularSpacing:AddCallback("OnOptionSelected", function(el, idx)
		local spacing = toint(self.m_ctrlAngularSpacing:GetOptionValue(self.m_ctrlAngularSpacing:GetSelectedOption()))
		self:SetAngularSpacing(spacing)
	end)

	-- if(tool.is_developer_mode_enabled()) then
	options = {
		{ "0", "None" },
		{ "14", "Unlit" },
		{ "2", "Albedo" },
		{ "3", "Metalness" },
		{ "4", "Roughness" },
		{ "11", "Emission" },
		{ "6", "Normals" },
		{ "1", "Ambient Occlusion" },
		{ "5", "Diffuse Lighting" },
		{ "8", "Reflectance" },
		{ "18", "Specular" },
		{ "12", "Lightmaps" },
		{ "19", "Indirect Lightmap" },
		{ "20", "Dominant Lightmap" },
		{ "7", "Normal Maps" },
		{ "9", "IBL Prefilter" },
		{ "10", "IBL Irradiance" },
		{ "13", "Lightmap Uvs" },
		{ "15", "CSM Cascades" },
		{ "16", "Shadow Map Depth" },
		{ "17", "Forward+ Heatmap" },
	}
	self.m_ctrlDebugMode = p:AddDropDownMenu(locale.get_text("pfm_debug_mode"), "debug_mode", options, "0")
	self.m_ctrlDebugMode:AddCallback("OnOptionSelected", function(el, idx)
		local mode = toint(self.m_ctrlDebugMode:GetOptionValue(self.m_ctrlDebugMode:GetSelectedOption()))
		console.run("render_debug_mode", mode)
		pfm.tag_render_scene_as_dirty()
	end)
	-- end

	self.m_ctrlShowBones = p:AddDropDownMenu(locale.get_text("pfm_show_bones"), "show_bones", {
		{ "0", locale.get_text("no") },
		{ "1", locale.get_text("yes") },
	}, 1)
	self.m_ctrlShowBones:AddCallback("OnOptionSelected", function(el, idx)
		local enabled = toboolean(self.m_ctrlShowBones:GetOptionValue(self.m_ctrlShowBones:GetSelectedOption()))
		pfm.get_project_manager():GetSelectionManager():SetShowBones(enabled)
		pfm.tag_render_scene_as_dirty()
	end)

	self.m_ctrlShowSelectionWireframe =
		p:AddDropDownMenu(locale.get_text("pfm_show_selection_wireframe"), "show_selection_wireframe", {
			{ "0", locale.get_text("no") },
			{ "1", locale.get_text("yes") },
		}, 1)
	self.m_ctrlShowSelectionWireframe:AddCallback("OnOptionSelected", function(el, idx)
		local enabled = toboolean(
			self.m_ctrlShowSelectionWireframe:GetOptionValue(self.m_ctrlShowSelectionWireframe:GetSelectedOption())
		)
		pfm.get_project_manager():GetSelectionManager():SetSelectionWireframeEnabled(enabled)
		pfm.tag_render_scene_as_dirty()
	end)

	self.m_ctrlShowAxes = p:AddDropDownMenu(locale.get_text("pfm_show_axes"), "show_axes", {
		{ "0", locale.get_text("no") },
		{ "1", locale.get_text("yes") },
	}, 1)
	self.m_ctrlShowAxes:AddCallback("OnOptionSelected", function(el, idx)
		local enabled = toboolean(self.m_ctrlShowAxes:GetOptionValue(self.m_ctrlShowAxes:GetSelectedOption()))
		local ent = pfm.get_project_manager():GetWorldAxesGizmo()
		if util.is_valid(ent) then
			ent:SetEnabled(enabled)
		end
		pfm.tag_render_scene_as_dirty()
	end)

	self.m_refreshRtView = p:AddButton(locale.get_text("pfm_refresh_rt_view"), "refresh_rt_view", function()
		self.m_ctrlRt:SelectOption(0)
		self.m_ctrlRt:SelectOption(1)
	end)
	self.m_refreshRtView:SetHeight(26)
	self.m_refreshRtView:SetVisible(false)

	pfm.call_event_listeners("PopulateViewportSettings", self, p)
end
function gui.PFMCoreViewportBase:SetManipulatorControlsEnabled(enabled)
	self.m_manipulatorControlsEnabled = enabled
end
function gui.PFMCoreViewportBase:SetCameraControlsEnabled(enabled)
	self.m_cameraControlsEnabled = enabled
end
function gui.PFMCoreViewportBase:InitializeControls()
	gui.PFMBaseViewport.InitializeControls(self)

	local controls = gui.create("WIBase", self.m_vpContents)
	controls:SetSize(64, 64)
	self.m_controls = controls

	self.m_playControls = gui.create("PlaybackControls", controls)
	self.m_playControls:SetName("playback_controls")
	self.m_playControls:CenterToParentX()
	self.m_playControls:SetAnchor(0.5, 0, 0.5, 0)
	self.m_playControls:LinkToPFMProject(pfm.get_project_manager())
	self.m_btPlay = self.m_playControls:GetPlayButton()

	controls:SizeToContents()
	if self.m_manipulatorControlsEnabled ~= false then
		self:InitializeManipulatorControls()
	end
	if self.m_cameraControlsEnabled ~= false then
		self:InitializeCameraControls()
	end

	if util.is_valid(self.m_settingsBox) then
		self.m_settingsBox:ResetControls()
	end
end
