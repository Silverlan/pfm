--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:ExportAnimation(actor)
	if self.m_animRecorder ~= nil then
		self.m_animRecorder:Clear()
		self.m_animRecorder = nil
	end
	local activeFilmClip = self:GetActiveFilmClip()
	if activeFilmClip == nil then
		return
	end
	local recorder = pfm.AnimationRecorder(actor, activeFilmClip)
	recorder:StartRecording()
	self.m_animRecorder = recorder
end
function Element:PackProject(fileName)
	local projName = file.remove_file_extension(
		file.get_file_name(self:GetProjectFileName() or "new_project"),
		pfm.Project.get_format_extensions()
	)
	local project = self:GetProject()
	local session = self:GetSession()

	local assetFiles = project:CollectAssetFiles()
	local projectFileName = self:GetProjectFileName()
	if projectFileName ~= nil then
		assetFiles[projectFileName] = projectFileName
	end

	local finalAssetFiles = {}
	for fZip, f in pairs(assetFiles) do
		local rootPath = "addons/pfmp_" .. projName .. "/"
		finalAssetFiles[rootPath .. fZip] = f
	end
	pfm.save_asset_files_as_archive(finalAssetFiles, fileName)
end
function Element:ImportMap(map)
	map = file.remove_file_extension(map, asset.get_supported_extensions(asset.TYPE_MAP, asset.FORMAT_TYPE_ALL))
	local origMapName = map
	map = asset.find_file(origMapName, asset.TYPE_MAP)
	if map == nil then
		if asset.import("maps/" .. origMapName, asset.TYPE_MAP) == false then
			return
		end
		map = asset.find_file(origMapName, asset.TYPE_MAP)
		if map == nil then
			return
		end
	end
	local actorEditor = self:GetActorEditor()
	local data, msg = udm.load("maps/" .. map)
	if data == false then
		pfm.log("Failed to import map '" .. map .. "': " .. msg, pfm.LOG_CATEGORY_PFM)
		return
	end

	local indexCounters = {}

	local group = actorEditor:FindCollection(file.get_file_name(asset.get_normalized_path(map, asset.TYPE_MAP)), true)
	local entityData = data:GetAssetData():GetData():Get("entities")
	for _, entData in ipairs(entityData:GetArrayValues()) do
		local keyValues = entData:Get("keyValues")
		local className = entData:GetValue("className", udm.TYPE_STRING)
		local pose = entData:GetValue("pose", udm.TYPE_SCALED_TRANSFORM) or math.ScaledTransform()
		local model = keyValues:GetValue("model", udm.TYPE_STRING)
		local uuid = keyValues:GetValue("uuid", udm.TYPE_STRING)
		local skin = keyValues:GetValue("skin", udm.TYPE_STRING) or 0
		local angles = keyValues:GetValue("angles", udm.TYPE_STRING)
		local scale = keyValues:GetValue("scale", udm.TYPE_STRING)
		if angles ~= nil then
			angles = EulerAngles(angles)
			pose:SetRotation(angles:ToQuaternion())
		end
		if scale ~= nil then
			scale = Vector(scale)
			pose:SetScale(scale)
		end
		local index
		if indexCounters[className] == nil then
			indexCounters[className] = 1
			index = 0
		else
			index = indexCounters[className]
			indexCounters[className] = index + 1
		end
		local name = keyValues:GetValue("targetname", udm.TYPE_STRING) or (className .. index)
		if className == "prop_physics" or className == "prop_dynamic" or className == "world" then
			if model ~= nil then
				name = file.get_file_name(model)
				local actor = actorEditor:CreateNewActor(
					name,
					pose,
					uuid,
					actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_SCENEBUILD, true, group)
				)
				actorEditor:CreatePresetActor(gui.PFMActorEditor.ACTOR_PRESET_TYPE_STATIC_PROP, {
					["actor"] = actor,
					["modelName"] = model,
				})
				actorEditor:UpdateActorComponents(actor)
			end
		elseif className == "skybox" then
			local actor = actorEditor:CreateNewActor(
				name,
				pose,
				uuid,
				actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_ENVIRONMENT, true, group)
			)

			local mdlC = actorEditor:CreateNewActorComponent(actor, "pfm_model", false, function(mdlC)
				actor:ChangeModel(model)
			end)
			actorEditor:CreateNewActorComponent(actor, "skybox", false)

			actorEditor:UpdateActorComponents(actor)
		elseif className == "env_light_environment" then
		elseif className == "env_light_point" then
			local actor = actorEditor:CreateNewActor(
				name,
				pose,
				uuid,
				actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_LIGHTS, true, group)
			)

			local radius = keyValues:GetValue("radius", udm.TYPE_FLOAT) or 1000.0
			local intensity = keyValues:GetValue("light_intensity", udm.TYPE_FLOAT) or 1000.0
			local intensityType = keyValues:GetValue("light_intensity_type", udm.TYPE_UINT32)
				or ents.LightComponent.INTENSITY_TYPE_CANDELA
			local color = Color(keyValues:GetValue("lightcolor", udm.TYPE_STRING) or "")

			actorEditor:CreateNewActorComponent(actor, "pfm_light_point", false)
			local lightC = actorEditor:CreateNewActorComponent(actor, "light", false)
			actorEditor:CreateNewActorComponent(actor, "light_point", false)
			local radiusC = actorEditor:CreateNewActorComponent(actor, "radius", false)
			local colorC = actorEditor:CreateNewActorComponent(actor, "color", false)
			lightC:SetMemberValue("intensity", udm.TYPE_FLOAT, intensity)
			lightC:SetMemberValue("intensityType", udm.TYPE_UINT32, intensityType)
			lightC:SetMemberValue("castShadows", udm.TYPE_BOOLEAN, false)
			lightC:SetMemberValue("baked", udm.TYPE_BOOLEAN, true)
			radiusC:SetMemberValue("radius", udm.TYPE_FLOAT, radius)
			colorC:SetMemberValue("color", udm.TYPE_VECTOR3, color:ToVector())
			actorEditor:UpdateActorComponents(actor)
		elseif className == "env_fog_controller" then
			local actor = actorEditor:CreateNewActor(
				name,
				pose,
				uuid,
				actorEditor:FindCollection(gui.PFMActorEditor.COLLECTION_ENVIRONMENT, true, group)
			)

			local fogColor = keyValues:GetValue("fogcolor", udm.TYPE_VECTOR3)
			fogColor = (fogColor ~= nil) and (fogColor / 255.0) or Vector(1, 1, 1)
			local fogStart = keyValues:GetValue("fogstart", udm.TYPE_FLOAT) or 500.0
			local fogEnd = keyValues:GetValue("fogend", udm.TYPE_FLOAT) or 2000.0
			local maxDensity = keyValues:GetValue("fogmaxdensity", udm.TYPE_FLOAT) or 1.0
			local fogType = keyValues:GetValue("fogtype", udm.TYPE_UINT32) or game.WorldEnvironment.FOG_TYPE_LINEAR

			local colorC = actorEditor:CreateNewActorComponent(actor, "color", false)
			colorC:SetMemberValue("color", udm.TYPE_VECTOR3, fogColor)

			local fogC = actorEditor:CreateNewActorComponent(actor, "fog_controller", false)
			fogC:SetMemberValue("start", udm.TYPE_FLOAT, fogStart)
			fogC:SetMemberValue("end", udm.TYPE_FLOAT, fogEnd)
			fogC:SetMemberValue("density", udm.TYPE_FLOAT, maxDensity)
			fogC:SetMemberValue("type", udm.TYPE_UINT32, fogType)
			actorEditor:UpdateActorComponents(actor)
		end
	end
