--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/gizmo.lua")

local Component = util.register_class("ents.TransformController", BaseEntityComponent)
Component.TYPE_TRANSLATION = 0
Component.TYPE_ROTATION = 1
Component.TYPE_SCALE = 2

Component.AXIS_X = math.AXIS_X
Component.AXIS_Y = math.AXIS_Y
Component.AXIS_Z = math.AXIS_Z
Component.AXIS_XY = 3
Component.AXIS_XZ = 4
Component.AXIS_YZ = 5
Component.AXIS_XYZ = 6

Component.SPACE_WORLD = math.COORDINATE_SPACE_WORLD
Component.SPACE_LOCAL = math.COORDINATE_SPACE_LOCAL
Component.SPACE_VIEW = math.COORDINATE_SPACE_VIEW

local defaultMemberFlags = bit.band(
	ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,
	bit.bnot(
		bit.bor(
			ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,
			ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,
			ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT
		)
	)
)
Component:RegisterMember("Axis", udm.TYPE_UINT8, Component.AXIS_X, {}, ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT)
Component:RegisterMember(
	"Relative",
	udm.TYPE_BOOLEAN,
	false,
	{},
	bit.bor(defaultMemberFlags, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER)
)
Component:RegisterMember(
	"Type",
	udm.TYPE_UINT8,
	Component.TYPE_TRANSLATION,
	{},
	ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT
)
Component:RegisterMember("Space", udm.TYPE_UINT8, Component.SPACE_WORLD, {}, defaultMemberFlags)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_MODEL)

	self:SetTargetEntity(self:GetEntity())
	self:GetReferenceEntity(self:GetEntity())

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:ApplyTransform()
	if self.m_gizmo == nil then
		return
	end
	self:UpdateGizmo()
end

function Component:GetReferenceAxis()
	return self:GetAxis()
end

function Component:GetTargetEntity()
	return self.m_targetEntity
end

function Component:SetTargetEntity(ent)
	self.m_targetEntity = ent
end

function Component:SetReferenceEntity(ent, boneId)
	self.m_refEnt = ent
end

function Component:GetReferenceEntity()
	return self.m_refEnt
end

function Component:GetBasePose()
	local entParent = self:GetTargetEntity()
	if util.is_valid(entParent) == false then
		return
	end
	local entRef = self:GetReferenceEntity()
	if util.is_valid(entRef) == false then
		entRef = entParent
	end

	local pose = math.Transform()
	local space = self:GetSpace()
	if space == Component.SPACE_LOCAL or self:GetType() == Component.TYPE_SCALE then
		pose = entParent:GetPose()
	elseif space == Component.SPACE_WORLD then
		pose:SetOrigin(entParent:GetPos())
	elseif space == Component.SPACE_VIEW then
		pose = entParent:GetPose()
		pose:SetRotation(entRef:GetRotation())
	end
	return pose
end

function Component:GetAffectedAxes()
	local axis = self:GetAxis()
	if
		axis == ents.TransformController.AXIS_X
		or axis == ents.TransformController.AXIS_Y
		or axis == ents.TransformController.AXIS_Z
	then
		return { axis }
	end
	if axis == ents.TransformController.AXIS_XY then
		return { ents.TransformController.AXIS_X, ents.TransformController.AXIS_Y }
	end
	if axis == ents.TransformController.AXIS_XZ then
		return { ents.TransformController.AXIS_X, ents.TransformController.AXIS_Z }
	end
	if axis == ents.TransformController.AXIS_YZ then
		return { ents.TransformController.AXIS_Y, ents.TransformController.AXIS_Z }
	end
	return { ents.TransformController.AXIS_X, ents.TransformController.AXIS_Y, ents.TransformController.AXIS_Z }
end

