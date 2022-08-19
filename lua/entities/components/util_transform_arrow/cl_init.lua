--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_gizmo.lua")
include("/util/gizmo.lua")

include_component("click")

util.register_class("ents.UtilTransformArrowComponent",BaseEntityComponent)

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

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
Component:RegisterMember("Axis",udm.TYPE_UINT8,Component.AXIS_X,{},ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT)
Component:RegisterMember("Selected",udm.TYPE_BOOLEAN,false,{},bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))
Component:RegisterMember("Relative",udm.TYPE_BOOLEAN,false,{},bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))
Component:RegisterMember("Type",udm.TYPE_UINT8,Component.TYPE_TRANSLATION,{},ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT)
Component:RegisterMember("Space",udm.TYPE_UINT8,ents.UtilTransformComponent.SPACE_WORLD,{},defaultMemberFlags)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_COLOR)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_CLICK)
	self:AddEntityComponent(ents.COMPONENT_BVH)
	self:AddEntityComponent("pfm_overlay_object")

	self:BindEvent(ents.ClickComponent.EVENT_ON_CLICK,"OnClick")
	-- self:BindEvent(ents.RenderComponent.EVENT_ON_UPDATE_RENDER_DATA,"UpdateScale")
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)

	renderC:SetExemptFromOcclusionCulling(true)
	renderC:AddToRenderGroup("pfm_editor_overlay")
end
function Component:UpdateScale()
	local cam = game.get_render_scene_camera()
	local d = self:GetEntity():GetPos():Distance(cam:GetEntity():GetPos())
	d = ((d *0.008) ^0.9) *3 -- Roughly try to keep the same size regardless of distance to the camera
	d = 1--2
	self:GetEntity():SetScale(Vector(d,d,d))
end
function Component:OnEntitySpawn()
	self:UpdateAxis()
end

function Component:OnRemove()
	util.remove(self.m_elLine)
	util.remove(self.m_cbOnMouseRelease)
end

if(util.get_class_value(Component,"SetAxisBase") == nil) then Component.SetAxisBase = Component.SetAxis end
function Component:SetAxis(axis)
	Component.SetAxisBase(self,axis)
	self:UpdateAxis()
end

if(util.get_class_value(Component,"SetTypeBase") == nil) then Component.SetTypeBase = Component.SetType end
function Component:SetType(type)
	Component.SetTypeBase(self,type)
	self:UpdateModel()
end

if(util.get_class_value(Component,"SetSpaceBase") == nil) then Component.SetSpaceBase = Component.SetSpace end
function Component:SetSpace(space)
	Component.SetSpaceBase(self,space)
	self:UpdatePose()
end

function Component:GetTargetEntity()
	local entParent = self.m_transformComponent:GetEntity()
	if(entParent == nil) then
		local attC = self:GetEntity():GetComponent(ents.COMPONENT_ATTACHABLE)
		entParent = (attC ~= nil) and attC:GetParent() or nil
	end
	return entParent
end

function Component:GetBasePose()
	if(util.is_valid(self.m_transformComponent) == false) then return end
	local entParent = self:GetTargetEntity()
	if(util.is_valid(entParent) == false) then return end
	local entRef = self:GetReferenceEntity()
	if(util.is_valid(entRef) == false) then entRef = entParent end

	local pose = math.Transform()
	local space = self:GetSpace()
	if(space == ents.UtilTransformComponent.SPACE_LOCAL or self:GetType() == Component.TYPE_SCALE) then
		pose = entParent:GetPose()
	elseif(space == ents.UtilTransformComponent.SPACE_WORLD) then
		pose:SetOrigin(entParent:GetPos())
	elseif(space == ents.UtilTransformComponent.SPACE_VIEW) then
		pose = entParent:GetPose()
		pose:SetRotation(entRef:GetRotation())
	end
	return pose
end

