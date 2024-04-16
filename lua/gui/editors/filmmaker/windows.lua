--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local g_registeredWindows = {}
pfm.get_registered_windows = function()
	return g_registeredWindows
end
pfm.register_window = function(name, category, localizedName, factory)
	table.insert(g_registeredWindows, {
		name = name,
		category = category,
		localizedName = localizedName,
		factory = function(...)
			local el = factory(...)
			if util.is_valid(el) then
				el:SetName("window_" .. name)
			end
			return el
		end,
	})
	pfm["WINDOW_" .. name:upper()] = name
	pfm["WINDOW_" .. name:upper() .. "_UI_ID"] = "window_" .. name
end

pfm.register_window("actor_editor", "editors", locale.get_text("pfm_actor_editor"), function(pm)
	local actorEditor = gui.create("WIPFMActorEditor")
	actorEditor:AddCallback("OnControlSelected", function(actorEditor, actor, component, controlData, slider)
		pm:OnActorControlSelected(actorEditor, actor, component, controlData, slider)
	end)
	actorEditor:AddCallback("OnPropertySelected", function(actorEditor, udmComponent, item, path, selected)
		pm:CallCallbacks("OnActorPropertySelected", udmComponent, item, path, selected)
	end)
	return actorEditor
end)
pfm.register_window("bone_retargeting", "editors", locale.get_text("pfm_bone_retargeting"), function(pm)
	local p = gui.create("WIBoneRetargeting")
	pm:OpenModelView()
	p:SetModelView(pm.m_mdlView)
	return p
end)
pfm.register_window("ik_rig_editor", "editors", locale.get_text("pfm_ik_rig_editor"), function(pm)
	local p = gui.create("WIIkRigEditor")
	pm:OpenModelView()
	p:SetModelView(pm.m_mdlView)
	return p
end)
pfm.register_window("model_viewer", "viewers", locale.get_text("pfm_model_viewer"), function(pm)
	local playerBox = gui.create("WIVBox")
	playerBox:SetAutoFillContents(true)

	local vrBox = gui.create("WIBase", playerBox)
	vrBox:SetSize(128, 128)
	local aspectRatioWrapper = gui.create("WIAspectRatio", vrBox)
	aspectRatioWrapper:AddCallback("OnAspectRatioChanged", function(el, aspectRatio)
		if util.is_valid(pm.m_viewport) then
			local scene = pm.m_viewport:GetScene()
			if scene ~= nil then
				local cam = scene:GetActiveCamera()
				if cam ~= nil then
					cam:SetAspectRatio(aspectRatio)
					cam:UpdateMatrices()
				end
			end
		end
	end)
	local vpWrapper = gui.create("WIBase", aspectRatioWrapper)
	vpWrapper:SetSize(10, 10)

	local width = pm:GetWidth()
	local height = pm:GetHeight()
	local modelView =
		gui.create("WIModelView", vpWrapper, 0, 0, vpWrapper:GetWidth(), vpWrapper:GetHeight(), 0, 0, 1, 1)
	modelView:SetClearColor(Color(5, 5, 5, 255))
	modelView:InitializeViewport(width, height)
	modelView:SetFov(math.horizontal_fov_to_vertical_fov(45.0, width, height))
	modelView:RequestFocus()

	aspectRatioWrapper:SetWidth(vrBox:GetWidth())
	aspectRatioWrapper:SetHeight(vrBox:GetHeight())
	aspectRatioWrapper:SetAnchor(0, 0, 1, 1)

	pm.m_mdlView = modelView
	local pRetarget = pm:GetWindow("bone_retargeting")
	if util.is_valid(pRetarget) then
		pRetarget:SetModelView(modelView)
	end
	return playerBox
end)
pfm.register_window("model_catalog", "catalogs", locale.get_text("pfm_model_catalog"), function(pm)
	local mdlCatalog = gui.create("WIPFMModelCatalog")
	local explorer = mdlCatalog:GetExplorer()
	explorer:AddCallback("PopulateIconContextMenu", function(explorer, pContext, tSelectedFiles, tExternalFiles)
		local hasExternalFiles = (#tExternalFiles > 0)
		if hasExternalFiles == true then
			return
		end
		if #tSelectedFiles == 1 then
			local path = tSelectedFiles[1]:GetRelativeAsset()
			local pItem = pContext:AddItem(locale.get_text("pfm_show_in_model_viewer"), function()
				local pDialog, frame, el = gui.open_model_dialog()
				el:SetModel(path)
			end)
			pItem:SetName("show_in_model_viewer")
			pItem:SetTooltip(locale.get_text("pfm_model_context_model_viewer"))

			local filePath = asset.find_file(path, asset.TYPE_MODEL)
			if filePath ~= nil then
				filePath = asset.get_asset_root_directory(asset.TYPE_MODEL) .. "/" .. filePath
				local pItem = pContext:AddItem(locale.get_text("pfm_edit_udm_data"), function()
					local filmmaker = tool.get_filmmaker()
					filmmaker:OpenFileInUdmEditor(filePath)
				end)
				pItem:SetName("edit_udm_data")
			end

			if asset.is_loaded(path, asset.TYPE_MODEL) == false then
				local pItem = pContext:AddItem(locale.get_text("pfm_load"), function()
					game.load_model(path)
				end)
				pItem:SetName("load")
				pItem:SetTooltip(locale.get_text("pfm_model_context_load"))
			else
				local mdl = game.load_model(path)
				local materials = mdl:GetMaterials()
				if #materials > 0 then
					local pItem, pSubMenu = pContext:AddSubMenu(locale.get_text("pfm_edit_material"))
					for _, mat in pairs(materials) do
						if mat ~= nil and mat:IsError() == false then
							local name = file.remove_file_extension(file.get_file_name(mat:GetName()))
							pSubMenu:AddItem(name, function(pItem)
								tool.get_filmmaker():OpenMaterialEditor(mat:GetName(), path)
							end)
						end
					end
					pItem:SetTooltip(locale.get_text("pfm_model_context_edit_material"))
					pSubMenu:Update()
				end

				local mdl = game.load_model(path)
				local name = (mdl:GetName() ~= nil) and mdl:GetName() or ""
				if #name > 0 then
					local filePath = asset.find_file(name, asset.TYPE_MODEL)
					if filePath ~= nil then
						filePath = asset.get_asset_root_directory(asset.TYPE_MODEL) .. "/" .. filePath
						local formatType, err = udm.get_format_type(filePath)
						if formatType ~= false then
							if formatType == udm.FORMAT_TYPE_BINARY then
								local pItem = pContext:AddItem(
									locale.get_text("pfm_convert_to_ascii_format"),
									function()
										local newFileName, err = udm.convert_udm_file_to_ascii(filePath)
										if newFileName == false then
											console.print_warning("Failed to convert asset to ASCII format: " .. err)
										else
											util.open_path_in_explorer(
												file.get_file_path(newFileName),
												file.get_file_name(newFileName)
											)
										end
									end
								)
								pItem:SetName("convert_to_ascii")
								pItem:SetTooltip(locale.get_text("pfm_model_context_convert_to_ascii"))
							else
								local pItem = pContext:AddItem(
									locale.get_text("pfm_convert_to_binary_format"),
									function()
										local newFileName, err = udm.convert_udm_file_to_binary(filePath)
										if newFileName == false then
											console.print_warning("Failed to convert asset to binary format: " .. err)
										else
											util.open_path_in_explorer(
												file.get_file_path(newFileName),
												file.get_file_name(newFileName)
											)
										end
									end
								)
								pItem:SetName("convert_to_binary")
								pItem:SetTooltip(locale.get_text("pfm_model_context_convert_to_binary"))
							end
						end
					end
				end
			end
		end

		if #tSelectedFiles > 0 then
			local pItem = pContext:AddItem(locale.get_text("pfm_pack_model"), function()
				local mdls = {}
				for _, f in ipairs(tSelectedFiles) do
					table.insert(mdls, f:GetRelativeAsset())
				end
				local job = pfm.pack_models(mdls)
				if job ~= false then
					job:Start()
					job:Wait()
				end
			end)
			pItem:SetName("pack_model")
			pItem:SetTooltip(locale.get_text("pfm_model_context_pack_model"))
		end
	end)
	explorer:AddCallback("OnIconAdded", function(explorer, icon)
		if icon:IsDirectory() == false then
			local entGhost
			gui.enable_drag_and_drop(icon, "ModelCatalog", function(elGhost)
				elGhost:SetAlpha(128)
				elGhost:AddCallback("OnDragTargetHoverStart", function(elGhost, elTgt)
					elGhost:SetAlpha(0)
					elGhost:SetAlwaysUpdate(true)

					if util.is_valid(entGhost) then
						entGhost:Remove()
					end
					local path = util.Path(icon:GetAsset())
					path:PopFront()
					local mdlPath = path:GetString()
					if icon:IsValid() and asset.exists(mdlPath, asset.TYPE_MODEL) == false then
						explorer:ImportAsset(icon)
					end -- Import the asset and generate the icon
					entGhost = ents.create("pfm_ghost")

					local ghostC = entGhost:GetComponent(ents.COMPONENT_PFM_GHOST)
					if string.compare(elTgt:GetClass(), "WIViewport", false) and ghostC ~= nil then
						ghostC:SetViewport(elTgt)
					end

					entGhost:Spawn()
					entGhost:SetModel(path:GetString())

					local mdl = entGhost:GetModel()
					local metaRig = (mdl ~= nil) and mdl:GetMetaRig() or nil
					if metaRig ~= nil then
						ghostC:SetBaseRotation(metaRig.forwardFacingRotationOffset)
					end

					pm:TagRenderSceneAsDirty(true)
				end)
				elGhost:AddCallback("OnDragTargetHoverStop", function(elGhost)
					elGhost:SetAlpha(128)
					elGhost:SetAlwaysUpdate(false)
					util.remove(entGhost)
					pm:TagRenderSceneAsDirty()
				end)
			end)
			icon:AddCallback("OnDragDropped", function(elIcon, elDrop)
				if util.is_valid(entGhost) == false then
					return
				end
				local filmClip = pm:GetActiveFilmClip()
				if filmClip == nil then
					return
				end
				local filmmaker = tool.get_filmmaker()
				local actorEditor = pm:GetActorEditor()

				local path = util.Path(elIcon:GetAsset())
				path:PopFront()
				local mdl = game.load_model(path:GetString())
				if mdl == nil then
					return
				end
				local name = util.Path
					.CreateFilePath(asset.get_normalized_path(path:GetString(), asset.TYPE_MODEL))
					:GetFileName()
				if #name == 0 then
					name = nil
				end

				local actor
				if pfm.is_articulated_model(mdl) then
					actor = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_ARTICULATED_ACTOR, {
						["modelName"] = path:GetString(),
						["name"] = name,
					})
				else
					actor = actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP, {
						["modelName"] = path:GetString(),
						["name"] = name,
					})
				end
				pm:UpdateActor(actor, filmClip)

				-- filmmaker:ReloadGameView() -- TODO: No need to reload the entire game view

				local entActor = actor:FindEntity()
				if util.is_valid(entActor) then
					local actorC = entActor:AddComponent("pfm_actor")
					if actorC ~= nil then
						pm:SetActorTransformProperty(actorC, "position", entGhost:GetPos(), true)
						pm:SetActorTransformProperty(actorC, "rotation", entGhost:GetRotation(), true)
					end

					local ghostC = entGhost:GetComponent(ents.COMPONENT_PFM_GHOST)
					local srcBone, attachmentActor, attachmentBone = ghostC:GetAttachmentTarget()
					if srcBone ~= nil then
						actorEditor:AddConstraint(
							gui.PFMActorEditor.ACTOR_PRESET_TYPE_CONSTRAINT_CHILD_OF,
							actor,
							"ec/pfm_actor/pose",
							attachmentActor,
							"ec/animated/bone/" .. attachmentBone .. "/pose"
						)
					else
						local tc = entActor:AddComponent("util_transform")
						if tc ~= nil then
							entActor:AddComponent("pfm_transform_gizmo")
							tc:SetTranslationEnabled(false)
							tc:SetRotationAxisEnabled(math.AXIS_X, false)
							tc:SetRotationAxisEnabled(math.AXIS_Z, false)
							tc:UpdateAxes()
							local trUtil =
								tc:GetTransformUtility(ents.TransformController.TYPE_ROTATION, math.AXIS_Y, "rotation")
							local arrowC = util.is_valid(trUtil)
									and trUtil:GetComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW)
								or nil
							if arrowC ~= nil then
								arrowC:StartTransform()
								local cb
								cb = input.add_callback("OnMouseInput", function(mouseButton, state, mods)
									if mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
										if util.is_valid(entActor) then
											entActor:RemoveComponent("util_transform")

											if actorC:IsValid() then
												pm:SetActorTransformProperty(
													actorC,
													"position",
													entActor:GetPos(),
													true
												)
												pm:SetActorTransformProperty(
													actorC,
													"rotation",
													entActor:GetRotation(),
													true
												)
												pm:SelectActor(actorC:GetActorData(), true, nil, false)
											end
										end
										cb:Remove()
										return util.EVENT_REPLY_HANDLED
									end
								end)
							end
						end
					end
				end
			end)
		end
	end)
	explorer:AddCallback("PopulateIconContextMenu", function(explorer, pContext, tSelectedFiles, tExternalFiles)
		if #tSelectedFiles ~= 1 then
			return
		end
		local path = tSelectedFiles[1]:GetRelativeAsset()
		if asset.exists(path, asset.TYPE_MODEL) == false then
			return
		end
		local pItem = pContext:AddItem(locale.get_text("pfm_edit_retarget_rig"), function()
			gui.open_model_dialog(function(result, mdlName)
				if result ~= gui.DIALOG_RESULT_OK then
					return
				end
				pm:OpenBoneRetargetWindow(path, mdlName)
			end)
		end)
		pItem:SetName("edit_retarget_rig")
		pItem:SetTooltip(locale.get_text("pfm_model_context_retarget_rig"))
	end)
	return mdlCatalog