function Component:GetAxisVector()
	local axis = self:GetReferenceAxis()
	local vAxis = Vector()
	if axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z then
		vAxis:Set(axis, 1.0)
	elseif axis == Component.AXIS_XY then
		vAxis = Vector(0, 0, 1)
	elseif axis == Component.AXIS_XZ then
		vAxis = Vector(0, 1, 0)
	elseif axis == Component.AXIS_YZ then
		vAxis = Vector(1, 0, 0)
	end
	return vAxis
end

function Component:UpdateGizmo(apply)
	if apply == nil then
		apply = true
	end
	local camPos, camDir, vpData = ents.ClickComponent.get_ray_data()
	local startRotation = Quaternion()
	local space = self:GetSpace()
	local localToggle = (space == Component.SPACE_LOCAL or self:IsRelative())
	if localToggle then
		startRotation = self.m_gizmo:GetInitialPose():GetRotation()
	elseif space == Component.SPACE_VIEW then
		startRotation = self.m_gizmoTargetSpaceRotation
	end

	self.m_gizmo:SetRay(camPos, camDir)
	self.m_gizmo:SetCameraPosition(camPos)

	local axis = self:GetAxis()
	local vAxis = self:GetAxisVector()
	local type = self:GetType()
	if type == Component.TYPE_TRANSLATION then
		local localToggle = self:GetSpace() == Component.SPACE_LOCAL
		local pose = math.Transform()
		if localToggle then
			local entTarget = self:GetTargetEntity()
			if util.is_valid(entTarget) then
				pose:SetRotation(entTarget:GetRotation())
			end
		elseif space == Component.SPACE_VIEW then
			local cam = ents.ClickComponent.get_camera()
			if util.is_valid(cam) then
				pose:SetRotation(cam:GetEntity():GetRotation())
			end
		end

		vAxis:Rotate(pose:GetRotation())
	end

	if type == Component.TYPE_TRANSLATION then
		local offset = self.m_gizmoOffset
		local point = self.m_gizmoPose:GetOrigin()
		point = point + offset
		if axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z then
			point = self.m_gizmo:AxisTranslationDragger(vAxis, point)
		elseif axis == Component.AXIS_XY or axis == Component.AXIS_XZ or axis == Component.AXIS_YZ then
			point = self.m_gizmo:PlaneTranslationDragger(vAxis, point)
		else
			local cam = vpData.camera
			local camOrientation = cam:GetEntity():GetRotation()
			local dir = -cam:GetEntity():GetForward()
			point = self.m_gizmo:PlaneTranslationDragger(dir, point)
		end
		point = point - offset
		self.m_gizmoPose:SetOrigin(point)

		local spacing = pfm.get_snap_to_grid_spacing()
		if spacing ~= 0 then
			
			for _, axis in ipairs(self:GetAffectedAxes()) do
				point:Set(axis, math.snap_to_grid(point:Get(axis), spacing))
			end
		end
		if apply then
			self:GetEntity():SetPos(point)
			self:InvokeEventCallbacks(Component.EVENT_ON_TRANSFORM_CHANGED, { point })
		end
	elseif type == Component.TYPE_ROTATION then
		local rot = self.m_gizmoPose:GetRotation()
		rot = self.m_gizmo:AxisRotationDragger(vAxis, Vector(), startRotation, rot)
		self.m_gizmoPose:SetRotation(rot)

		local angSpacing = pfm.get_angular_spacing()
		if angSpacing ~= 0 then
			rot = self.m_gizmoBasePose:GetRotation():GetInverse() * rot
			local ang = rot:ToEulerAngles()
			for _, axis in ipairs(self:GetAffectedAxes()) do
				ang:Set(axis, math.snap_to_grid(ang:Get(axis), angSpacing))
			end
			rot = ang:ToQuaternion()
			rot = self.m_gizmoBasePose:GetRotation() * rot
		end

		if localToggle == false then
			rot = rot * self.m_gizmo:GetInitialPose():GetRotation()
		end
		if apply then
			self:InvokeEventCallbacks(Component.EVENT_ON_TRANSFORM_CHANGED, { nil, rot })
			-- transformC:SetTransformRotation(rot)
		end
	elseif type == Component.TYPE_SCALE then
		local uniform = false
		local scale = self.m_gizmoPose:GetScale()
		scale = self.m_gizmo:AxisScaleDragger(vAxis, self.m_gizmoPose:GetOrigin(), scale, uniform)
		self.m_gizmoPose:SetScale(scale)
		if apply then
			self:InvokeEventCallbacks(Component.EVENT_ON_TRANSFORM_CHANGED, { nil, nil, scale })
			-- transformC:SetTransformScale(scale)
		end
	end
