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
	local tdC = self:GetTrackedDevice()
	if util.is_valid(self.m_ikSolverC) == false or util.is_valid(tdC) == false then
		return
	end
	local pose = tdC:GetDevicePose() --tdC:GetEntity():GetPose()
	pose:SetOrigin(tdC:GetEntity():GetPos())

	local poseLocal = self.m_ikSolverC:GetEntity():GetPose():GetInverse() * pose
	self.m_ikSolverC:SetMemberValue(self.m_controlPropertyIdx, poseLocal:GetOrigin())

	if self.m_rotControlPropertyIdx ~= nil and self.m_controlBoneId ~= nil then
		local twistAxis = self:GetTargetActor():GetModel():FindBoneTwistAxis(self.m_controlBoneId)
		if twistAxis ~= nil then
			local rotOffset = game.Model.get_twist_axis_rotation_offset(twistAxis)
			local poseRot = pose:GetRotation() * rotOffset

			self.m_ikSolverC:SetMemberValue(self.m_rotControlPropertyIdx, poseRot)
		end
	end

	--[[local pos = pose:GetOrigin()
	local dbgInfo = debug.DrawInfo()
	dbgInfo:SetColor(Color.Lime)
	dbgInfo:SetDuration(0.1)
	debug.draw_line(pos, pos + Vector(20, 0, 0), dbgInfo)]]
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
	local memberIndices = { memberIdx }

	propertyName = "control/" .. ikControl .. "/rotation"
	memberIdx = ikSolverC:GetMemberIndex(propertyName)
	if memberIdx ~= nil then
		table.insert(memberIndices, memberIdx)
	end

	return targetActor, ikSolverC, memberIndices
end

function Component:UpdateIkControl()
	pfm.log("Updating tracked device ik control...", pfm.LOG_CATEGORY_PFM_VR)
	self.m_ikSolverC = nil
	self.m_controlPropertyIdx = nil
	self.m_rotControlPropertyIdx = nil
	self.m_controlBoneId = nil
	self.m_refPose = math.ScaledTransform()
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

	local rotPropertyName = "control/" .. ikControl .. "/rotation"
	memberIdx = ikSolverC:GetMemberIndex(rotPropertyName)
	self.m_rotControlPropertyIdx = memberIdx

	local mdl = targetActor:GetModel()
	if mdl ~= nil then
		local ref = mdl:GetReferencePose()
		local boneId = mdl:GetSkeleton():LookupBone(ikControl)
		if boneId ~= -1 then
			self.m_refPose = ref:GetBonePose(boneId)
			self.m_controlBoneId = boneId
		end
	end

	if memberIdx == nil then
		pfm.log(
			"Ik rotation control property '"
				.. rotPropertyName
				.. "' not found in target actor '"
				.. tostring(targetActor)
				.. "'!",
			pfm.LOG_CATEGORY_PFM_VR,
			pfm.LOG_SEVERITY_WARNING
		)
	end

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:SetTrackedDevice(tdC)
	self.m_trackedDevice = tdC
end
function Component:GetTrackedDevice()
	return self.m_trackedDevice
end
ents.COMPONENT_PFM_VR_TRACKED_DEVICE = ents.register_component("pfm_vr_tracked_device", Component)
