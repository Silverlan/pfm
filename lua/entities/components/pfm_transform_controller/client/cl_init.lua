--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PfmTransformController", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent("transform_controller")

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:SetTransformTarget(ent, targetPath)
	local componentName, pathName = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(targetPath))
	local component = (componentName ~= nil) and ent:GetComponent(componentName) or nil
	local memberIndex = (component ~= nil) and component:GetMemberIndex(pathName:GetString()) or nil
	self.m_transformGizmoInfo = {
		targetEntity = ent,
		targetPath = targetPath,
		componentName = componentName,
		propertyName = pathName:GetString(),
		component = component,
		memberIndex = memberIndex,
	}
	self:UpdateTransformGizmoPose(true)

	local cbs = {}
	local function add_event_callback(c, evId, fc)
		local cb = c:AddEventCallback(evId, function(...)
			fc(self, ...)
		end)
		table.insert(cbs, cb)
	end
	if self:GetEntity():HasComponent(ents.COMPONENT_UTIL_TRANSFORM) then
		local utilTrC = self:GetEntity():GetComponent(ents.COMPONENT_UTIL_TRANSFORM)
		add_event_callback(utilTrC, ents.UtilTransformComponent.EVENT_ON_TRANSFORM_START, Component.OnTransformStart)
		add_event_callback(utilTrC, ents.UtilTransformComponent.EVENT_ON_TRANSFORM_END, Component.OnTransformEnd)

		add_event_callback(utilTrC, ents.UtilTransformComponent.EVENT_ON_POSITION_CHANGED, Component.OnPositionChanged)
		add_event_callback(utilTrC, ents.UtilTransformComponent.EVENT_ON_ROTATION_CHANGED, Component.OnRotationChanged)
		add_event_callback(utilTrC, ents.UtilTransformComponent.EVENT_ON_SCALE_CHANGED, Component.OnScaleChanged)
	else
		local trC = self:GetEntity():GetComponent(ents.COMPONENT_TRANSFORM_CONTROLLER)
		add_event_callback(trC, ents.TransformController.EVENT_ON_TRANSFORM_START, Component.OnTransformStart)
		add_event_callback(trC, ents.TransformController.EVENT_ON_TRANSFORM_END, Component.OnTransformEnd)

		add_event_callback(trC, ents.TransformController.EVENT_ON_TRANSFORM_CHANGED, Component.OnTransformChanged)
	end
	self.m_callbacks = cbs
end

function Component:OnTransformChanged(pos, rot, scale)
	if pos ~= nil then
		self:OnPositionChanged()
	end
	if rot ~= nil then
		self:OnRotationChanged()
	end
	if scale ~= nil then
		self:OnScaleChanged()
	end
end

function Component:OnTick(dt)
	if self.m_transformGizmoInfo.isTransforming then
		return
	end
	self:UpdateTransformGizmoPose()
end

function Component:UpdateTransformGizmoPose(updateLastPose)
	local utilTransformC = self:GetEntity():GetComponent(ents.COMPONENT_UTIL_TRANSFORM)
	local ent = self.m_transformGizmoInfo.targetEntity
	local componentName = self.m_transformGizmoInfo.componentName
	local propertyName = self.m_transformGizmoInfo.propertyName
	local lastPose = self.m_transformGizmoInfo.lastPose
	local c = (componentName ~= nil and util.is_valid(ent)) and ent:GetComponent(componentName) or nil
	local idx = (c ~= nil) and c:GetMemberIndex(propertyName) or nil
	local pose = (idx ~= nil) and c:GetTransformMemberPose(idx, math.COORDINATE_SPACE_WORLD) or nil
	local function update_view_rotation()
		if utilTransformC == nil then
			return
		end
		if utilTransformC:GetSpace() ~= ents.TransformController.SPACE_VIEW then
			return
		end
		if utilTransformC:IsRotationEnabled() == false and utilTransformC:IsTranslationEnabled() == false then
			return
		end
		utilTransformC:UpdateRotation()
	end
	if pose == nil or pose == lastPose then
		update_view_rotation()
		return
	end
	self:GetEntity():SetPose(math.Transform(pose:GetOrigin(), pose:GetRotation()))
	update_view_rotation()
	if updateLastPose then
		self.m_transformGizmoInfo.lastPose = pose
	end
end

function Component:OnPositionChanged()
	local pos = self:CalcNewDataPose():GetOrigin()
	local c = self.m_transformGizmoInfo.component
	if util.is_valid(c) == false then
		return
	end
	local idx = self.m_transformGizmoInfo.memberIndex
	if self.m_tmpAnimChannel ~= nil then
		pos = c:ConvertPosToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, pos)
		self.m_tmpAnimChannel:InsertValue(0.0, pos)
	else
		c:SetTransformMemberPos(idx, math.COORDINATE_SPACE_WORLD, pos)
	end
