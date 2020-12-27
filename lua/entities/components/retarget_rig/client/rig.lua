--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.RetargetRig.Rig")

include("rig_flex.lua")

ents.RetargetRig.Rig.FILE_LOCATION = "retarget_rigs/"
ents.RetargetRig.Rig.impl = {}

function ents.RetargetRig.Rig:__init(srcMdl,dstMdl)
	self.m_srcMdl = srcMdl
	self.m_dstMdl = dstMdl
	self.m_bindPose = dstMdl:GetReferencePose():Copy()

	-- Note: Bone translations are stored in reverse (i.e. [destination] = source),
	-- since different destination bones can be mapped to the same source bones!
	self.m_dstToSrcTranslationTable = {}

	-- Flex translations are stored [source] = {destination0,destination1,...},
	-- since we're also storing additional information per (source,destinationX) pair
	self.m_flexTranslationTable = {}
end
function ents.RetargetRig.Rig:GetSourceModel() return self.m_srcMdl end
function ents.RetargetRig.Rig:GetDestinationModel() return self.m_dstMdl end
function ents.RetargetRig.Rig:SetDstToSrcTranslationTable(t)
	self.m_dstToSrcTranslationTable = t
	self:ApplyPoseMatchingRotationCorrections()
end
function ents.RetargetRig.Rig:GetDstToSrcTranslationTable() return self.m_dstToSrcTranslationTable end
function ents.RetargetRig.Rig:GetBindPoseTransforms() return self.m_bindPoseTransforms end
function ents.RetargetRig.Rig:GetBoneTranslation(boneId) return self.m_dstToSrcTranslationTable[boneId] end
function ents.RetargetRig.Rig:SetBoneTranslation(boneIdSrc,boneIdDst)
	if(boneIdSrc == -1 or boneIdDst == -1) then return end
	self.m_dstToSrcTranslationTable[boneIdDst] = boneIdSrc
	self:ApplyPoseMatchingRotationCorrections()
end
function ents.RetargetRig.Rig:GetBindPose() return self.m_bindPose end
function ents.RetargetRig.Rig:SetBindPose(bindPose)
	self.m_bindPose = bindPose
	self:UpdateBindPoses()
end
function ents.RetargetRig.Rig:UpdateBindPoses()
	local mdl0 = self.m_dstMdl
	local skeleton0 = mdl0:GetSkeleton()
	local bindPoseTransforms = {}
	for i=0,skeleton0:GetBoneCount() -1 do
		local parent = skeleton0:GetBone(i):GetParent()
		if(parent == nil) then bindPoseTransforms[i] = phys.Transform()
		else
			local posP,rotP,scaleP = self.m_bindPose:GetBoneTransform(parent:GetID())
			local posC,rotC,scaleC = self.m_bindPose:GetBoneTransform(i)
			local poseP = phys.Transform(posP,rotP)
			local poseC = phys.Transform(posC,rotC)
			bindPoseTransforms[i] = poseP:GetInverse() *poseC
		end
	end
	self.m_bindPoseTransforms = bindPoseTransforms
end
function ents.RetargetRig.Rig:CalcDeltaRotationBetweenParentChildPoses(pose,poseParent,poseOther,poseOtherParent)
	local dir0 = poseParent:GetOrigin() -pose:GetOrigin()
	local dir1 = poseOtherParent:GetOrigin() -poseOther:GetOrigin()
	return dir0:GetRotation(dir1)
end
function ents.RetargetRig.Rig:ApplyBonePoseMatchingRotationCorrections(bindPose,bone,parentPose)
	-- We need to apply some rotational corrections to try and match the two skeletons in cases where their bind pose is
	-- very different from each other (e.g. if one bind pose has the arms stretched out to the side and the other has the arms pointing down)
	parentPose = parentPose or phys.Transform()
	local pose = bindPose:GetBonePose(bone:GetID())
	local boneTranslationIds = self:GetDstToSrcTranslationTable()
	local dstMdl = self.m_srcMdl
	local skeleton1 = dstMdl:GetSkeleton()
	local ref1 = dstMdl:GetReferencePose()

	local rotations = {}
	local poseThis = parentPose *pose
	local rot = Quaternion()
	-- We'll try to roughly match the rotations of our skeletons
	for boneId,child in pairs(bone:GetChildren()) do
		if(boneTranslationIds[boneId] ~= nil) then
			local pose = poseThis *bindPose:GetBonePose(boneId)
			local boneOther = skeleton1:GetBone(boneTranslationIds[boneId])
			local boneParentOther = boneOther:GetParent()
			local poseOther = ref1:GetBonePose(boneOther:GetID())
			local poseOtherParent = (boneParentOther ~= nil) and ref1:GetBonePose(boneParentOther:GetID()) or phys.Transform()

			rot = self:CalcDeltaRotationBetweenParentChildPoses(pose,poseThis,poseOther,poseOtherParent)
			table.insert(rotations,rot)
		end
	end
	rot = math.calc_average_rotation(rotations)

	local boneBindPose = parentPose *pose
	boneBindPose:SetRotation(rot:GetInverse() *boneBindPose:GetRotation())
	boneBindPose = parentPose:GetInverse() *boneBindPose
	bindPose:SetBonePose(bone:GetID(),boneBindPose)

	pose = parentPose *pose
	pose:SetRotation(rot *pose:GetRotation())
	pose = parentPose:GetInverse() *pose

	pose = parentPose *pose
	for boneId,child in pairs(bone:GetChildren()) do
		self:ApplyBonePoseMatchingRotationCorrections(bindPose,child,pose)
	end
