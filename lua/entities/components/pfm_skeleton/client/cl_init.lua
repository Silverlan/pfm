--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMSkeleton",BaseEntityComponent)

function ents.PFMSkeleton:Initialize()
	BaseEntityComponent.Initialize(self)

	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,"OnModelChanged")
	self:BindEvent(ents.AnimatedComponent.EVENT_ON_SKELETON_UPDATED,"UpdateSkeleton")

	self.m_bones = {}
end

function ents.PFMSkeleton:OnRemove()
	self:ClearBones()
end

function ents.PFMSkeleton:OnModelChanged()
	self:InitializeSkeleton()
end

function ents.PFMSkeleton:CreateBone(boneId,boneLength)
	local ent = ents.create("pfm_bone")
	self.m_bones[boneId] = ent
	ent:Spawn()

	ent:GetComponent(ents.COMPONENT_TRANSFORM):SetScale(Vector(boneLength,boneLength,boneLength))
end

function ents.PFMSkeleton:ClearBones()
	for boneId,ent in pairs(self.m_bones) do
		if(ent:IsValid()) then ent:Remove() end
	end
	self.m_bones = {}
end

function ents.PFMSkeleton:InitializeSkeletonBones(animC,bones,parentPose,parentBone)
	parentPose = parentPose or phys.ScaledTransform()
	local avgLen = 0.0
	local numBones = 0
	for boneId,bone in pairs(bones) do
		local pose = parentPose *animC:GetBonePose(boneId)
		avgLen = avgLen +parentPose:GetOrigin():Distance(pose:GetOrigin())
		numBones = numBones +1
		local len = self:InitializeSkeletonBones(animC,bone:GetChildren(),pose,bone)
		if(len == 0.0) then len = 10.0 end
		self:CreateBone(boneId,len)
	end
	avgLen = avgLen /numBones
	return avgLen
end

function ents.PFMSkeleton:UpdateSkeletonPoses(animC,bones,parentPose)
	parentPose = parentPose or self:GetEntity():GetPose()
	for boneId,bone in pairs(bones) do
		local pose = parentPose *animC:GetBonePose(boneId)
		local entBone = self.m_bones[boneId]
		if(util.is_valid(entBone)) then
			entBone:SetPos(pose:GetOrigin())
			entBone:SetRotation(parentPose:GetRotation())
		end
		self:UpdateSkeletonPoses(animC,bone:GetChildren(),pose)
	end
end

function ents.PFMSkeleton:InitializeSkeleton()
	self:ClearBones()

	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(mdl == nil or animC == nil) then return end
	local skeleton = mdl:GetSkeleton()
	self:InitializeSkeletonBones(animC,skeleton:GetRootBones())
	self:UpdateSkeleton()
end

function ents.PFMSkeleton:OnEntitySpawn()
	self:InitializeSkeleton()
end

function ents.PFMSkeleton:UpdateSkeleton()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local mdl = self:GetEntity():GetModel()
	local skeleton = (mdl ~= nil) and mdl:GetSkeleton() or nil
	if(animC == nil or skeleton == nil) then return end
	self:UpdateSkeletonPoses(animC,skeleton:GetRootBones())
end
ents.COMPONENT_PFM_SKELETON = ents.register_component("pfm_skeleton",ents.PFMSkeleton)
