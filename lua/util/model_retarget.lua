--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]


function util.retarget_model(impostee,impostor)
	local mdlSrc = impostee
	local mdlDst = impostor

	local ent = ents.create_prop(mdlSrc)
	local mdl = game.load_model(mdlDst):Copy(game.Model.FCOPY_DEEP)
	mdl:ClearAnimations()

	ent:PlayAnimation("reference")
	local impersonateeC = ent:AddComponent("impersonatee")
	impersonateeC:SetImpostorModel(mdlDst)

	local impostorC = impersonateeC:GetImpostor()
	local retargetC = impostorC:GetEntity():GetComponent("retarget_rig")
	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()
	local numBones = skeleton:GetBoneCount()
	for i=0,numBones -1 do
		local retargetBindPose = retargetC.m_origBindPoseToRetargetBindPose[i]
		local pose = ref:GetBonePose(i)
		-- pose = pose *retargetBindPose
		ref:SetBonePose(i,pose)
	end

	for _,animName in ipairs(ent:GetModel():GetAnimationNames()) do
		print("Retargeting animation '" .. animName .. "'...")
		ent:PlayAnimation(animName)

		local anim = ent:GetModel():GetAnimation(animName)
		local flags = anim:GetFlags()
		if(bit.band(flags,game.Model.Animation.FLAG_GESTURE) == 0) then
			local animCpy = game.Model.Animation.Create()
			local boneList = {}
			for i=0,numBones -1 do
				table.insert(boneList,i)
			end
			animCpy:SetBoneList(boneList)
			animCpy:SetFPS(anim:GetFPS())
			local animCSrc = impersonateeC:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
			local animC = impostorC:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)

			local numFrames = anim:GetFrameCount()
			for frameId=0,numFrames -1 do
				--animC:SetCycle(frameId /(numFrames -1))
				local c = animCSrc:GetCycle()
				local dt = (1 /(numFrames -1)) /(anim:GetFPS() /numFrames)
				if(c +dt > 1) then dt = (1.0 -c) end
				animCSrc:ClearPreviousAnimation()
				animCSrc:AdvanceAnimations(dt)
				animCSrc:UpdateEffectiveBoneTransforms()
				animC:ClearPreviousAnimation()
				animC:AdvanceAnimations(dt)
				local frame = game.Model.Animation.Frame.Create(numBones)
				for i=0,numBones -1 do
					frame:SetBonePose(i,animC:GetBonePose(i))
				end
				animCpy:AddFrame(frame)
			end
			mdl:AddAnimation(animName,animCpy)
		end
	end

	util.remove(ent)
	return mdl
end
