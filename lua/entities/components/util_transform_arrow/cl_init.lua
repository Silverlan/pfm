--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_gizmo.lua")

include_component("click")

util.register_class("ents.UtilTransformArrowComponent", BaseEntityComponent)

include("model.lua")
include("gizmo.lua")

local Component = ents.UtilTransformArrowComponent
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
Component:RegisterMember("Axis", udm.TYPE_UINT8, Component.AXIS_X, {
	onChange = function(self)
		self:UpdateLine()
	end,
}, ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT)
Component:RegisterMember(
	"Selected",
	udm.TYPE_BOOLEAN,
	false,
	{},
	bit.bor(defaultMemberFlags, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER)
)
Component:RegisterMember(
	"Relative",
	udm.TYPE_BOOLEAN,
	false,
	{},
	bit.bor(defaultMemberFlags, ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER)
)
Component:RegisterMember("Type", udm.TYPE_UINT8, Component.TYPE_TRANSLATION, {
	onChange = function(self)
		self:UpdateLine()
	end,
}, ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT)
Component:RegisterMember("Space", udm.TYPE_UINT8, ents.UtilTransformComponent.SPACE_WORLD, {}, defaultMemberFlags)
Component:RegisterMember("AxisGuidesEnabled", udm.TYPE_BOOLEAN, true, {
	onChange = function(self)
		self:UpdateAxisGuides()
	end,
}, defaultMemberFlags)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_COLOR)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local clickC = self:AddEntityComponent(ents.COMPONENT_CLICK)
	self:AddEntityComponent(ents.COMPONENT_BVH)
	self:AddEntityComponent("pfm_overlay_object")

	self:BindEvent(ents.ClickComponent.EVENT_ON_CLICK, "OnClick")
	-- self:BindEvent(ents.RenderComponent.EVENT_ON_UPDATE_RENDER_DATA,"UpdateScale")
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

	renderC:SetExemptFromOcclusionCulling(true)
	renderC:SetDepthPassEnabled(false)
	renderC:SetDepthBias(185, 180)

	clickC:SetPriority(100)
end
function Component:SetCamera(cam)
	self.m_cam = cam
end
function Component:UpdateScale()
	local cam = self.m_cam
	if util.is_valid(cam) == false then
		cam = game.get_render_scene_camera()
	end
	if util.is_valid(cam) == false then
		return
	end
	local entCam = cam:GetEntity()
	local plane = math.Plane(entCam:GetForward(), 0)
	plane:MoveToPos(entCam:GetPos())

	local ent = self:GetEntity()
	local pos = ent:GetPos()
	local p = pos:ProjectToPlane(plane:GetNormal(), plane:GetDistance())
	local d = pos:Distance(p)

	d = d * cam:GetFOVRad() * 0.01 -- Resize according to distance to camera
	ent:SetScale(Vector(d, d, d))

	if util.is_valid(self.m_debugLine) == false then
		return
	end
	local pose = self:GetBasePose()
	if pose == nil then
		return
	end
	self.m_debugLine:SetPos(self:GetEntity():GetPos())
	self.m_debugLine:SetRotation(self:GetEntity():GetRotation() * EulerAngles(0, -90, 0):ToQuaternion())
end
function Component:UpdateAxisGuides()
	if self:GetAxisGuidesEnabled() == false then
		util.remove(self.m_debugLine)
		return
	end
	self:UpdateLine()
end
function Component:UpdateLine()
	util.remove(self.m_debugLine)
	if self:GetEntity():IsSpawned() == false or self:GetAxisGuidesEnabled() == false then
		return
	end
	local axis = self:GetAxis()
	if
		self:GetType() ~= Component.TYPE_TRANSLATION
		or (axis ~= Component.AXIS_X and axis ~= Component.AXIS_Y and axis ~= Component.AXIS_Z)
	then
		return
	end
	local colC = self:GetEntity():GetComponent(ents.COMPONENT_COLOR)
	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor((colC ~= nil) and Color(colC:GetColor()) or Color.White)
	self.m_debugLine = debug.draw_line(Vector(-1000, 0, 0), Vector(1000, 0, 0), drawInfo)
end
function Component:OnEntitySpawn()
	self:UpdateAxis()
	self:UpdateLine()
end

function Component:OnRemove()
	util.remove(self.m_elLine)
	util.remove(self.m_cbOnMouseRelease)
	util.remove(self.m_debugLine)
end

if util.get_class_value(Component, "SetAxisBase") == nil then
	Component.SetAxisBase = Component.SetAxis
end
function Component:SetAxis(axis)
	Component.SetAxisBase(self, axis)
	self:UpdateAxis()
end

if util.get_class_value(Component, "SetTypeBase") == nil then
	Component.SetTypeBase = Component.SetType