end)
pfm.register_window("material_catalog", "catalogs", locale.get_text("pfm_material_catalog"), function(pm)
	local el = gui.create("WIPFMMaterialCatalog")
	return el
end)
pfm.register_window("particle_catalog", "catalogs", locale.get_text("pfm_particle_catalog"), function(pm)
	local el = gui.create("WIPFMParticleCatalog")
	return el
end)
pfm.register_window("tutorial_catalog", "catalogs", locale.get_text("pfm_tutorial_catalog"), function(pm)
	local el = gui.create("WIPFMTutorialCatalog")
	return el
end)
--[[pfm.register_window("actor_catalog", "catalogs", locale.get_text("pfm_actor_catalog"), function(pm)
	local el = gui.create("WIPFMActorCatalog")
	return el
end)]]
pfm.register_window("element_viewer", "editors", locale.get_text("pfm_element_viewer"), function(pm)
	local el = gui.create("WIPFMElementViewer")
	return el
end)
pfm.register_window("material_editor", "editors", locale.get_text("pfm_material_editor"), function(pm)
	local el = gui.create("WIPFMMaterialEditor")
	return el
end)
pfm.register_window("particle_editor", "editors", locale.get_text("pfm_particle_editor"), function(pm)
	local el = gui.create("WIPFMParticleEditor")
	return el
end)
pfm.register_window("web_browser", "editors", locale.get_text("pfm_web_browser"), function(pm)
	local el = gui.create("WIPFMWebBrowser")
	el:AddCallback("OnDetached", function(el, window)
		window:Maximize()
	end)
	return el
end)
pfm.register_window("code_editor", "editors", locale.get_text("pfm_code_editor"), function(pm)
	local el = gui.create("WIPFMCodeEditor")
	el:AddCallback("OnDetached", function(el, window)
		window:Maximize()
	end)
	return el
end)
pfm.register_window("console", "editors", locale.get_text("console"), function(pm)
	local elConsole = gui.get_console()
	if util.is_valid(elConsole) == false then
		return
	end
	elConsole:SetExternallyOwned(true)
	local el = gui.create("WIBase")
	el:SetSize(512, 512)
	el:AddCallback("OnDetached", function(el, window)
		window:Maximize()
	end)
	el:AddCallback("OnReattached", function(el, window)
		if elConsole:IsValid() then
			elConsole:SetExternallyOwned(false)
		end
	end)
	elConsole:SetParent(el)
	elConsole:SetSize(el:GetSize())
	elConsole:SetAnchor(0, 0, 1, 1)
	return el
end)
pfm.register_window("settings", "editors", locale.get_text("pfm_settings"), function(pm)
	local el = gui.create("WIPFMSettings")
	return el
end)