end
function ents.RetargetRig.Rig:ApplyPoseMatchingRotationCorrections()
	local srcMdl = self.m_dstMdl
	local skeleton0 = srcMdl:GetSkeleton()
	local ref0 = srcMdl:GetReferencePose()

	local bindPose = self.m_bindPose -- self.m_dstMdl:GetReferencePose():Copy()
	local ref = self.m_dstMdl:GetReferencePose()
	for boneId=0,ref:GetBoneCount() -1 do
		bindPose:SetBonePose(boneId,ref:GetBonePose(boneId))
	end
	bindPose:Localize(skeleton0)

	for boneId,bone in pairs(skeleton0:GetRootBones()) do
		self:ApplyBonePoseMatchingRotationCorrections(bindPose,bone)
	end
	bindPose:Globalize(skeleton0)

	for _,bone in ipairs(skeleton0:GetBones()) do
		local pose = ref0:GetBonePose(bone:GetID())
		pose:SetRotation(bindPose:GetBonePose(bone:GetID()):GetRotation())
		bindPose:SetBonePose(bone:GetID(),pose)
	end

	self:SetBindPose(bindPose)
end
function ents.RetargetRig.Rig.get_rig_file_path(srcMdl,dstMdl)
	local dstHash = string.hash(type(dstMdl) == "string" and dstMdl or dstMdl:GetName())
	local path = ents.RetargetRig.Rig.get_rig_location(srcMdl):GetString() .. dstHash .. ".rig"
	return util.Path.CreateFilePath(path)
end
function ents.RetargetRig.Rig.get_rig_location(mdl)
	local hash = string.hash(type(mdl) == "string" and mdl or mdl:GetName())
	local path = ents.RetargetRig.Rig.FILE_LOCATION .. hash .. "/"
	return util.Path.CreatePath(path)
end
function ents.RetargetRig.Rig.get_bone_cache_map_file_path()
	return ents.RetargetRig.Rig.FILE_LOCATION .. "bone_cache.txt"
