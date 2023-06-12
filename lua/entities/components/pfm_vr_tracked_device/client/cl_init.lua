--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVrTrackedDevice", BaseEntityComponent)

Component:RegisterMember("SerialNumber", ents.MEMBER_TYPE_STRING, "", {
	flags = ents.ComponentInfo.MemberInfo.FLAG_READ_ONLY_BIT,
})
Component:RegisterMember("TargetActor", ents.MEMBER_TYPE_ENTITY, "", {
	onChange = function(c)
		c:UpdateIkControl()
	end,
})
Component:RegisterMember("IkControl", ents.MEMBER_TYPE_STRING, "", {
	onChange = function(c)
		c:UpdateIkControl()
	end,
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end

function Component:OnRemove() end

function Component:OnEntitySpawn() end

function Component:OnTick()
	self:UpdateEffector()
end

function Component:UpdateEffector()
	--[[local tdC = self:GetTrackedDevice()
	if(util.is_valid(self.m_ikSolverC) == false or util.is_valid(tdC) == false) then return end
	local pose = tdC:GetEntity():GetPose()
	local poseLocal = self.m_ikSolverC:GetEntity():GetPose():GetInverse() *pose
	self.m_ikSolverC:SetMemberValue(self.m_controlPropertyIdx,poseLocal:GetOrigin())

	local pos = pose:GetOrigin()
	local dbgInfo = debug.DrawInfo()
	dbgInfo:SetColor(Color.Lime)
	dbgInfo:SetDuration(0.1)
	debug.draw_line(pos,pos +Vector(20,0,0),dbgInfo)]]
end

function Component:GetControlPropertyIndex()
	return self.m_controlPropertyIdx
end

function Component:GetTargetData()
	local targetActor = self:GetTargetActor()
	if util.is_valid(targetActor) == false then
		return
	end
	local ikSolverC = targetActor:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	local ikControl = self:GetIkControl()
	local propertyName = "control/" .. ikControl .. "/position"
	local memberIdx = ikSolverC:GetMemberIndex(propertyName)
	if memberIdx == nil then
		return
	end
	return targetActor, ikSolverC, memberIdx
end

function Component:UpdateIkControl()
	pfm.log("Updating tracked device ik control...", pfm.LOG_CATEGORY_PFM_VR)
	self.m_ikSolverC = nil
	self.m_controlPropertyIdx = nil
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)

	local targetActor = self:GetTargetActor()
	local ikControl = self:GetIkControl()
	if util.is_valid(targetActor) == false or ikControl == nil then
		pfm.log(
			"Failed to locate target actor '" .. tostring(self:GetTargetActorReference()) .. "'!",
			pfm.LOG_CATEGORY_PFM_VR,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	local ikSolverC = targetActor:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		pfm.log(
			"Target actor '" .. tostring(targetActor) .. "' has no ik solver component!",
			pfm.LOG_CATEGORY_PFM_VR,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	local propertyName = "control/" .. ikControl .. "/position"
	local memberIdx = ikSolverC:GetMemberIndex(propertyName)
	if memberIdx == nil then
		pfm.log(
			"Ik control property '" .. propertyName .. "' not found in target actor '" .. tostring(targetActor) .. "'!",
			pfm.LOG_CATEGORY_PFM_VR,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	self.m_ikSolverC = ikSolverC
	self.m_controlPropertyIdx = memberIdx
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

	-- Test POV
	local vrBody = targetActor:AddComponent("vr_body")
	local upperBodyBoneChain = { 10, 11, 12 }
	local leftArmBoneChain = { 16, 17, 18 }
	local rightArmBoneChain = { 35, 36, 37 }
	local headBone = 14
	if #upperBodyBoneChain > 2 then
		vrBody:SetUpperBody(upperBodyBoneChain)
	end
	if #leftArmBoneChain > 2 then
		vrBody:SetLeftArm(leftArmBoneChain)
	end
	if #rightArmBoneChain > 2 then
		vrBody:SetRightArm(rightArmBoneChain)
	end
	if headBone ~= -1 then
		vrBody:SetHeadBone(headBone)
	end

	local ent, vrManagerC = ents.citerator(ents.COMPONENT_PFM_VR_MANAGER)()
	vrBody:SetHmd(vrManagerC:GetHmd())

	--[[local vrCameraPovC = targetActor:GetComponent("vr_camera_pov")
	if(#upperBodyBoneChain > 2) then vrCameraPovC:SetUpperBody(upperBodyBoneChain) end
	if(#leftArmBoneChain > 2) then vrCameraPovC:SetLeftArm(leftArmBoneChain) end
	if(#rightArmBoneChain > 2) then vrCameraPovC:SetRightArm(rightArmBoneChain) end
	if(headBone ~= -1) then vrCameraPovC:SetHeadBone(headBone) end
	--vrBody:SetHmd(entHmd:GetComponent(ents.COMPONENT_VR_HMD))

	local povCameraC = targetActor:AddComponent("pov_camera")
	povCameraC:SetHeadEntity(entActor,headBone,neckBone,targetBone)
	povCameraC:SetEnabled(true)]]
end

function Component:SetTrackedDevice(tdC)
	self.m_trackedDevice = tdC
end
function Component:GetTrackedDevice()
	return self.m_trackedDevice
end
ents.COMPONENT_PFM_VR_TRACKED_DEVICE = ents.register_component("pfm_vr_tracked_device", Component)