pfm.register_window("primary_viewport", "viewers", locale.get_text("pfm_primary_viewport"), function(pm)
	local el = gui.create("WIPFMViewport")
	el:AddCallback("OnReattached", function(el, window)
		pm:RequestFocus()
	end)
	el:AddCallback("OnManipulatorModeChanged", function(el, manipMode)
		pm:CallCallbacks("OnManipulatorModeChanged", manipMode)
	end)
	return el
end)
pfm.register_window("secondary_viewport", "viewers", locale.get_text("pfm_secondary_viewport"), function(pm)
	local el = gui.create("WIPFMViewport")
	el:AddCallback("OnReattached", function(el, window)
		pm:RequestFocus()
	end)
	el:InitializeCustomScene()
	return el
end)
pfm.register_window("tertiary_viewport", "viewers", locale.get_text("pfm_tertiary_viewport"), function(pm)
	local el = gui.create("WIPFMViewport")
	el:AddCallback("OnReattached", function(el, window)
		pm:RequestFocus()
	end)
	el:InitializeCustomScene()
	return el
end)
pfm.register_window("render", "viewers", locale.get_text("pfm_render"), function(pm)
	local el = gui.create("WIPFMRenderPreview")
	el:GetVisibilityProperty():AddCallback(function(wasVisible, isVisible)
		if pm.m_renderWasSceneCameraEnabled == nil then
			pm.m_renderWasSceneCameraEnabled = ents.PFMCamera.is_camera_enabled()
		end
		if isVisible then
			ents.PFMCamera.set_camera_enabled(false) -- Switch to game camera for VR renders
		else
			ents.PFMCamera.set_camera_enabled(pm.m_renderWasSceneCameraEnabled)
			pm.m_renderWasSceneCameraEnabled = nil
		end
	end)
	el:AddCallback("InitializeRender", function(el, rtJob, settings, preview)
		rtJob:AddCallback("PrepareFrame", function()
			if pm.m_renderWasSceneCameraEnabled == nil then
				pm.m_renderWasSceneCameraEnabled = ents.PFMCamera.is_camera_enabled()
			end
			ents.PFMCamera.set_camera_enabled(pm.m_renderWasSceneCameraEnabled)
		end)
		rtJob:AddCallback("OnFrameStart", function()
			ents.PFMCamera.set_camera_enabled(false) -- Switch back to game cam for 360 preview
		end)
	end)
	return el
end)
--[[pfm.register_window("post_processing", "viewers", locale.get_text("pfm_post_processing"), function(pm)
	return gui.create("WIPFMPostProcessing")
end)
pfm.register_window("video_player", "viewers", locale.get_text("pfm_video_player"), function(pm)
	return gui.create("WIPFMVideoPlayer")
end)]]

pfm.register_window("timeline", "timeline", locale.get_text("pfm_timeline"), function(pm)
	local pfmTimeline = gui.create("WIPFMTimeline")
	pm.m_timeline = pfmTimeline

	local userInteractionTimeStart
	pfmTimeline:AddCallback("OnUserInputStarted", function()
		userInteractionTimeStart = pm:GetTimeOffset()
	end)
	pfmTimeline:AddCallback("OnUserInputEnded", function()
		if userInteractionTimeStart == nil then
			return
		end
		local tOld = userInteractionTimeStart
		local tNew = pm:GetTimeOffset()
		pfm.undoredo.push("time_offset", pfm.create_command("set_time_offset", tNew, tOld))
		userInteractionTimeStart = nil
	end)
	pm:UpdateBookmarks()

	return pfmTimeline
end)