end
function ents.RetargetRig.Rig.load_bone_cache_map()
	if(ents.RetargetRig.Rig.impl.boneMapCache ~= nil) then return ents.RetargetRig.Rig.impl.boneMapCache end
	local cache = {}
	ents.RetargetRig.Rig.impl.boneMapCache = cache
	local contents = file.read(ents.RetargetRig.Rig.get_bone_cache_map_file_path())
	if(contents == nil) then return cache end
	local lines = string.split(contents,"\n")
	for _,line in ipairs(lines) do
		local kv = string.split(line,"=")
		if(kv[1] ~= nil and kv[2] ~= nil) then
			local boneSrc = string.remove_whitespace(kv[1])
			local boneDst = string.remove_whitespace(kv[2])
			if(#boneSrc > 0 and #boneDst > 0) then
				cache[boneSrc] = cache[boneSrc] or {}
				cache[boneSrc][boneDst] = true
			end
		end
	end
	return cache
end
function ents.RetargetRig.Rig:DebugPrint()
	local srcMdl = self.m_dstMdl
	local skeleton0 = srcMdl:GetSkeleton()

	local dstMdl = self.m_srcMdl
	local skeleton1 = dstMdl:GetSkeleton()
	print("Source model: ",dstMdl:GetName())
	print("Target model: ",srcMdl:GetName())
	print("Bone translations:")
	for boneId0,boneId1 in pairs(self:GetDstToSrcTranslationTable()) do
		local bone0 = skeleton0:GetBone(boneId0)
		local bone1 = skeleton1:GetBone(boneId1)
		print("[\"" .. bone0:GetName() .. "\"] = \"" .. bone1:GetName() .. "\",")
	end
	print("Flex controller translations:")
	for fcIdSrc,mappings in pairs(self:GetFlexControllerTranslationTable()) do
		local flexCSrc = dstMdl:GetFlexController(fcIdSrc)
		print("[\"" .. (flexCSrc and flexCSrc.name or "invalid") .. "\"]:")
		for fcIdDst,data in pairs(mappings) do
			local flexCDst = srcMdl:GetFlexController(fcIdDst)
			print("\t[\"" .. (flexCDst and flexCDst.name or "invalid") .. "\"]:")
			print("\t\tmin_source: " .. data.min_source)
			print("\t\tmax_source: " .. data.max_source)
			print("\t\tmin_target: " .. data.min_target)
			print("\t\tmax_target: " .. data.max_target)
		end
	end
	print("")
end
function ents.RetargetRig.Rig:Save()
	self:DebugPrint()
	local srcMdl = self.m_dstMdl
	local skeleton0 = srcMdl:GetSkeleton()

	local dstMdl = self.m_srcMdl
	local skeleton1 = dstMdl:GetSkeleton()

	local db = util.DataBlock.create()

	db:SetValue("string","source",dstMdl:GetName())
	db:SetValue("string","target",srcMdl:GetName())

	local bm = db:AddBlock("bone_map")
	local translationTable = self:GetDstToSrcTranslationTable()
	local translationNameTable = {}
	for boneId0,boneId1 in pairs(translationTable) do
		local bone0 = skeleton0:GetBone(boneId0)
		local bone1 = skeleton1:GetBone(boneId1)
		if(bone0 == nil or bone1 == nil) then console.print_warning("Retarget rig has invalid bone reference, not all bones will be saved!")
		else
			bm:SetValue("string",bone0:GetName(),bone1:GetName())
			translationNameTable[bone0:GetName()] = bone1:GetName()
		end
	end
	ents.RetargetRig.Rig.add_bone_list_to_cache_map(translationNameTable)
	ents.RetargetRig.Rig.save_flex_controller_map(db,dstMdl,srcMdl,self.m_flexTranslationTable)

	local filePath = ents.RetargetRig.Rig.get_rig_file_path(dstMdl,srcMdl)
	if(file.create_path(filePath:GetPath()) == false) then return end
	local f = file.open(filePath:GetString(),bit.bor(file.OPEN_MODE_WRITE))
	if(f == nil) then return end
	f:WriteString(db:ToString("rig"))
	f:Close()
end
function ents.RetargetRig.Rig.load(psrcMdl,pdstMdl)
	-- TODO: Flip these names
	local srcMdl = pdstMdl
	local dstMdl = psrcMdl
	local filePath = ents.RetargetRig.Rig.get_rig_file_path(dstMdl,srcMdl)
	local f = file.open(filePath:GetString(),bit.bor(file.OPEN_MODE_READ))
	if(f == nil) then return end
	local root = util.DataBlock.load(f)
	f:Close()
	if(root == nil) then return end
	local db = root:FindBlock("rig")
	if(db == nil) then return end
	local source = db:GetString("source")
	local target = db:GetString("target")

	local skeleton0 = srcMdl:GetSkeleton()
	local skeleton1 = dstMdl:GetSkeleton()
	local bm = db:FindBlock("bone_map")
	local translationTable = {}
	if(bm ~= nil) then
		for _,boneName0 in ipairs(bm:GetKeys()) do
			local boneName1 = bm:GetString(boneName0)
			local boneId0 = srcMdl:LookupBone(boneName0)
			local boneId1 = dstMdl:LookupBone(boneName1)
			if(boneId0 == -1 or boneId1 == -1) then console.print_warning("Retarget rig has invalid bone reference from bone '" .. boneName0 .. "' to bone '" .. boneName1 .. "'! Ignoring...")
			else translationTable[boneId0] = boneId1 end
		end
	end

	local rig = ents.RetargetRig.Rig(dstMdl,srcMdl)
	rig.m_dstToSrcTranslationTable = translationTable
	rig.m_flexTranslationTable = ents.RetargetRig.Rig.load_flex_controller_map(db,dstMdl,srcMdl)
	rig:DebugPrint()
	rig:SetDstToSrcTranslationTable(translationTable)
	return rig
end
function ents.RetargetRig.Rig.is_bone_relation_in_cache(srcBone,dstBone)
	local cache = ents.RetargetRig.Rig.load_bone_cache_map()
	if(cache[srcBone] == nil) then return false end
	return cache[srcBone][dstBone] or false
end
function ents.RetargetRig.Rig.add_bone_list_to_cache_map(boneList)
	local cache = ents.RetargetRig.Rig.load_bone_cache_map()
	for boneSrc,boneDst in pairs(boneList) do
		cache[boneSrc] = cache[boneSrc] or {}
		cache[boneSrc][boneDst] = true

		cache[boneDst] = cache[boneDst] or {}
		cache[boneDst][boneSrc] = true
	end

	local contents = ""
	for boneSrc,list in pairs(cache) do
		for boneDst,_ in pairs(list) do
			if(boneDst ~= boneSrc) then
				if(#contents > 0) then contents = contents .. "\n" end
				contents = contents .. boneSrc .. "=" .. boneDst
			end
		end
	end
	file.write(ents.RetargetRig.Rig.get_bone_cache_map_file_path(),contents)
end