end

function Component:IsActive()
	return (self.m_gizmo ~= nil and self.m_gizmo:IsActive())
end

function Component:GetTargetSpaceRotation()
	local targetSpaceRotation = math.Transform()
	if self:GetSpace() == Component.SPACE_VIEW then
		local cam = ents.ClickComponent.get_camera()
		if util.is_valid(cam) then
			targetSpaceRotation = cam:GetEntity():GetRotation()
		end
	end
	return targetSpaceRotation
end

function Component:OnTick(dt)
	self:ApplyTransform()
end

function Component:StartTransform(hitPos)
	local gizmo = util.Gizmo()
	gizmo:SetActive(true)
	self.m_gizmo = gizmo

	local targetSpaceRotation = self:GetTargetSpaceRotation()
	self.m_gizmoTargetSpaceRotation = targetSpaceRotation
	self.m_gizmoBasePose = self:GetBasePose()

	if hitPos == nil then
		-- Calculate hit position at current cursor intersection with plane
		local axis = self:GetAxisVector()
		axis:Rotate(self.m_gizmoBasePose:GetRotation())
		local plane = math.Plane(axis, 0.0)
		plane:MoveToPos(self:GetEntity():GetPos())

		local camPos, camDir, vpData = ents.ClickComponent.get_ray_data()
		local maxDist = 10000000.0
		local t = intersect.line_with_plane(camPos, camDir * maxDist, plane:GetNormal(), plane:GetDistance())
		if t ~= false then
			hitPos = camPos + camDir * maxDist * t
		end
	end

	local targetEntity = self:GetTargetEntity()
	self.m_gizmoPose = targetEntity:GetPose()
	hitPos = hitPos or self.m_gizmoPose:GetOrigin()
	self.m_gizmoOffset = hitPos - self.m_gizmoPose:GetOrigin()

	gizmo:SetInteractionStart(
		true,
		hitPos,
		math.ScaledTransform(
			targetEntity:GetPos(),
			targetSpaceRotation:GetInverse() * targetEntity:GetRotation(),
			self.m_gizmoPose:GetScale()
		)
	)
	self:UpdateGizmo(false)
	gizmo:SetInteractionStart(false)

	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_START)

	util.remove(self.m_cbOnMouseRelease)
	self.m_cbOnMouseRelease = input.add_callback("OnMouseInput", function(mouseButton, state, mods)
		if mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_RELEASE then
			self:StopTransform()
		end
	end)
end

function Component:OnRemove()
	util.remove(self.m_cbOnMouseRelease)
end

function Component:StopTransform()
	if self.m_gizmo == nil then
		return
	end
	self.m_gizmo = nil

	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_END)
end
ents.register_component("transform_controller", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
Component.EVENT_ON_TRANSFORM_START =
	ents.register_component_event(ents.COMPONENT_TRANSFORM_CONTROLLER, "on_transform_start")
Component.EVENT_ON_TRANSFORM_END =
	ents.register_component_event(ents.COMPONENT_TRANSFORM_CONTROLLER, "on_transform_end")
Component.EVENT_ON_TRANSFORM_CHANGED =
	ents.register_component_event(ents.COMPONENT_TRANSFORM_CONTROLLER, "on_transform_changed")
