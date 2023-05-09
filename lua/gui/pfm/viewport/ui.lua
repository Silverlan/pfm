--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMViewport:InitializeViewport(parent)
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
	self:SetCameraMode(gui.PFMViewport.CAMERA_MODE_PLAYBACK)

	gui.mark_as_drag_and_drop_target(self.m_viewport, "ModelCatalog")
end
function gui.PFMViewport:InitializeSettings(parent)
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
		local pm = tool.get_filmmaker()
		if util.is_valid(pm) and pm:CheckBuildKernels() then
			return
		end
		local val = el:GetOptionValue(idx)
		if val == "0" then
			val = nil
			if util.is_valid(self.m_ctrlViewportMode) then
				self.m_ctrlViewportMode:SelectOption("auto")
			end
			if util.is_valid(self.m_ctrlViewportWrapper) then
				self.m_ctrlViewportWrapper:SetVisible(false)
			end
		else
			val = "cycles"
			local pfm = tool.get_filmmaker()
			local renderTab = pfm:GetRenderTab()
			if util.is_valid(renderTab) then
				val = renderTab:GetRenderSettings():GetRenderEngine()
			end
			if util.is_valid(self.m_ctrlViewportWrapper) then
				self.m_ctrlViewportWrapper:SetVisible(true)
			end
		end
		self:SetRtViewportRenderer(val)
	end)

	local options = {
		{ "auto", "Auto" },
		{ "realtime", "Realtime" },
		{ "render", "Render" },
	}
	local ctrlViewportMode, wrapper
	ctrlViewportMode, wrapper =
		p:AddDropDownMenu(locale.get_text("pfm_viewport_mode"), "viewport_mode", options, "auto")
	self.m_ctrlViewportMode = ctrlViewportMode
	self.m_ctrlViewportWrapper = wrapper
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
			tool.get_filmmaker():SetOverlaySceneEnabled(false)
		else
			self.m_rtViewport:SetZPos(10)
			tool.get_filmmaker():SetOverlaySceneEnabled(true)
		end
	end)
	self.m_ctrlViewportWrapper:SetVisible(false)

	self.m_ctrlVr = p:AddDropDownMenu(locale.get_text("pfm_viewport_vr_enabled"), "vr_enabled", {
		{ "0", locale.get_text("disabled") },
		{ "1", locale.get_text("enabled") },
	}, 0)
	self.m_ctrlVr:AddCallback("OnOptionSelected", function(el, idx)
		local enabled = (idx == 1)
		ents.PFMCamera.set_vr_view_enabled(enabled)
		if ents.PFMCamera.is_vr_view_enabled() then
			for i = 0, openvr.MAX_TRACKED_DEVICE_COUNT - 1 do
				if openvr.get_tracked_device_class(i) == openvr.TRACKED_DEVICE_CLASS_CONTROLLER then
					local ent = ents.create("pfm_vr_controller")
					ent:Spawn()

					table.insert(self.m_vrControllers, ent)

					local vrC = ent:GetComponent(ents.COMPONENT_VR_CONTROLLER)
					if vrC ~= nil then
						vrC:SetControllerId(i)
					end

					local pfmVrC = ent:GetComponent(ents.COMPONENT_PFM_VR_CONTROLLER)
					if pfmVrC ~= nil then
						-- TODO: This is just a prototype implementation, do this properly!
						local el = pfmVrC:GetGUIElement():GetPlayButton()
						if util.is_valid(el) then
							el:AddCallback("OnStateChanged", function(el, oldState, state)
								local btPlay = self:GetPlayButton()
								if util.is_valid(btPlay) == false then
									return
								end
								if state == gui.PFMPlayButton.STATE_PLAYING then
									btPlay:Pause()
								elseif state == gui.PFMPlayButton.STATE_PAUSED then
									btPlay:Play()
								end
							end)
						end
					end
				end
			end
		else
			for _, ent in ipairs(self.m_vrControllers) do
				if ent:IsValid() then
					ent:Remove()
				end
			end
			self.m_vrControllers = {}
		end
	end)

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
		tool.get_filmmaker():TagRenderSceneAsDirty()
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
		tool.get_filmmaker():GetSelectionManager():SetShowBones(enabled)
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
		tool.get_filmmaker():GetSelectionManager():SetSelectionWireframeEnabled(enabled)
		pfm.tag_render_scene_as_dirty()
	end)

	self.m_ctrlShowAxes = p:AddDropDownMenu(locale.get_text("pfm_show_axes"), "show_axes", {
		{ "0", locale.get_text("no") },
		{ "1", locale.get_text("yes") },
	}, 1)
	self.m_ctrlShowAxes:AddCallback("OnOptionSelected", function(el, idx)
		local enabled = toboolean(self.m_ctrlShowAxes:GetOptionValue(self.m_ctrlShowAxes:GetSelectedOption()))
		local ent = tool.get_filmmaker():GetWorldAxesGizmo()
		if util.is_valid(ent) then
			ent:SetEnabled(enabled)
		end
		pfm.tag_render_scene_as_dirty()
	end)
end
function gui.PFMViewport:InitializeControls()
	gui.PFMBaseViewport.InitializeControls(self)

	local controls = gui.create("WIBase", self.m_vpContents)
	controls:SetSize(64, 64)
	self.m_controls = controls

	self.m_playControls = gui.create("PlaybackControls", controls)
	self.m_playControls:SetName("playback_controls")
	self.m_playControls:CenterToParentX()
	self.m_playControls:SetAnchor(0.5, 0, 0.5, 0)
	self.m_playControls:LinkToPFMProject(tool.get_filmmaker())
	self.m_btPlay = self.m_playControls:GetPlayButton()
	controls:SizeToContents()
	self:InitializeManipulatorControls()
	self:InitializeCameraControls()

	self.m_settingsBox:ResetControls()
end
