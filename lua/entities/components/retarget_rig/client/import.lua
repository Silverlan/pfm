--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function ents.RetargetRig.Rig.find_viable_retarget_rig(mdlImpersonatee,mdlImpostor,skeleton,flexController)
	if(skeleton == nil) then skeleton = true end
	if(flexController == nil) then flexController = false end

	if(type(mdlImpersonatee) == "string") then
		mdlImpersonatee = game.load_model(mdlImpersonatee)
		if(mdlImpersonatee == nil) then return end
	end
	if(type(mdlImpostor) == "string") then
		mdlImpostor = game.load_model(mdlImpostor)
		if(mdlImpostor == nil) then return end
	end

	local path = ents.RetargetRig.Rig.get_rig_location(mdlImpersonatee)
	path = ents.RetargetRig.Rig.FILE_LOCATION .. path:GetString()

	local bestMatch
	local bestMatchCount
	local bestMatchPercentage
	local bestMatchPercentageBones

	local tFiles = file.find(path .. "*.udm")
	for _,fileName in ipairs(tFiles) do
		local udmData,err = udm.load(path .. fileName)
		if(udmData ~= false) then
			local assetData = udmData:GetAssetData():GetData()

			local n = 0
			local nBones = 0
			local matches = 0
			if(skeleton) then
				local udmBoneMap = assetData:Get("rig"):Get("bone_map")
				if(udmBoneMap:IsValid()) then
					local numBones = udmBoneMap:GetChildCount()
					n = n +numBones
					nBones = numBones
					for srcBone,udmDstBone in pairs(udmBoneMap:GetChildren()) do
						local boneId = mdlImpostor:LookupBone(srcBone)
						if(boneId ~= -1) then
							matches = matches +1
						end
					end
				end
			end
			local matchesBones = matches

			if(flexController) then
				local udmFlexCMap = assetData:Get("rig"):Get("flex_controller_map")
				if(udmFlexCMap:IsValid()) then
					for dstFlex,udmDstFlex in pairs(udmFlexCMap:GetChildren()) do
						for srcFlex,data in pairs(udmDstFlex:GetChildren()) do
							local flexCId = mdlImpostor:LookupFlexController(srcFlex)
							n = n +1
							if(flexCId ~= -1) then
								matches = matches +1
							end
						end
					end
				end
			end
			if(n > 0 and (bestMatchCount == nil or matches > bestMatchCount)) then
				bestMatchCount = matches
				bestMatch = fileName
				bestMatchPercentage = (matches /n)
				bestMatchPercentageBones = (nBones > 0) and (matchesBones /nBones) or 0
			end
		end
	end

	local matchThreshold = 0.5
	if(bestMatch ~= nil and ((skeleton == true and bestMatchPercentageBones >= matchThreshold) or (skeleton == false and bestMatchPercentage >= matchThreshold))) then
		return path .. bestMatch
	end
end

function ents.RetargetRig.Rig.find_and_import_viable_retarget_rig(mdlImpersonatee,mdlImpostor,skeleton,flexController)
	if(skeleton == nil) then skeleton = true end
	if(flexController == nil) then flexController = false end

	local f = ents.RetargetRig.Rig.find_viable_retarget_rig(mdlImpersonatee,mdlImpostor,skeleton,flexController)
	if(f == nil) then return false end
	local udmData,err = udm.load(f)
	if(udmData == false) then return false end

	if(type(mdlImpersonatee) == "string") then
		mdlImpersonatee = game.load_model(mdlImpersonatee)
		if(mdlImpersonatee == nil) then return end
	end
	if(type(mdlImpostor) == "string") then
		mdlImpostor = game.load_model(mdlImpostor)
		if(mdlImpostor == nil) then return end
	end

	local rig = ents.RetargetRig.Rig(mdlImpersonatee,mdlImpostor)
	local assetData = udmData:GetAssetData():GetData()
	if(skeleton) then
		local udmBoneMap = assetData:Get("rig"):Get("bone_map")
		for srcBone,udmDstBone in pairs(udmBoneMap:GetChildren()) do
			local srcBoneId = mdlImpostor:LookupBone(srcBone)
			local dstBoneId = mdlImpersonatee:LookupBone(udmDstBone:GetValue(udm.TYPE_STRING))
			if(srcBoneId ~= -1 and dstBoneId ~= -1) then
				rig:SetBoneTranslation(dstBoneId,srcBoneId)
			end
		end
	end

	if(flexController) then
		local udmFlexCMap = assetData:Get("rig"):Get("flex_controller_map")
		for srcFlex,udmDstFlex in pairs(udmFlexCMap:GetChildren()) do
			for dstFlex,udmDstFlex in pairs(udmFlexCMap:GetChildren()) do
				local dstFlexId = mdlImpersonatee:LookupFlexController(dstFlex)
				if(dstFlexId ~= -1) then
					for srcFlex,data in pairs(udmDstFlex:GetChildren()) do
						local srcFlexId = mdlImpostor:LookupFlexController(srcFlex)
						if(srcFlexId ~= -1) then
							local minSrc = data:GetValue("min_source",udm.TYPE_FLOAT) or 0.0
							local maxSrc = data:GetValue("max_source",udm.TYPE_FLOAT) or 1.0
							local minDst = data:GetValue("min_target",udm.TYPE_FLOAT) or 0.0
							local maxDst = data:GetValue("max_target",udm.TYPE_FLOAT) or 1.0
							rig:SetFlexControllerTranslation(dstFlexId,srcFlexId,minSrc,maxSrc,minDst,maxDst)
						end
					end
				end
			end
		end
	end
	return rig:Save()
end
