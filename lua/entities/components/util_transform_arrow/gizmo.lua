--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/gizmo.lua")

local Component = ents.UtilTransformArrowComponent

function Component:ApplyTransform()
	self:UpdateGizmo()

	if(util.is_valid(self.m_elLine)) then
		local vpData = ents.ClickComponent.get_viewport_data()
		if(vpData ~= nil) then
			local cam = ents.ClickComponent.get_camera()
			local rotationPivot = cam:WorldSpaceToScreenSpace(self:GetEntity():GetPos())
			local posCursor = input.get_cursor_pos()
			rotationPivot = Vector2(vpData.x +rotationPivot.x *vpData.width,vpData.y +rotationPivot.y *vpData.height)

			self.m_elLine:SetStartPos(Vector2(posCursor.x,posCursor.y))
			self.m_elLine:SetEndPos(rotationPivot)
			self.m_elLine:SizeToContents()
		end
	end

	pfm.tag_render_scene_as_dirty()
end

function Component:UpdateGizmo()
	local camPos,camDir,vpData = ents.ClickComponent.get_ray_data()
	local startRotation = Quaternion()
	local space = self:GetSpace()
	local localToggle = (space == ents.UtilTransformComponent.SPACE_LOCAL or self:IsRelative())
	if(localToggle) then startRotation = self.m_gizmo:GetInitialPose():GetRotation()
	elseif(space == ents.UtilTransformComponent.SPACE_VIEW) then startRotation = self.m_gizmoTargetSpaceRotation end

	self.m_gizmo:SetRay(camPos,camDir)
	self.m_gizmo:SetCameraPosition(camPos)
	local transformC = self:GetBaseUtilTransformComponent()

	local axis = self:GetAxis()
	local vAxis = self:GetAxisVector()
	local type = self:GetType()
	if(type == Component.TYPE_TRANSLATION) then
		local localToggle = self:GetSpace() == ents.UtilTransformComponent.SPACE_LOCAL or self:IsRelative()
		local pose = math.Transform()
		if(localToggle) then pose:SetRotation(self.m_transformComponent:GetEntity():GetRotation())
		elseif(space == ents.UtilTransformComponent.SPACE_VIEW) then
			local cam = ents.ClickComponent.get_camera()
			if(util.is_valid(cam)) then pose:SetRotation(cam:GetEntity():GetRotation()) end
		end
		
		vAxis:Rotate(pose:GetRotation())
	end

	if(type == Component.TYPE_TRANSLATION) then
		local offset = self.m_gizmoOffset
		local point = self.m_gizmoPose:GetOrigin()
		point = point +offset
		if(axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z) then
			point = self.m_gizmo:AxisTranslationDragger(vAxis,point)
		elseif(axis == Component.AXIS_XY or axis == Component.AXIS_XZ or axis == Component.AXIS_YZ) then
			point = self.m_gizmo:PlaneTranslationDragger(vAxis,point)
		else
			local cam = vpData.camera
			local camOrientation = cam:GetEntity():GetRotation()
			local dir = -cam:GetEntity():GetForward()
			point = self.m_gizmo:PlaneTranslationDragger(dir,point)
		end
		point = point -offset
		self.m_gizmoPose:SetOrigin(point)

		local spacing = pfm.get_snap_to_grid_spacing()
		if(spacing ~= 0) then
			for _,axis in ipairs(self:GetAffectedAxes()) do point:Set(axis,math.snap_to_grid(point:Get(axis),spacing)) end
		end
		transformC:SetAbsTransformPosition(point)
		self:GetEntity():SetPos(point)
	elseif(type == Component.TYPE_ROTATION) then
		local rot = self.m_gizmoPose:GetRotation()
		rot = self.m_gizmo:AxisRotationDragger(vAxis,Vector(),startRotation,rot)
		self.m_gizmoPose:SetRotation(rot)

		local angSpacing = pfm.get_angular_spacing()
		if(angSpacing ~= 0) then
			rot = self.m_gizmoBasePose:GetRotation():GetInverse() *rot
			local ang = rot:ToEulerAngles()
			for _,axis in ipairs(self:GetAffectedAxes()) do ang:Set(axis,math.snap_to_grid(ang:Get(axis),angSpacing)) end
			rot = ang:ToQuaternion()
			rot = self.m_gizmoBasePose:GetRotation() *rot
		end

		if(localToggle == false) then rot = rot *self.m_gizmo:GetInitialPose():GetRotation() end

		transformC:SetTransformRotation(rot)
	elseif(type == Component.TYPE_SCALE) then
		local uniform = false
		local scale = self.m_gizmoPose:GetScale()
		scale = self.m_gizmo:AxisScaleDragger(vAxis,self.m_gizmoPose:GetOrigin(),scale,uniform)
		self.m_gizmoPose:SetScale(scale)

		transformC:SetTransformScale(scale)
	end