function Component:UpdateRotation()
	local pose = self:GetBasePose()
	if(pose == nil) then return end
	local axis = self:GetAxis()
	local rot = Quaternion()
	local entParent = self:GetTargetEntity()

	if(self:GetType() == Component.TYPE_TRANSLATION or self:GetType() == Component.TYPE_SCALE) then
		if(axis == Component.AXIS_X) then
			rot = rot *EulerAngles(0,90,0):ToQuaternion()
		elseif(axis == Component.AXIS_Y) then
			rot = rot *EulerAngles(-90,0,0):ToQuaternion()
		elseif(axis == Component.AXIS_XY) then
			rot = rot *EulerAngles(-90,0,0):ToQuaternion()
		elseif(axis == Component.AXIS_YZ) then
			rot = rot *EulerAngles(-90,-90,0):ToQuaternion()
		elseif(axis == Component.AXIS_XZ) then
			rot = rot *EulerAngles(0,0,0):ToQuaternion()
		end
	else
		--if(self:GetSpace() ~= ents.UtilTransformComponent.SPACE_WORLD) then rot = entParent:GetRotation() end
		if(axis == Component.AXIS_X) then
			rot = rot *EulerAngles(0,0,90):ToQuaternion()
		elseif(axis == Component.AXIS_Z) then
			rot = rot *EulerAngles(90,0,0):ToQuaternion()
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
	if(attC ~= nil) then
		local attInfo = ents.AttachableComponent.AttachmentInfo()
		attInfo.flags = bit.bor(ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME,ents.AttachableComponent.FATTACHMENT_MODE_POSITION_ONLY)
		local parentBone = self.m_transformComponent:GetParentBone()
		local entParent = self:GetTargetEntity()
		if(util.is_valid(entParent)) then
			if(parentBone == nil) then attC:AttachToEntity(entParent,attInfo)
			else attC:AttachToBone(entParent,parentBone,attInfo) end
		end
	end
end

function Component:SetUtilTransformComponent(c)
	self.m_transformComponent = c
	self:UpdatePose()
end
function Component:GetBaseUtilTransformComponent() return util.is_valid(self.m_transformComponent) and self.m_transformComponent or nil end
local axisColors = {
	[Component.AXIS_X] = "intenseRed",
	[Component.AXIS_Y] = "intenseGreen",
	[Component.AXIS_Z] = "intenseBlue",
	[Component.AXIS_XY] = "yellow",
	[Component.AXIS_XZ] = "pink",
	[Component.AXIS_YZ] = "turquoise",
	[Component.AXIS_XYZ] = "white"
}
function Component:UpdateColor()
	local axis = self:GetAxis()
	local colC = self:GetEntity():GetComponent(ents.COMPONENT_COLOR)
	if(colC ~= nil) then
		local col = pfm.get_color_scheme_color(axisColors[axis])
		if(self:IsSelected()) then
			if(col == Color.White) then col = Color(128,128,128,255)
			else col = col:Lerp(Color.White,0.25) end
		end
		colC:SetColor(col)
	end
end
function Component:UpdateAxis()
	local ent = self:GetEntity()
	if(ent:IsSpawned() == false) then return end
	self:UpdateColor()
	self:UpdateModel()
end
function Component:UpdateModel()
	local ent = self:GetEntity()
	if(ent:IsSpawned() == false) then return end
	local mdl
	if(self:GetType() == Component.TYPE_TRANSLATION) then
		local axis = self:GetAxis()
		if(axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z) then mdl = self:GetArrowModel()
		elseif(axis == Component.AXIS_XY or axis == Component.AXIS_XZ or axis == Component.AXIS_YZ) then mdl = self:GetPlaneModel()
		else mdl = self:GetBoxModel() end
	elseif(self:GetType() == Component.TYPE_SCALE) then mdl = self:GetScaleModel()
	else mdl = self:GetDiskModel() end
	if(mdl == ent:GetModel()) then return end
	ent:SetModel(mdl)