end

function Component:OnRotationChanged()
	local c = self.m_transformGizmoInfo.component
	if util.is_valid(c) == false then
		return
	end
	local idx = self.m_transformGizmoInfo.memberIndex
	local rot = self:CalcNewDataPose():GetRotation()
	if self.m_tmpAnimChannel ~= nil then
		rot = c:ConvertRotToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, rot)
		self.m_tmpAnimChannel:InsertValue(0.0, rot)
	else
		c:SetTransformMemberRot(idx, math.COORDINATE_SPACE_WORLD, rot)
	end
end

function Component:OnScaleChanged()
	local c = self.m_transformGizmoInfo.component
	if util.is_valid(c) == false then
		return
	end
	local idx = self.m_transformGizmoInfo.memberIndex
	local scale = self:CalcNewDataPose():GetScale()
	if self.m_tmpAnimChannel ~= nil then
		scale = c:ConvertScaleToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, scale)
		self.m_tmpAnimChannel:InsertValue(0.0, scale)
	else
		c:SetTransformMemberScale(idx, math.COORDINATE_SPACE_LOCAL, scale)
	end
end

function Component:OnTransformStart()
	local ent = self.m_transformGizmoInfo.targetEntity
	if util.is_valid(ent) == false then
		return
	end
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC == nil then
		return
	end
	local actor = actorC:GetActorData()
	self.m_transformData = {
		actor = actor,
		component = (actor ~= nil) and actor:FindComponent(self.m_transformGizmoInfo.componentName) or nil,
	}

	local component = self.m_transformData.component
	local componentName = self.m_transformGizmoInfo.componentName
	local pathName = self.m_transformGizmoInfo.propertyName
	local c = (componentName ~= nil) and ent:GetComponent(componentName) or nil
	local idx = (c ~= nil) and c:GetMemberIndex(pathName) or nil
	local pose = (idx ~= nil) and c:GetTransformMemberPose(idx, math.COORDINATE_SPACE_WORLD) or nil

	self.m_transformGizmoInfo.isTransforming = true
	self:UpdateAnimationChannelSubstituteValue()
	self:UpdateTransformGizmoPose(true)
	local memberInfo = self:GetMemberInfo()
	local pose = self.m_transformGizmoInfo.startPose
	if memberInfo.type == ents.MEMBER_TYPE_TRANSFORM or memberInfo.type == ents.MEMBER_TYPE_SCALED_TRANSFORM then
		pose = component:GetEffectiveMemberValue(pathName, memberInfo.type)
		pose = c:ConvertTransformMemberPoseToTargetSpace(idx, math.COORDINATE_SPACE_WORLD, pose)
	elseif memberInfo.type == ents.MEMBER_TYPE_QUATERNION or memberInfo.type == ents.MEMBER_TYPE_EULER_ANGLES then
		pose = math.ScaledTransform()
		local rot = component:GetEffectiveMemberValue(pathName, memberInfo.type)
		rot = c:ConvertTransformMemberRotToTargetSpace(idx, math.COORDINATE_SPACE_WORLD, rot)
		pose:SetRotation(rot)
	else
		pose = math.ScaledTransform()
		local pos = component:GetEffectiveMemberValue(pathName, memberInfo.type)
		pos = c:ConvertTransformMemberPosToTargetSpace(idx, math.COORDINATE_SPACE_WORLD, pos)
		pose:SetOrigin(pos)
	end
	self.m_transformGizmoInfo.startPose = pose

	self:InitializeAnimationChannelSubstitute()
end
function Component:OnTransformEnd()
	self.m_transformGizmoInfo.isTransforming = false
	self:RestoreAnimationChannel()

	local ent = self.m_transformGizmoInfo.targetEntity
	local targetPath = self.m_transformGizmoInfo.targetPath
	local componentName = self.m_transformGizmoInfo.componentName
	local pathName = self.m_transformGizmoInfo.propertyName

	local uuid = tostring(ent:GetUuid())

	local c = (componentName ~= nil) and ent:GetComponent(componentName) or nil
	local idx = (c ~= nil) and c:GetMemberIndex(pathName) or nil

	local get_pose_value
	local memberInfo = self:GetMemberInfo()
	if memberInfo.type == udm.TYPE_VECTOR3 then
		get_pose_value = function(pose)
			local pos = pose:GetOrigin()
			pos = c:ConvertPosToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, pos)
			return pos
		end
	else
		get_pose_value = function(pose)
			local rot = pose:GetRotation()
			rot = c:ConvertRotToMemberSpace(idx, math.COORDINATE_SPACE_WORLD, rot)
			return rot
		end
	end

	local pm = pfm.get_project_manager()
	local newDataPose = self:CalcNewDataPose()
	local origDataPose = self.m_transformGizmoInfo.startPose
	local oldVal = get_pose_value(origDataPose)
	local newVal = get_pose_value(newDataPose)

	if oldVal ~= nil and newVal ~= nil then
		pm:ChangeActorPropertyValue(pfm.dereference(uuid), targetPath, memberInfo.type, oldVal, newVal, nil, true)
	end
	self.m_transformGizmoInfo.lastPose = nil
	self.m_transformGizmoInfo.startPose = nil
