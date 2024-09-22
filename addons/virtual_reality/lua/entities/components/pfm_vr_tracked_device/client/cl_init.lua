--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVrTrackedDevice", BaseEntityComponent)

Component.IK_CONTROL_TYPE_HEAD = 0
Component.IK_CONTROL_TYPE_EXTREMITY = 1

Component:RegisterMember("SerialNumber", ents.MEMBER_TYPE_STRING, "", {
	flags = ents.ComponentInfo.MemberInfo.FLAG_READ_ONLY_BIT,
})
Component:RegisterMember("TargetActor", ents.MEMBER_TYPE_ENTITY, "", {
	onChange = function(c)
		c:UpdateIkControl()
	end,
})
Component:RegisterMember("TargetProperty", ents.MEMBER_TYPE_STRING, "", {
	onChange = function(c)
		c:UpdateIkControl()
	end,
})
Component:RegisterMember("Offset", udm.TYPE_VECTOR3, Vector(0, 0, 0), {
	onChange = function(self)
		self:UpdateIkControl()
	end,
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end

function Component:OnRemove()
	util.remove(self.m_cbOnTrackingStateChanged)
end

function Component:OnEntitySpawn() end

function Component:OnTick()
	if
		util.is_valid(self.m_managerC) == false--[[ or self.m_managerC:IsIkTrackingEnabled() == false]]
	then
		return
	end
	self:UpdateEffector()
end

function Component:UpdateEffector()
	local tdC = self:GetTrackedDevice()
	if util.is_valid(self.m_targetComponent) == false or util.is_valid(tdC) == false then
		return
	end
	local pose = tdC:GetDevicePose() --tdC:GetEntity():GetPose()
	pose:SetOrigin(tdC:GetEntity():GetPos())
	pose:TranslateLocal(self.m_posOffset)
	self.m_targetComponent:SetTransformMemberPos(self.m_posPropertyIdx, math.COORDINATE_SPACE_WORLD, pose:GetOrigin())

	if self.m_rotPropertyIdx ~= nil then
		local rotOffset = self.m_rotOffset
		rotOffset = EulerAngles(0, 0, 90):ToQuaternion()
		pose:SetRotation(tdC:GetEntity():GetRotation())
		local poseRot = pose:GetRotation() * rotOffset
		--poseRot = Quaternion()
		self.m_targetComponent:SetTransformMemberRot(self.m_rotPropertyIdx, math.COORDINATE_SPACE_WORLD, poseRot)
	end

	--[[local pos = pose:GetOrigin()
	local dbgInfo = debug.DrawInfo()
	dbgInfo:SetColor(Color.Lime)
	dbgInfo:SetDuration(0.1)
	debug.draw_line(pos, pos + Vector(20, 0, 0), dbgInfo)]]
end

function Component:GetControlPropertyIndex()
	return self.m_posPropertyIdx
end

function Component:GetTargetData()
	local targetActor = self:GetTargetActor()
	if util.is_valid(targetActor) == false then
		return
	end
	local targetProperty = self:GetTargetProperty()
	local poseMetaInfo, component = pfm.util.find_property_pose_meta_info(targetActor, targetProperty)
	if poseMetaInfo == nil then
		self:LogWarn("Unable to find pose meta info for property '" .. targetProperty .. "'!")
		return
	end
	local posPropertyPath = "ec/" .. component .. "/" .. poseMetaInfo.posProperty
	local rotPropertyPath = "ec/" .. component .. "/" .. poseMetaInfo.rotProperty
	local posMemberInfo, component = pfm.get_member_info(posPropertyPath, targetActor)

	if posMemberInfo == nil then
		return
	end
	local idxPos = component:GetMemberInfo(posPropertyPath)
	if idxPos == nil then
		return
	end
	local memberIndices = { idxPos }

	local idxRot = component:GetMemberIndex(rotPropertyPath)
	if idxRot ~= nil then
		table.insert(memberIndices, idxRot)
	end

	return targetActor, component, memberIndices
end

function Component:SetManager(managerC)
	self.m_managerC = managerC
	util.remove(self.m_cbOnTrackingStateChanged)
	self.m_cbOnTrackingStateChanged = managerC:AddEventCallback(
		ents.PFMVrManager.EVENT_ON_IK_TRACKING_STATE_CHANGED,
		function()
			self:UpdateTrackingState()
		end
	)
	self:UpdateTrackingState()
end

function Component:UpdateTrackingState()
	local targetActor = self:GetTargetActor()
	if util.is_valid(self.m_managerC) == false or util.is_valid(targetActor) == false then
		return
	end

	local enableProperties = not self.m_managerC:IsIkTrackingEnabled()
	local panimaC = targetActor:GetComponent(ents.COMPONENT_PANIMA)
	if panimaC ~= nil then
		if self.m_posPropertyName ~= nil then
			panimaC:SetPropertyEnabled("ec/ik_solver/" .. self.m_posPropertyName, enableProperties)
		end
		if self.m_rotPropertyName ~= nil then
			panimaC:SetPropertyEnabled("ec/ik_solver/" .. self.m_rotPropertyName, enableProperties)
		end
	end
end

function Component:UpdateIkControl()
	self:LogInfo("Updating tracked device ik control...")
	self.m_targetComponent = nil
	self.m_posPropertyIdx = nil
	self.m_posPropertyName = nil
	self.m_rotPropertyIdx = nil
	self.m_rotPropertyName = nil
	self.m_posOffset = Vector()
	self.m_rotOffset = Quaternion()
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)

	local targetActor = self:GetTargetActor()
	local targetProperty = self:GetTargetProperty()
	if util.is_valid(targetActor) == false or targetProperty == nil then
		self:LogWarn("Failed to locate target actor '" .. tostring(self:GetTargetActorReference()) .. "'!")
		return
	end

	local poseMetaInfo, componentName = pfm.util.find_property_pose_meta_info(targetActor, targetProperty)
	if componentName == nil then
		self:LogWarn(
			"Target actor '"
				.. tostring(targetActor)
				.. "' has has no component for property '"
				.. targetProperty
				.. "'!"
		)
		return
	end
	local component = targetActor:GetComponent(componentName)
	if component == nil then
		self:LogWarn(
			"Target actor '"
				.. tostring(targetActor)
				.. "' has has no component for property '"
				.. targetProperty
				.. "'!"
		)
		return
	end
	local posPropertyPath = "ec/" .. componentName .. "/" .. poseMetaInfo.posProperty
	local posMemberInfo, _, posMemberIdx = pfm.get_member_info(posPropertyPath, targetActor)
	if posMemberIdx == nil then
		self:LogWarn(
			"Property '" .. poseMetaInfo.posProperty .. "' not found in target actor '" .. tostring(targetActor) .. "'!"
		)
		return
	end
	self.m_targetComponent = component
	self.m_posPropertyIdx = posMemberIdx
	self.m_posPropertyName = posPropertyPath

	local rotPropertyName = "ec/" .. componentName .. "/" .. poseMetaInfo.rotProperty
	local rotMemberInfo, _, rotMemberIdx = pfm.get_member_info(rotPropertyName, targetActor)
	self.m_rotPropertyIdx = rotMemberIdx
	if rotMemberInfo ~= nil then
		self.m_rotPropertyName = rotPropertyName
	end

	local pm = tool.get_filmmaker()
	local actorC = targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	--[[if util.is_valid(pm) and actorC ~= nil then
		-- Make the ik properties animated
		pm:MakeActorPropertyAnimated(
			actorC:GetActorData(),
			"ec/ik_solver/" .. propertyName,
			udm.TYPE_VECTOR3,
			true,
			false
		)
		pm:MakeActorPropertyAnimated(
			actorC:GetActorData(),
			"ec/ik_solver/" .. rotPropertyName,
			udm.TYPE_QUATERNION,
			true,
			false
		)
	end]]

	self:UpdateTrackingState()

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:SetTrackedDevice(tdC)
	self.m_trackedDevice = tdC
end
function Component:GetTrackedDevice()
	return self.m_trackedDevice
end
ents.register_component("pfm_vr_tracked_device", Component, "vr", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