end
function Component:GetReferenceAxis() return self:GetAxis() end
function Component:GetCursorAxisAngle()
	local transformC = self:GetBaseUtilTransformComponent()
	if(transformC == nil) then return end
	local entTransform = transformC:GetEntity()
	local ang = entTransform:GetAngles()
	local axis = self:GetAxis()

	local intersectPos = self:GetCursorIntersectionWithAxisPlane()
	if(intersectPos == nil) then return end
	local pos = intersectPos -self:GetEntity():GetPos()
	local axisAngle = 0.0
	if(axis == math.AXIS_X) then axisAngle = math.atan2(pos.z,pos.y)
	elseif(axis == math.AXIS_Y) then axisAngle = math.atan2(pos.x,pos.z)
	else axisAngle = math.atan2(pos.y,pos.x) end
	return math.deg(axisAngle)
end
function Component:GetCursorIntersectionWithAxisPlane()
	local transformC = self:GetBaseUtilTransformComponent()
	local ent = self:GetEntity()
	local clickC = ent:GetComponent(ents.COMPONENT_CLICK)
	if(transformC == nil or clickC == nil) then return end
	local axis = self:GetAxis()

	local plane
	if(self:GetType() == Component.TYPE_TRANSLATION) then
		if(axis == math.AXIS_X) then
			plane = math.Plane(transformC:GetEntity():GetUp(),ent:GetPos())
		elseif(axis == math.AXIS_Y) then
			plane = math.Plane(-transformC:GetEntity():GetRight(),ent:GetPos())
		else
			plane = math.Plane(transformC:GetEntity():GetUp(),ent:GetPos())
		end
	else
		if(axis == math.AXIS_X) then
			plane = math.Plane(vector.FORWARD,ent:GetPos())
		elseif(axis == math.AXIS_Y) then
			plane = math.Plane(vector.UP,ent:GetPos())
		else
			plane = math.Plane(vector.RIGHT,ent:GetPos())
		end
	end

	local pos,dir = ents.ClickComponent.get_ray_data()
	local maxDist = 32768
	local t = intersect.line_with_plane(pos,dir *maxDist,plane:GetNormal(),plane:GetDistance())
	if(t == false) then return end
	return pos +dir *t *maxDist
end
function Component:OnTick(dt)
	self:UpdateScale() -- TODO: This doesn't belong here, move it to a render callback
	if(self:IsSelected() ~= true) then return end
	local ent = self:GetEntity()
	local clickC = ent:GetComponent(ents.COMPONENT_CLICK)
	local transformC = self:GetBaseUtilTransformComponent()
	if(util.is_valid(transformC) == false or util.is_valid(clickC) == false) then return end
	self:ApplyTransform()
end
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
function Component:ToLocalSpace(pos)
	local transformC = self:GetBaseUtilTransformComponent()
	if(transformC == nil) then return pos end
	return transformC:GetEntity():GetPose():GetInverse() *pos
end
function Component:ToGlobalSpace(pos)
	local transformC = self:GetBaseUtilTransformComponent()
	if(transformC == nil) then return pos end
	return transformC:GetEntity():GetPose() *pos
end
function Component:OnClick(action,pressed,hitPos)
	if(action ~= input.ACTION_ATTACK) then return util.EVENT_REPLY_UNHANDLED end
	if(pressed) then
		self:StartTransform(hitPos)
		util.remove(self.m_cbOnMouseRelease)
		self.m_cbOnMouseRelease = input.add_callback("OnMouseInput",function(mouseButton,state,mods)
			if(mouseButton == input.MOUSE_BUTTON_LEFT and state == input.STATE_RELEASE) then
				self:StopTransform()
			end
		end)
	else self:StopTransform() end
	return util.EVENT_REPLY_HANDLED
end
function Component:GetAxisVector()
	local axis = self:GetReferenceAxis()
	local vAxis = Vector()
	if(axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z) then vAxis:Set(axis,1.0)
	elseif(axis == Component.AXIS_XY) then vAxis = Vector(0,0,1)
	elseif(axis == Component.AXIS_XZ) then vAxis = Vector(0,1,0)
	elseif(axis == Component.AXIS_YZ) then vAxis = Vector(1,0,0) end
	return vAxis
end