end

function Component:GetPanimaComponent()
	local ent = self.m_transformGizmoInfo.targetEntity
	if util.is_valid(ent) == false then
		return
	end
	local panimaC = ent:GetComponent(ents.COMPONENT_PANIMA)
	local animManager = (panimaC ~= nil) and panimaC:GetAnimationManager("pfm") or nil
	local player = (animManager ~= nil) and animManager:GetPlayer() or nil
	local anim = (player ~= nil) and player:GetAnimation() or nil
	return panimaC, animManager, player, anim
end

function Component:GetMemberInfo()
	if util.is_valid(self.m_transformGizmoInfo.targetEntity) == false then
		return
	end
	return self.m_transformGizmoInfo.targetEntity:FindMemberInfo(self.m_transformGizmoInfo.targetPath)
end

function Component:InitializeAnimationChannelSubstitute()
	if self.m_restoreAnimChannel ~= nil then
		return
	end

	local ent = self.m_transformGizmoInfo.targetEntity
	local targetPath = self.m_transformGizmoInfo.targetPath

	local memberInfo = ent:FindMemberInfo(targetPath)
	if memberInfo == nil then
		return
	end

	local panimaC = ent:GetComponent(ents.COMPONENT_PANIMA)
	local animManager = (panimaC ~= nil) and panimaC:GetAnimationManager("pfm") or nil
	local player = (animManager ~= nil) and animManager:GetPlayer() or nil
	local anim = (player ~= nil) and player:GetAnimation() or nil

	local channel = (anim ~= nil) and anim:FindChannel(targetPath) or nil
	if channel ~= nil then
		-- The property is animated. In this case, we'll have to replace the animation channel with
		-- a temporary one containing only one animation value as long as the object is being transformed.
		-- This is because, while the object is being moved, we want to update it continuously, but we
		-- don't want to do a full update of the property value yet, because that would be too
		-- expensive. We can perform a cheap update by replacing the animation value in the channel, and
		-- then we'll do the full update once the transformation has stopped.
		local val = panimaC:GetRawPropertyValue(animManager, targetPath, memberInfo.type)
		local cpy = panima.Channel(channel)
		cpy:ClearAnimationData()
		cpy:InsertValue(0.0, val)
		anim:RemoveChannel(channel)
		anim:AddChannel(cpy)
		panimaC:UpdateAnimationChannelSubmitters()
		self.m_restoreAnimChannel = channel
		self.m_tmpAnimChannel = cpy
	end
end

function Component:UpdateAnimationChannelSubstituteValue()
	if self.m_tmpAnimChannel == nil then
		return
	end

	local memberInfo = self:GetMemberInfo()
	if memberInfo == nil then
		return
	end

	local panimaC, animManager = self:GetPanimaComponent()
	if panimaC == nil then
		return
	end
	local val = panimaC:GetRawPropertyValue(animManager, self.m_transformGizmoInfo.targetPath, memberInfo.type)
	self.m_tmpAnimChannel:InsertValue(0.0, val)
end

function Component:RestoreAnimationChannel()
	if self.m_restoreAnimChannel == nil then
		return
	end
	local panimaC, animManager, player, anim = self:GetPanimaComponent()
	anim:RemoveChannel(self.m_tmpAnimChannel)
	anim:AddChannel(self.m_restoreAnimChannel)
	panimaC:UpdateAnimationChannelSubmitters()
	self.m_restoreAnimChannel = nil
	self.m_tmpAnimChannel = nil
end

function Component:CalcNewDataPose()
	local oldPose = self.m_transformGizmoInfo.lastPose
	local newPose = self:GetEntity():GetPose()
	local dtPos = newPose:GetOrigin() - oldPose:GetOrigin()
	local dtRot = oldPose:GetRotation():GetInverse() * newPose:GetRotation()
	local dtScale = newPose:GetScale() - oldPose:GetScale()
	local origDataPose = self.m_transformGizmoInfo.startPose
	return math.ScaledTransform(
		origDataPose:GetOrigin() + dtPos,
		origDataPose:GetRotation() * dtRot,
		origDataPose:GetScale() + dtScale
	)
end

function Component:OnRemove()
	util.remove(self.m_callbacks)
end
ents.COMPONENT_PFM_TRANSFORM_CONTROLLER = ents.register_component("pfm_transform_controller", Component)
