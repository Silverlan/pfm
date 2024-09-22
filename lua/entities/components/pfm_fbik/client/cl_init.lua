--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("ik_solver")

local Component = util.register_class("ents.PFMFbIk", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	local ikSolverC = self:AddEntityComponent("ik_solver")

	self.m_ikEnabled = true
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:BindEvent(ents.AnimatedComponent.EVENT_MAINTAIN_ANIMATIONS, "MaintainAnimations")

	self.m_cbUpdateIk = ikSolverC:AddEventCallback(ents.IkSolverComponent.EVENT_ON_IK_UPDATED, function()
		self:UpdateIk()
	end)
end
function Component:OnRemove()
	util.remove(self.m_cbUpdateIk)
end
function Component:SetEnabled(enabled)
	self.m_ikEnabled = enabled
end
function Component:MaintainAnimations()
	-- Disable default skeletal animation playback
	return self.m_ikEnabled and util.EVENT_REPLY_HANDLED or util.EVENT_REPLY_UNHANDLED
end
function Component:UpdateIk()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local ikSolverC = self:GetEntity():GetComponent(ents.COMPONENT_IK_SOLVER)
	local mdl = self:GetEntity():GetModel()
	if ikSolverC == nil then
		return
	end
	-- This assumes that the bones in the solver are in hierarchical order!
	-- If that is not the case, this may cause weird twitching issues between frames.
	for i = 1, ikSolverC:GetBoneCount() do
		local boneId = ikSolverC:GetSkeletalBoneId(i - 1)
		local bone = ikSolverC:GetBone(boneId)
		if bone == nil then
			--local pose = animC:GetBonePose(mdl:GetSkeleton():GetBone(boneId):GetParent():GetID(),math.COORDINATE_SPACE_WORLD) *mdl:GetReferencePose():GetBonePose(boneId)
			--animC:SetBonePose(boneId,posemath.COORDINATE_SPACE_WORLD)
		elseif bone:IsPinned() == false then -- Pinned bones are controlled by forward kinematics
			local pos = bone:GetPos()
			local rot = bone:GetRot()
			local pose = math.ScaledTransform(pos, rot, Vector(1, 1, 1))
			--local pose = animC:GetBonePose(boneId,math.COORDINATE_SPACE_WORLD)
			--pose:SetOrigin(pos)
			animC:SetBonePose(boneId, pose, math.COORDINATE_SPACE_OBJECT)
		end
	end
end
function Component:AddBone(id)
	local solverC = self:GetEntityComponent(ents.COMPONENT_IK_SOLVER)
	if solverC == nil then
		return
	end
	return solverC:AddSimpleBone(id)
end
function Component:UpdateIkRig() end
ents.register_component("pfm_fbik", Component, "animation")