function Component:UpdateGizmo()
	local camPos,camDir,vpData = ents.ClickComponent.get_ray_data()
	local startRotation = Quaternion()--self.m_gizmoStartRotation
	local localToggle = self:GetSpace() == ents.UtilTransformComponent.SPACE_LOCAL
	if(localToggle) then startRotation = self.m_gizmoStartRotation end

	self.m_gizmo:SetRay(camPos,camDir)
	self.m_gizmo:SetCameraPosition(camPos)
	local transformC = self:GetBaseUtilTransformComponent()

	local axis = self:GetAxis()
	local vAxis = self:GetAxisVector()
	local type = self:GetType()
	if(type == Component.TYPE_TRANSLATION) then
		local localToggle = self:GetSpace() == ents.UtilTransformComponent.SPACE_LOCAL
		local pose = math.Transform()
		if(localToggle) then pose:SetRotation(self.m_transformComponent:GetEntity():GetRotation()) end
		vAxis:Rotate(pose:GetRotation())
	end

	if(type == Component.TYPE_TRANSLATION) then
		local offset = self.m_gizmoOffset
		self.m_gizmoPoint = self.m_gizmoPoint +offset
		if(axis == Component.AXIS_X or axis == Component.AXIS_Y or axis == Component.AXIS_Z) then
			self.m_gizmoPoint = self.m_gizmo:AxisTranslationDragger(nil,vAxis,self.m_gizmoPoint)
		elseif(axis == Component.AXIS_XY or axis == Component.AXIS_XZ or axis == Component.AXIS_YZ) then
			self.m_gizmoPoint = self.m_gizmo:PlaneTranslationDragger(nil,nil,vAxis,self.m_gizmoPoint)
		else
			local cam = vpData.camera
			local camOrientation = cam:GetEntity():GetRotation()
			local dir = -cam:GetEntity():GetForward()
			self.m_gizmoPoint = self.m_gizmo:PlaneTranslationDragger(nil,nil,dir,self.m_gizmoPoint)
		end
		self.m_gizmoPoint = self.m_gizmoPoint -offset

		transformC:SetAbsTransformPosition(self.m_gizmoPoint)
		self:GetEntity():SetPos(self.m_gizmoPoint)
	elseif(type == Component.TYPE_ROTATION) then
		self.m_gizmoRotation = self.m_gizmo:AxisRotationDragger(nil,nil,vAxis,Vector(),startRotation,self.m_gizmoRotation)

		if(localToggle == false) then transformC:SetTransformRotation(self.m_gizmoRotation *self.m_gizmoStartRotation)
		else transformC:SetTransformRotation(self.m_gizmoRotation) end
	elseif(type == Component.TYPE_SCALE) then
		local uniform = false
		self.m_gizmoScale = self.m_gizmo:AxisScaleDragger(nil,nil,vAxis,self.m_gizmoPoint,self.m_gizmoScale,uniform)

		transformC:SetTransformScale(self.m_gizmoScale)
	end
end
function Component:StartTransform(hitPos)
	local gizmo = util.Gizmo()
	gizmo:SetActive(true)
	self.m_gizmo = gizmo

	self.m_gizmoPoint = self.m_transformComponent:GetEntity():GetPos()
	self.m_gizmoRotation = self.m_transformComponent:GetEntity():GetRotation()
	self.m_gizmoScale = self.m_transformComponent:GetEntity():GetScale()
	self.m_gizmoStartPosition = self.m_transformComponent:GetEntity():GetPos()
	self.m_gizmoStartRotation = self.m_transformComponent:GetEntity():GetRotation()
	self.m_gizmoOffset = hitPos -self.m_gizmoPoint -- Vector()

	gizmo:SetInteractionStart(true,hitPos,math.ScaledTransform(self.m_transformComponent:GetEntity():GetPos(),self.m_transformComponent:GetEntity():GetRotation(),self.m_gizmoScale:Copy()))
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

	pfm.tag_render_scene_as_dirty()
end