end
function Component:SetType(type)
	Component.SetTypeBase(self, type)
	self:UpdateModel()
end

if util.get_class_value(Component, "SetSpaceBase") == nil then
	Component.SetSpaceBase = Component.SetSpace
end
function Component:SetSpace(space)
	Component.SetSpaceBase(self, space)
	self:UpdatePose()
end

function Component:GetTargetEntity()
	local entParent = self.m_transformComponent:GetEntity()
	if entParent == nil then
		local attC = self:GetEntity():GetComponent(ents.COMPONENT_ATTACHABLE)
		entParent = (attC ~= nil) and attC:GetParent() or nil
	end
	return entParent
end

function Component:GetBasePose()
	if util.is_valid(self.m_transformComponent) == false then
		return
	end
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
	if space == ents.UtilTransformComponent.SPACE_LOCAL or self:GetType() == Component.TYPE_SCALE then
		pose = entParent:GetPose()
	elseif space == ents.UtilTransformComponent.SPACE_WORLD then
		pose:SetOrigin(entParent:GetPos())
	elseif space == ents.UtilTransformComponent.SPACE_VIEW then
		pose = entParent:GetPose()
		pose:SetRotation(entRef:GetRotation())
	end
	return pose
end

function Component:UpdateRotation()
	local pose = self:GetBasePose()
	if pose == nil then
		return
	end
	pose = math.Transform(pose:GetOrigin(), pose:GetRotation()) -- Get rid of scale
	local axis = self:GetAxis()
	local rot = Quaternion()
	local entParent = self:GetTargetEntity()

	if self:GetType() == Component.TYPE_TRANSLATION or self:GetType() == Component.TYPE_SCALE then
		if axis == Component.AXIS_X then
			rot = rot * EulerAngles(0, 90, 0):ToQuaternion()
		elseif axis == Component.AXIS_Y then
			rot = rot * EulerAngles(-90, 0, 0):ToQuaternion()
		elseif axis == Component.AXIS_XY then
			rot = rot * EulerAngles(-90, 0, 0):ToQuaternion()
		elseif axis == Component.AXIS_YZ then
			rot = rot * EulerAngles(-90, -90, 0):ToQuaternion()
		elseif axis == Component.AXIS_XZ then
			rot = rot * EulerAngles(0, 0, 0):ToQuaternion()
		end
	else
		--if(self:GetSpace() ~= ents.UtilTransformComponent.SPACE_WORLD) then rot = entParent:GetRotation() end
		if axis == Component.AXIS_X then
			rot = rot * EulerAngles(0, 0, 90):ToQuaternion()
		elseif axis == Component.AXIS_Z then
			rot = rot * EulerAngles(90, 0, 0):ToQuaternion()
		end
	end
	pose:RotateLocal(rot)
	local ent = self:GetEntity()
	ent:SetPose(pose)
end

function Component:UpdatePose()
	self:UpdateRotation()
	local ent = self:GetEntity()
	local attC = ent:AddComponent(ents.COMPONENT_ATTACHABLE)
	if attC ~= nil then
		local attInfo = ents.AttachableComponent.AttachmentInfo()
		attInfo.flags = bit.bor(
			ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME,
			ents.AttachableComponent.FATTACHMENT_MODE_POSITION_ONLY
		)
		local parentBone = self.m_transformComponent:GetParentBone()
		local entParent = self:GetTargetEntity()
		if util.is_valid(entParent) then
			if parentBone == nil then
				attC:AttachToEntity(entParent, attInfo)
			else
				attC:AttachToBone(entParent, parentBone, attInfo)
			end
		end
	end
end

function Component:SetUtilTransformComponent(c)
	self.m_transformComponent = c
	self:UpdatePose()
end
function Component:GetBaseUtilTransformComponent()
	return util.is_valid(self.m_transformComponent) and self.m_transformComponent or nil
end
local axisColors = {
	[Component.AXIS_X] = "intenseRed",
	[Component.AXIS_Y] = "intenseGreen",
	[Component.AXIS_Z] = "intenseBlue",
	[Component.AXIS_XY] = "yellow",
	[Component.AXIS_XZ] = "pink",
	[Component.AXIS_YZ] = "turquoise",
	[Component.AXIS_XYZ] = "white",
}
function Component:UpdateColor()
	local axis = self:GetAxis()
	local colC = self:GetEntity():GetComponent(ents.COMPONENT_COLOR)
	if colC ~= nil then
		local col = pfm.get_color_scheme_color(axisColors[axis])
		if self:IsSelected() then
			if col == Color.White then
				col = Color(128, 128, 128, 255)
			else
				col = col:Lerp(Color.White, 0.25)
			end
		end
		colC:SetColor(col)
	end
	self:UpdateLine()
