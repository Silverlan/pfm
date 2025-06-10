--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("project_packer.lua")

function pfm.save_asset_files_as_archive(assetFiles, fileName, onComplete)
	fileName = file.remove_file_extension(fileName) .. ".zip"
	local job = util.pack_zip_archive(fileName, assetFiles)
	if job == false then
		pfm.log("Failed to pack zip archive '" .. fileName .. "'!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		return
	end
	job:CallOnComplete(function(worker)
		if worker:IsSuccessful() == false then
			console.print_warning("Could not pack zip archive '" .. fileName .. "'!")
			return
		end
		local tFilesNotFound = worker:GetResult()
		if #tFilesNotFound > 0 then
			console.print_warning("Failed to pack " .. #tFilesNotFound .. " files to zip-archive:")
			console.print_table(tFilesNotFound)
		end
		util.open_path_in_explorer(util.get_addon_path(), fileName)
		if onComplete ~= nil then
			onComplete()
		end
	end)
	return job
end

function pfm.pack_models(mdls)
	if #mdls == 0 then
		return
	end
	local packer = pfm.ProjectPacker()
	for _, mdl in ipairs(mdls) do
		packer:AddModel(mdl)
	end

	local mdlName = mdls[1]
	if type(mdlName) ~= "string" then
		mdlName = mdlName:GetName()
	end

	file.create_directory("export")
	local fileName = file.get_file_name(mdlName)
	fileName = file.remove_file_extension(fileName, asset.get_supported_extensions(asset.TYPE_MODEL))
	return pfm.save_asset_files_as_archive(packer:GetFiles(), "export/" .. fileName .. "_packed.zip")
end

function pfm.get_member_info(path, actor)
	local path = panima.Channel.Path(path)
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(path)
	local componentId = componentName and ents.get_component_id(componentName)
	local componentInfo = componentId and ents.get_component_info(componentId)
	if memberName == nil or componentInfo == nil then
		return
	end

	local c
	if util.is_valid(actor) then
		c = actor:GetComponent(componentId)
		if c ~= nil then
			local memberId = c:GetMemberIndex(memberName:GetString())
			if memberId ~= nil then
				return c:GetMemberInfo(memberId), c, memberId
			end
		end
	end
	return componentInfo:GetMemberInfo(memberName:GetString()), c, componentInfo:FindMemberIndex(memberName:GetString())
end

function pfm.set_actor_property_value(actor, propertyPath, valueType, value)
	local uuid
	local t = util.get_type_name(actor)
	if t == "Uuid" then
		uuid = tostring(actor)
	elseif t == "Actor" then
		uuid = tostring(actor:GetUniqueId())
	elseif t == "string" then
		uuid = actor
	else
		uuid = actor:GetUuid()
	end
	actor = pfm.dereference(uuid)
	if actor == nil then
		return false
	end
	actor:SetMemberValue(propertyPath, valueType, value)
	return true
end

function pfm.get_bone_index_from_hit_data(hitData)
	-- Try to determine bone by vertex weight of selected triangle
	local vws = {
		hitData.mesh:GetVertexWeight(hitData.mesh:GetIndex(hitData.primitiveIndex * 3)),
		hitData.mesh:GetVertexWeight(hitData.mesh:GetIndex(hitData.primitiveIndex * 3 + 1)),
		hitData.mesh:GetVertexWeight(hitData.mesh:GetIndex(hitData.primitiveIndex * 3 + 2)),
	}

	local vWeights = { 1.0 - hitData.u, 1.0 - hitData.v, hitData.u + hitData.v }
	local accWeights = {}
	for i = 0, 3 do
		for j, vw in ipairs(vws) do
			local boneId = vw.boneIds:Get(i)
			if boneId ~= -1 then
				accWeights[boneId] = accWeights[boneId] or 0.0
				accWeights[boneId] = accWeights[boneId] + vw.weights:Get(i) * vWeights[j]
			end
		end
	end

	local largestWeight = -1.0
	local boneId = -1
	for accBoneId, accWeight in pairs(accWeights) do
		if accWeight > largestWeight then
			largestWeight = accWeight
			boneId = accBoneId
		end
	end
	return boneId
end

pfm.to_editor_channel_value = function(val, udmType)
	if val == nil then
		return nil, pfm.to_editor_channel_type(udmType)
	end
	local type = util.get_type_name(val)
	if type == "Color" then
		return val:ToVector(), udm.TYPE_VECTOR3
	end
	if type == "Quaternion" then
		return val:ToEulerAngles(), udm.TYPE_EULER_ANGLES
	end
	return val, udmType
end

pfm.to_editor_channel_type = function(udmType)
	if udmType == udm.TYPE_QUATERNION then
		return udm.TYPE_EULER_ANGLES
	end
	return udmType
end

pfm.to_animation_channel_type = function(udmType)
	if udmType == udm.TYPE_EULER_ANGLES then
		return udm.TYPE_QUATERNION
	end
	return udmType
end

pfm.util = pfm.util or {}

local moduleLoadStates = {}
local function load_module(identifier, modulePath)
	if moduleLoadStates[identifier] == nil then
		local r = engine.load_library(modulePath)
		if r ~= true then
			console.print_warning("An error occured trying to load the '" .. identifier .. "' module: ", r)
			moduleLoadStates[identifier] = false
		else
			moduleLoadStates[identifier] = true
		end
	end
	return moduleLoadStates[identifier]
end

pfm.util.init_opencv = function()
	return load_module("pr_opencv", "opencv/pr_opencv")
end

pfm.util.init_curl = function()
	return load_module("pr_curl", "curl/pr_curl")
end

pfm.util.init_openvr = function()
	return load_module("pr_openvr", "openvr/pr_openvr")
end

pfm.util.download_file = function(url, fileName)
	if pfm.util.init_curl() == false then
		return false, "Failed to initialize curl module."
	end

	if fileName:sub(#fileName, #fileName) == "/" then
		fileName = fileName .. url:match(".+/([^/]+)$")
	end

	local job = util.create_parallel_job("download_file", function(worker)
		local requestData = curl.RequestData()
		local request = curl.request(url, requestData)
		request:Start()
		worker:AddTask(request, function(worker)
			local result = request:GetResult()
			file.create_path(file.get_file_path(fileName))
			local f = file.open(fileName, bit.bor(file.OPEN_MODE_WRITE, file.OPEN_MODE_BINARY))
			if f == nil then
				local msg = "Failed to write file '" .. fileName .. "'!"
				worker:SetStatus(util.ParallelJob.JOB_STATUS_FAILED, msg)
				return util.Worker.TASK_STATUS_COMPLETE
			end
			f:Write(result)
			f:Close()

			worker:SetStatus(util.ParallelJob.JOB_STATUS_SUCCESSFUL)
			return util.Worker.TASK_STATUS_COMPLETE
		end, 1.0)
		return util.Worker.TASK_STATUS_COMPLETE
	end, function(worker) end)
	job:Start()
	return job, fileName
end

pfm.util.extract_archive = function(zipFile, extractLocation)
	if type(zipFile) == "string" then
		zipFile = util.ZipFile.open(zipFile, util.ZipFile.OPEN_MODE_READ)
	end
	if zipFile == nil then
		return false
	end
	return zipFile:ExtractFiles(extractLocation, true)
end

pfm.util.get_localized_property_name = function(componentName, pathName)
	if pathName == nil then
		local path = componentName
		componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
		if componentName == nil then
			return util.Path.CreateFilePath(path):GetFileName()
		end
	else
		pathName = util.Path.CreateFilePath(pathName)
	end
	local displayName = pathName:GetFileName()
	local description
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
	return displayName, description
end

pfm.create_file_open_dialog = function(...)
	local fileDialog = gui.create_file_open_dialog(...)
	fileDialog:SetSkin("pfm")
	return fileDialog
end
pfm.create_file_save_dialog = function(...)
	local fileDialog = gui.create_file_save_dialog(...)
	fileDialog:SetSkin("pfm")
	return fileDialog
end
