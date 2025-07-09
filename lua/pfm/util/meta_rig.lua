-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}

pfm.util.is_character_model = function(model)
	return pfm.util.get_character_head_data(model) ~= nil
end

pfm.util.get_character_head_data = function(model)
	local mdl = model
	if type(mdl) == "string" then
		mdl = game.load_model(mdl)
	end
	if mdl == nil then
		return
	end
	local metaRig = mdl:GetMetaRig()
	if metaRig == nil then
		return
	end
	local metaBoneHead = metaRig:GetBone(Model.MetaRig.BONE_TYPE_HEAD)
	local metaBoneNeck = metaRig:GetBone(Model.MetaRig.BONE_TYPE_NECK)
	if metaBoneHead == nil or metaBoneNeck == nil then
		return
	end

	local headBones = {}
	local skeleton = mdl:GetSkeleton()
	local headBone = skeleton:GetBone(metaBoneHead.boneId)
	local addHeadBones
	addHeadBones = function(bone)
		for id, child in pairs(bone:GetChildren()) do
			headBones[id] = true
			addHeadBones(child)
		end
	end
	addHeadBones(headBone)
	return {
		headBounds = { metaBoneHead.min, metaBoneHead.max },
		headBoneId = metaBoneHead.boneId,
		headParentBoneId = metaBoneNeck.boneId,
		headBones = headBones,
	}
end