end

function Component:IsActive() return (self.m_gizmo ~= nil and self.m_gizmo:IsActive()) end

function Component:GetTargetSpaceRotation()
	local targetSpaceRotation = math.Transform()
	if(self:GetSpace() == ents.UtilTransformComponent.SPACE_VIEW) then
		local cam = ents.ClickComponent.get_camera()
		if(util.is_valid(cam)) then targetSpaceRotation = cam:GetEntity():GetRotation() end
	end
	return targetSpaceRotation
end

function Component:StartTransform(hitPos)
	local gizmo = util.Gizmo()
	gizmo:SetActive(true)
	self.m_gizmo = gizmo

	local targetSpaceRotation = self:GetTargetSpaceRotation()
	self.m_gizmoTargetSpaceRotation = targetSpaceRotation
	self.m_gizmoBasePose = self:GetBasePose()

	if(hitPos == nil) then
		-- Calculate hit position at current cursor intersection with plane
		local axis = self:GetAxisVector()
		axis:Rotate(self.m_gizmoBasePose:GetRotation())
		local plane = math.Plane(axis,0.0)
		plane:MoveToPos(self:GetEntity():GetPos())

		local camPos,camDir,vpData = ents.ClickComponent.get_ray_data()
		local maxDist = 10000000.0
		local t = intersect.line_with_plane(camPos,camDir *maxDist,plane:GetNormal(),plane:GetDistance())
		if(t ~= false) then
			hitPos = camPos +camDir *maxDist *t
		end
	end
		
	self.m_gizmoPose = self.m_transformComponent:GetEntity():GetPose()
	hitPos = hitPos or self.m_gizmoPose:GetOrigin()
	self.m_gizmoOffset = hitPos -self.m_gizmoPose:GetOrigin()

	gizmo:SetInteractionStart(true,hitPos,math.ScaledTransform(self.m_transformComponent:GetEntity():GetPos(),targetSpaceRotation:GetInverse() *self.m_transformComponent:GetEntity():GetRotation(),self.m_gizmoPose:GetScale()))
	self:UpdateGizmo()
	gizmo:SetInteractionStart(false)

	self:SetSelected(true)
	self:UpdateColor()
	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_START)

	util.remove(self.m_elLine)
	if(self:GetType() == Component.TYPE_ROTATION) then
		local elLine = gui.create("WILine")
		self.m_elLine = elLine
	end

	input.set_binding_layer_enabled("pfm_transform",true)
	input.update_effective_input_bindings()
	pfm.tag_render_scene_as_dirty()
end

function Component:StopTransform()
	if(self.m_gizmo == nil) then return end
	self.m_gizmo = nil
	util.remove(self.m_elLine)
	util.remove(self.m_cbOnMouseRelease)

	self:SetSelected(false)
	self:UpdateColor()
	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_END)

	input.set_binding_layer_enabled("pfm_transform",false)
	input.update_effective_input_bindings()
	pfm.tag_render_scene_as_dirty()
end