function Component:StopTransform()
	util.remove(self.m_elLine)
	util.remove(self.m_cbOnMouseRelease)
	self:SetSelected(false)
	self:UpdateColor()
	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_END)

	pfm.tag_render_scene_as_dirty()
end

local arrowModel
function Component:GetArrowModel()
	if(arrowModel ~= nil) then return arrowModel end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local scale = 1.0
	scale = Vector(scale,scale,scale)
	local mesh = game.Model.Mesh.Create()
	local meshBase = game.Model.Mesh.Sub.CreateCylinder(0.4,16.0,12)
	meshBase:SetSkinTextureIndex(0)
	meshBase:Scale(scale)
	mesh:AddSubMesh(meshBase)

	local meshTip = game.Model.Mesh.Sub.CreateCone(
		1.0, -- startRadius
		5.0, -- length
		0.0, -- endRadius
		12 -- segmentCount
	)
	meshTip:SetSkinTextureIndex(0)
	meshTip:Translate(Vector(0.0,0.0,16.0))
	meshTip:Scale(scale)
	mesh:AddSubMesh(meshTip)


	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0,"pfm/gizmo")

	arrowModel = mdl
	return mdl
end

function Component:SetReferenceEntity(ent,boneId)
	self.m_refEnt = ent
	self:UpdatePose()
end

function Component:GetReferenceEntity() return self.m_refEnt end

local function create_model(subMesh,scale)
	if(type(subMesh) ~= "table") then subMesh = {subMesh} end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	scale = Vector(scale,scale,scale)
	local mesh = game.Model.Mesh.Create()

	for _,sm in ipairs(subMesh) do
		sm:SetSkinTextureIndex(0)
		sm:Scale(scale)
		mesh:AddSubMesh(sm)
	end

	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0,"pfm/gizmo")
	return mdl
end

local diskModel
function Component:GetDiskModel()
	if(diskModel ~= nil) then return diskModel end
	local scale = 1.5
	local mesh = game.Model.Mesh.Sub.CreateRing(7.5,8,true)
	diskModel = create_model(mesh,scale)
	return diskModel
end

local scaleModel
function Component:GetScaleModel()
	if(scaleModel ~= nil) then return scaleModel end
	local scale = 1.0
	local meshScale = 2.0
	local mesh = game.Model.Mesh.Sub.CreateCylinder(0.5 *meshScale,10.0 *meshScale,12)
	local mesh2 = game.Model.Mesh.Sub.CreateCylinder(1 *meshScale,3 *meshScale,12)
	local zOffset = 5
	for i=0,mesh:GetVertexCount() -1 do
		local v = mesh:GetVertexPosition(i)
		v.z = v.z +zOffset
		mesh:SetVertexPosition(i,v)
	end
	for i=0,mesh2:GetVertexCount() -1 do
		local v = mesh2:GetVertexPosition(i)
		v.z = v.z +10 *meshScale +zOffset
		mesh2:SetVertexPosition(i,v)
	end
	scaleModel = create_model({mesh,mesh2},scale)
	return scaleModel
end

local planeModel
function Component:GetPlaneModel()
	if(planeModel ~= nil) then return planeModel end
	local scale = 1.0
	local offset = Vector(5,0,5)
	local meshBox = game.Model.Mesh.Sub.CreateBox(offset +Vector(-3,-0.1,-3),offset +Vector(3,0.1,3))
	planeModel = create_model(meshBox,scale)
	return planeModel
end

local boxModel
function Component:GetBoxModel()
	if(boxModel ~= nil) then return boxModel end
	local scale = 1.0
	local meshBox = game.Model.Mesh.Sub.CreateBox(Vector(-2,-2,-2),Vector(2,2,2))
	boxModel = create_model(meshBox,scale)
	return boxModel
end
ents.COMPONENT_UTIL_TRANSFORM_ARROW = ents.register_component("util_transform_arrow",Component)
Component.EVENT_ON_TRANSFORM_START = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM_ARROW,"on_transform_start")
Component.EVENT_ON_TRANSFORM_END = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM_ARROW,"on_transform_end")
