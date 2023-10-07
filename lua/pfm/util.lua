--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("project_packer.lua")

function pfm.save_asset_files_as_archive(assetFiles, fileName)
	fileName = file.remove_file_extension(fileName) .. ".zip"
	util.pack_zip_archive(fileName, assetFiles)
	util.open_path_in_explorer(util.get_addon_path(), fileName)
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
	pfm.save_asset_files_as_archive(packer:GetFiles(), "export/" .. fileName .. "_packed.zip")
end

function pfm.get_member_info(path, actor)
	local path = panima.Channel.Path(path)
	local componentName, memberName = ents.PanimaComponent.parse_component_channel_path(path)
	local componentId = componentName and ents.get_component_id(componentName)
	local componentInfo = componentId and ents.get_component_info(componentId)
	if memberName == nil or componentInfo == nil then
		return
	end

	if util.is_valid(actor) then
		local c = actor:GetComponent(componentId)
		if c ~= nil then
			local memberId = c:GetMemberIndex(memberName:GetString())
			if memberId ~= nil then
				return c:GetMemberInfo(memberId)
			end
		end
	end
	return componentInfo:GetMemberInfo(memberName:GetString())
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