end
function Element:ConvertStaticActorsToMap()
	local filmClip = self:GetActiveGameViewFilmClip()
	if filmClip == nil then
		return
	end
	local function add_entity(actor, className)
		local ent = util.WorldData.EntityData()
		ent:SetFlags(bit.bor(ent:GetFlags(), util.WorldData.EntityData.FLAG_CLIENTSIDE_ONLY_BIT))
		ent:SetClassName(className)
		ent:SetKeyValue("uuid", tostring(actor:GetUniqueId()))
		ent:SetPose(actor:GetAbsolutePose())
		return ent
	end
	local function apply_key_value(c, ent, memberName, kvName)
		kvName = kvName or memberName
		local val = c:GetMemberValue(memberName)
		if val ~= nil then
			ent:SetKeyValue(kvName, tostring(val))
		end
	end
	local function apply_component_property(c, cMap, propName)
		local udmData = cMap:GetData()
		local val = c:GetMemberValue(propName)
		if val ~= nil then
			udmData:SetValue(propName, c:GetMemberType(propName), val)
		end
	end
	local function add_component(cActor, entMap)
		if cActor == nil then
			return
		end
		local componentMap = entMap:AddComponent(cActor:GetType())
		componentMap:SetFlags(bit.bor(componentMap:GetFlags(), util.WorldData.ComponentData.FLAG_CLIENTSIDE_ONLY_BIT))
		for name, udmProp in pairs(cActor:GetProperties():GetChildren()) do
			apply_component_property(cActor, componentMap, name)
		end
	end
	local worldData = util.WorldData()
	for _, actor in ipairs(filmClip:GetActorList()) do
		local pfmActorC = actor:FindComponent("pfm_actor")
		local isVisible = true
		if pfmActorC ~= nil then
			isVisible = pfmActorC:GetMemberValue("visible")
		end
		if isVisible then
			local c = actor:FindComponent("light_map_receiver")
			local mdlC = actor:FindComponent("model")
			if c ~= nil and mdlC ~= nil then
				local ent = add_entity(actor, "prop_dynamic")

				apply_key_value(mdlC, ent, "model")
				apply_key_value(mdlC, ent, "skin")
				add_component(c, ent)

				-- TODO: Bodygroups?

				worldData:AddEntity(ent)
			end

			local cLight = actor:FindComponent("light")
			if cLight ~= nil and cLight:GetMemberValue("baked") == true then
				local pointC = actor:FindComponent("light_point")
				local dirC = actor:FindComponent("light_directional")
				local spotC = actor:FindComponent("light_spot")
				local ent
				if pointC ~= nil then
					ent = add_entity(actor, "env_light_point")
					local radiusC = actor:FindComponent("radius")
					if radiusC ~= nil then
						apply_key_value(radiusC, ent, "radius")
					end
				elseif dirC ~= nil then
					ent = add_entity(actor, "env_light_environment")
				elseif spotC ~= nil then
					ent = add_entity(actor, "env_light_spot")
					local radiusC = actor:FindComponent("radius")
					if radiusC ~= nil then
						apply_key_value(radiusC, ent, "radius")
					end
					apply_key_value(spotC, ent, "outerConeAngle", "outerCutoff")
					apply_key_value(spotC, ent, "blendFraction", "blendFraction")
				end
				if ent ~= nil then
					local colorC = actor:FindComponent("color")
					if colorC ~= nil then
						apply_key_value(colorC, ent, "color")
					end

					apply_key_value(cLight, ent, "intensityType", "light_intensity_type")
					apply_key_value(cLight, ent, "intensity")
					worldData:AddEntity(ent)
				end
			end

			local lmC = actor:FindComponent("light_map")
			if lmC ~= nil then
				local ent = add_entity(actor, "entity")
				add_component(lmC, ent)
				add_component(actor:FindComponent("light_map_data_cache"), ent)
				add_component(actor:FindComponent("pfm_cuboid_bounds"), ent)

				worldData:AddEntity(ent)
			end

			local probeC = actor:FindComponent("reflection_probe")
			if probeC ~= nil then
				local ent = add_entity(actor, "entity")
				add_component(probeC, ent)

				worldData:AddEntity(ent)
			end

			local skyC = actor:FindComponent("pfm_sky")
			if skyC ~= nil then
				local ent = add_entity(actor, "entity")
				add_component(skyC, ent)

				worldData:AddEntity(ent)
			end
		end
	end

	local dialogue = gui.create_file_save_dialog(function(pDialog, fileName)
		if fileName == nil then
			return
		end
		fileName = "maps/" .. fileName

		local udmData, err = udm.create()
		if udmData ~= nil then
			local normalizedPath = asset.get_normalized_path(fileName, asset.TYPE_MAP)
			local res, err = worldData:Save(udmData:GetAssetData(), file.get_file_name(normalizedPath))
			if res == false then
				pfm.log("Failed to save world data: " .. err, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
			else
				local fileName = normalizedPath .. "." .. asset.get_udm_format_extension(asset.TYPE_MAP, true)
				file.create_path(file.get_file_path(fileName))
				res, err = udmData:Save(fileName)
				if res == false then
					pfm.log(
						"Failed to save map file '" .. fileName .. "': " .. err,
						pfm.LOG_CATEGORY_PFM,
						pfm.LOG_SEVERITY_WARNING
					)
				else
					pfm.log("Successfully saved map file as '" .. fileName .. "'!", pfm.LOG_CATEGORY_PFM)
				end
			end
		end
	end)
	dialogue:SetRootPath("maps")
	dialogue:SetExtensions(asset.get_supported_extensions(asset.TYPE_MAP))
	dialogue:Update()
end
function Element:ImportPFMProject(projectFilePath)
	local project, err = pfm.load_project(projectFilePath, true)
	if project == false then
		pfm.log(
			"Failed to import PFM project '" .. projectFilePath .. "'!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_ERROR
		)
		return false
	end
	-- TODO: Not yet implemented
	return true
end
function Element:ImportSFMProject(projectFilePath)
	local res = pfm.ProjectManager.ImportSFMProject(self, projectFilePath)
	if res == false then
		pfm.log(
			"Failed to import SFM project '" .. projectFilePath .. "'!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_ERROR
		)
		return false
	end
	local session = self:GetSession()
	if session ~= nil then
		local settings = session:GetSettings()
		local mapName = asset.get_normalized_path(settings:GetMapName(), asset.TYPE_MAP)
		if mapName ~= asset.get_normalized_path(game.get_map_name(), asset.TYPE_MAP) then
			time.create_simple_timer(0.0, function()
				if self:IsValid() then
					self:ChangeMap(mapName)
				end
			end)
		end
	end
	return res
end