end
function Component:UpdateAxis()
	local ent = self:GetEntity()
	if ent:IsSpawned() == false then
		return
	end
	self:UpdateColor()
	self:UpdateModel()
end
function Component:UpdateModel()
	local ent = self:GetEntity()
	if ent:IsSpawned() == false then
		return
	end
	local mdl
	if self:GetType() == Component.TYPE_TRANSLATION then
		local axis = self:GetAxis()
		if axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z then
			mdl = self:GetArrowModel()
		elseif axis == Component.AXIS_XY or axis == Component.AXIS_XZ or axis == Component.AXIS_YZ then
			mdl = self:GetPlaneModel()
		else
			mdl = self:GetBoxModel()
		end
	elseif self:GetType() == Component.TYPE_SCALE then
		mdl = self:GetScaleModel()
	else
		mdl = self:GetDiskModel()
	end
	if mdl == ent:GetModel() then
		return
	end
	ent:SetModel(mdl)
end
function Component:GetReferenceAxis()
	return self:GetAxis()
end
function Component:OnTick(dt)
	self:UpdateScale() -- TODO: This doesn't belong here, move it to a render callback
	if self:IsSelected() ~= true then
		return
	end
	local ent = self:GetEntity()
	local clickC = ent:GetComponent(ents.COMPONENT_CLICK)
	local transformC = self:GetBaseUtilTransformComponent()
	if util.is_valid(transformC) == false or util.is_valid(clickC) == false then
		return
	end
	self:ApplyTransform()
end
function Component:ToLocalSpace(pos)
	local transformC = self:GetBaseUtilTransformComponent()
	if transformC == nil then
		return pos
	end
	return transformC:GetEntity():GetPose():GetInverse() * pos
end
function Component:ToGlobalSpace(pos)
	local transformC = self:GetBaseUtilTransformComponent()
	if transformC == nil then
		return pos
	end
	return transformC:GetEntity():GetPose() * pos
end
function Component:OnClick(action, pressed, hitPos)
	if action ~= input.ACTION_ATTACK then
		return util.EVENT_REPLY_UNHANDLED
	end
	if pressed then
		self:StartTransform(hitPos)
	else
		self:StopTransform()
	end
	return util.EVENT_REPLY_HANDLED
end
function Component:GetAffectedAxes()
	local axis = self:GetAxis()
	if axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z then
		return { axis }
	end
	if axis == Component.AXIS_XY then
		return { Component.AXIS_X, Component.AXIS_Y }
	end
	if axis == Component.AXIS_XZ then
		return { Component.AXIS_X, Component.AXIS_Z }
	end
	if axis == Component.AXIS_YZ then
		return { Component.AXIS_Y, Component.AXIS_Z }
	end
	if axis == Component.AXIS_XYZ then
		return { Component.AXIS_X, Component.AXIS_Y, Component.AXIS_Z }
	end
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

function Component:SetReferenceEntity(ent, boneId)
	self.m_refEnt = ent
	self:UpdatePose()
end

function Component:GetReferenceEntity()
	return self.m_refEnt
end

function Component.apply_distance_transform(factor)
	for ent, c in ents.citerator(ents.COMPONENT_UTIL_TRANSFORM_ARROW) do
		if c:IsActive() and c:GetAxis() == Component.AXIS_XYZ then
			local tgt = c:GetTargetEntity()
			local cam = ents.ClickComponent.get_camera()
			local transformC = c:GetBaseUtilTransformComponent()
			if util.is_valid(tgt) and util.is_valid(cam) and util.is_valid(transformC) then
				local pos = tgt:GetPos()
				pos = pos + cam:GetEntity():GetForward() * factor

				local offset = cam:GetEntity():GetForward() * factor
				c.m_gizmo.m_interaction.click_offset = c.m_gizmo.m_interaction.click_offset + offset
				c.m_gizmo.m_interaction.initial_pose:SetOrigin(
					c.m_gizmo.m_interaction.initial_pose:GetOrigin() + offset
				)
			end
			break
		end
	end
end

ents.COMPONENT_UTIL_TRANSFORM_ARROW = ents.register_component("util_transform_arrow", Component)
Component.EVENT_ON_TRANSFORM_START =
	ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM_ARROW, "on_transform_start")
Component.EVENT_ON_TRANSFORM_END =
	ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM_ARROW, "on_transform_end")

-----------------

console.register_command("pfm_transform_distance", function(pl, ...)
	local pm = tool.get_filmmaker()
	if util.is_valid(pm) == false then
		return
	end
	local args = { ... }
	Component.apply_distance_transform((args[1] == "in") and 1.0 or -1.0)
end)
