include("/shaders/pfm/pfm_gizmo.lua")

include_component("click")

util.register_class("ents.UtilTransformArrowComponent",BaseEntityComponent)

local Component = ents.UtilTransformArrowComponent
Component.TYPE_TRANSLATION = 0
Component.TYPE_ROTATION = 1

local defaultMemberFlags = bit.band(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,bit.bnot(bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_BIT_KEY_VALUE,ents.BaseEntityComponent.MEMBER_FLAG_BIT_INPUT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_OUTPUT)))
Component:RegisterMember("Axis",util.VAR_TYPE_UINT8,math.AXIS_X,ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,1)
Component:RegisterMember("Selected",util.VAR_TYPE_BOOL,false,bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER),1)
Component:RegisterMember("Relative",util.VAR_TYPE_BOOL,false,bit.bor(defaultMemberFlags,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER),1)
Component:RegisterMember("Type",util.VAR_TYPE_UINT8,Component.TYPE_TRANSLATION,ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,1)
Component:RegisterMember("Space",util.VAR_TYPE_UINT8,ents.UtilTransformComponent.SPACE_WORLD,defaultMemberFlags,1)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_COLOR)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_CLICK)

	self:BindEvent(ents.ClickComponent.EVENT_ON_CLICK,"OnClick")
	-- self:BindEvent(ents.RenderComponent.EVENT_ON_UPDATE_RENDER_DATA,"UpdateScale")
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:UpdateScale()
	local cam = game.get_render_scene_camera()
	local d = self:GetEntity():GetPos():Distance(cam:GetEntity():GetPos())
	d = ((d *0.008) ^0.3) *2 -- Roughly try to keep the same size regardless of distance to the camera
	self:GetEntity():SetScale(Vector(d,d,d))
end
function Component:OnEntitySpawn()
	self:UpdateAxis()
end

function Component:OnRemove()
	util.remove(self.m_elLine)
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

function Component:UpdatePose()
	if(util.is_valid(self.m_transformComponent) == false) then return end
	local axis = self:GetAxis()
	local rot = Quaternion() -- c:GetEntity():GetRotation()

	if(self:GetType() == Component.TYPE_TRANSLATION) then
		if(axis == math.AXIS_X) then
			rot = rot *EulerAngles(0,90,0):ToQuaternion()
		elseif(axis == math.AXIS_Y) then
			rot = rot *EulerAngles(-90,0,0):ToQuaternion()
		end
	else
		if(axis == math.AXIS_X) then
			rot = rot *EulerAngles(0,0,90):ToQuaternion()
		elseif(axis == math.AXIS_Z) then
			rot = rot *EulerAngles(90,0,0):ToQuaternion()
		end
	end

	local entParent = self:GetTargetEntity()
	if(util.is_valid(entParent) == false) then return end
	local entRef = self:GetReferenceEntity()
	if(util.is_valid(entRef) == false) then entRef = entParent end

	local pose = phys.Transform()
	local space = self:GetSpace()
	if(space == ents.UtilTransformComponent.SPACE_WORLD) then
		pose:SetOrigin(entParent:GetPos())
	elseif(space == ents.UtilTransformComponent.SPACE_LOCAL) then
		pose = entParent:GetPose()
	elseif(space == ents.UtilTransformComponent.SPACE_VIEW) then
		pose = entParent:GetPose()
		pose:SetRotation(entRef:GetRotation())
	end

	pose:RotateLocal(rot)

	local ent = self:GetEntity()
	ent:SetPose(pose)
	local attC = ent:AddComponent(ents.COMPONENT_ATTACHABLE)
	if(attC ~= nil) then
		local attInfo = ents.AttachableComponent.AttachmentInfo()
		attInfo.flags = bit.bor(ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME,ents.AttachableComponent.FATTACHMENT_MODE_POSITION_ONLY)
		local parentBone = self.m_transformComponent:GetParentBone()
		if(parentBone == nil) then attC:AttachToEntity(entParent,attInfo)
		else attC:AttachToBone(entParent,parentBone,attInfo) end
	end
end

function Component:SetUtilTransformComponent(c)
	self.m_transformComponent = c
	self:UpdatePose()
end
function Component:GetBaseUtilTransformComponent() return util.is_valid(self.m_transformComponent) and self.m_transformComponent or nil end
function Component:UpdateAxis()
	local ent = self:GetEntity()
	if(ent:IsSpawned() == false) then return end
	local axis = self:GetAxis()
	local colC = ent:GetComponent(ents.COMPONENT_COLOR)
	if(colC ~= nil) then
		if(axis == math.AXIS_X) then colC:SetColor(Color.Red)
		elseif(axis == math.AXIS_Y) then colC:SetColor(Color.Lime)
		elseif(axis == math.AXIS_Z) then colC:SetColor(Color.Aqua) end
	end
	self:UpdateModel()
end
function Component:UpdateModel()
	local ent = self:GetEntity()
	if(ent:IsSpawned() == false) then return end
	local mdl
	if(self:GetType() == Component.TYPE_TRANSLATION) then mdl = self:GetArrowModel()
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
	local transformC = self:GetBaseUtilTransformComponent()
	local entTransform = transformC:GetEntity()

	local cam = ents.ClickComponent.get_camera()

	local t = self:GetEntity():GetUp()
	if(self:GetAxis() == math.AXIS_Y) then t = self:GetEntity():GetUp() end

	--local sign = math.sign(cam:GetEntity():GetForward():DotProduct(self:GetEntity():GetUp()))
	local sign = math.sign(cam:GetEntity():GetForward():DotProduct(t))
	-- print(debug.draw_line(self:GetEntity():GetPos(),self:GetEntity():GetPos() +t *100,Color.Red,12))

	if(self:GetType() == Component.TYPE_TRANSLATION) then
		local v = Vector()
		v:Set(self:GetReferenceAxis(),1.0)
		v:Rotate(self.m_moveReferenceRot)

		local dir,z = cam:WorldSpaceToScreenSpaceDirection(v)
		local z = cam:CalcScreenSpaceDistance(self:GetEntity():GetPos())

		local mouseDelta = input.get_cursor_pos() -self.m_moveStartCursorPos

		local dot = dir:DotProduct(mouseDelta)
		local delta = dot *z /400

		local axis = self:GetReferenceAxis()
		local vAxis = Vector()
		vAxis:Set(axis,1.0)
		local offset = vAxis *delta
		if(self:GetSpace() ~= ents.UtilTransformComponent.SPACE_WORLD) then offset:Rotate(self.m_moveReferenceRot) end
		--offset = offset *sign
		--if(axis == math.AXIS_X or axis == math.AXIS_Z) then offset = -offset end

		local newPos = self.m_moveStartTransformPos +offset
		-- print(self.m_moveStartCursorPos)
		transformC:SetAbsTransformPosition(newPos)

		pfm.tag_render_scene_as_dirty()

		local intersectPos = self:GetCursorIntersectionWithAxisPlane()
		if(intersectPos ~= nil) then
			--self.m_moveStartCursorPos = input.get_cursor_pos()


			--[[if(self:IsRelative() == false) then
			local pos = transformC:GetAbsTransformPosition()
			pos = pos +delta

			self.m_moveStartPos = intersectPos
			transformC:SetAbsTransformPosition(pos)
			else
			local pos = transformC:GetTransformPosition()
			pos = pos +delta

			self.m_moveStartPos = intersectPos
			transformC:SetTransformPosition(pos)
			end]]
			--[[local axis = self:GetReferenceAxis()
			local delta = Vector()
			delta:Set(axis,(self:ToLocalSpace(intersectPos) -self:ToLocalSpace(self.m_moveStartPos)):Get(axis))
			print("Relative: ",self:IsRelative())
			if(self:IsRelative()) then
				local parent = transformC:GetParent()
				if(util.is_valid(parent)) then
					delta:Rotate(parent:GetRotation())
				end
			end

			local pos = transformC:GetAbsTransformPosition()
			pos:Set(axis,self:ToLocalSpace(intersectPos):Get(axis))
			debug.draw_line(intersectPos,intersectPos +Vector(0,100,0),Color.Aqua,0.1)
			print("INTERSECT: ",intersectPos)
			pfm.tag_render_scene_as_dirty()]]
			--print("Test: ",intersectPos)
			--pos = pos +delta

			--self.m_moveStartPos = intersectPos
			--transformC:SetAbsTransformPosition(pos)
		end
	else


		local rotationPivot = cam:WorldSpaceToScreenSpace(self:GetEntity():GetPos())
		--print("rotationPivot: ",rotationPivot)

		local posCursor = input.get_cursor_pos()
		local vpData = ents.ClickComponent.get_viewport_data()
		--function  return get_viewport_data() end

		rotationPivot = Vector2(vpData.x +rotationPivot.x *vpData.width,vpData.y +rotationPivot.y *vpData.height)

		if(util.is_valid(self.m_elLine)) then
			self.m_elLine:SetStartPos(Vector2(posCursor.x,posCursor.y))
			self.m_elLine:SetEndPos(rotationPivot)
		end

		posCursor.x = posCursor.x -vpData.x
		posCursor.y = posCursor.y -vpData.y
		rotationPivot.x = rotationPivot.x -vpData.x
		rotationPivot.y = rotationPivot.y -vpData.y

		local startPos = self.m_moveStartCursorPos -Vector2(vpData.x,vpData.y)
		self.m_moveStartCursorPos = input.get_cursor_pos()

		local v0 = (posCursor -rotationPivot):GetNormal()
		local v1 = (startPos -rotationPivot):GetNormal()
		local axis = Vector2(0,1)
		local dcur = v0:DotProduct(axis)
		local dstart = v1:DotProduct(axis)

		local curAng = math.deg(math.atan2(v0.y,v0.x))
		local startAng = math.deg(math.atan2(v1.y,v1.x))
		local diff = math.normalize_angle(curAng -startAng,-180) /180.0
		local cam = game.get_primary_camera()
		diff = diff *sign
		if(self:GetAxis() == math.AXIS_X) then diff = -diff end
		--print()--math.deg(math.acos(dcur)))
		--[[delta = dcur -dstart
		delta = delta *10]]
		local delta = diff


		--local mouseDelta = input.get_cursor_pos() -self.m_moveStartCursorPos
		--print(rotationPivot,mouseDelta)




		local axis = self:GetReferenceAxis()
		local vAxis = Vector()
		if(self:GetSpace() == ents.UtilTransformComponent.SPACE_WORLD) then
			vAxis:Set(axis,1.0)
		else
			vAxis:Set(axis,1.0)
			vAxis:Rotate(self.m_moveReferenceRot)
		end
		local rAxis = Quaternion(vAxis,delta *math.rad(180.0))
		local newRot
		if(self:GetSpace() == ents.UtilTransformComponent.SPACE_WORLD) then newRot = rAxis *self.m_moveStartTransformRot
		else newRot = rAxis *self.m_moveStartTransformRot end
		local newAng = newRot:ToEulerAngles()
		self.m_moveStartTransformRot = newRot
		transformC:SetTransformRotation(newAng)

		--transformC:SetAbsTransformPosition(newPos)

		pfm.tag_render_scene_as_dirty()
		--[[local intersectPos = self:GetCursorIntersectionWithAxisPlane()
		if(intersectPos ~= nil) then
			local cursorAxisAngle = self:GetCursorAxisAngle()
			if(cursorAxisAngle ~= nil) then
				local ang = transformC:GetTransformRotation()
				local axis = self:GetAxis()

				local angAxis = EulerAngles()
				angAxis:Set(axis,cursorAxisAngle -self.m_rotStartAngle)
				local rot = ang:ToQuaternion()
				if(self:IsRelative() == false) then
					rot = angAxis:ToQuaternion() *rot
				else
					rot = rot *rotAxis:ToQuaternion()
				end
				ang = rot:ToEulerAngles()

				self.m_rotStartAngle = cursorAxisAngle
				transformC:SetTransformRotation(ang)
			end
		end]]
	end
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
	if(pressed) then self:StartTransform()
	else self:StopTransform() end
	return util.EVENT_REPLY_HANDLED
end

function Component:StartTransform()
	local intersectPos = self:GetCursorIntersectionWithAxisPlane()
	if(intersectPos == nil) then return util.EVENT_REPLY_UNHANDLED end

	self.m_moveStartCursorPos = input.get_cursor_pos()
	local refRot
	if(util.is_valid(self.m_refEnt)) then
		local attC = self:GetEntity():AddComponent(ents.COMPONENT_ATTACHABLE)
		local animC = self.m_refEnt:GetComponent(ents.COMPONENT_ANIMATED)
		if(attC ~= nil and animC ~= nil) then
			local boneId = attC:GetBone()
			if(boneId ~= nil and boneId ~= -1) then
				refRot = animC:GetGlobalBonePose(boneId):GetRotation()
			end
		end
		refRot = refRot or self.m_refEnt:GetRotation()
	end
	self.m_moveReferenceRot = refRot or Quaternion()
	self.m_moveStartTransformPos = self.m_transformComponent:GetAbsTransformPosition()
	self.m_moveStartTransformRot = self.m_transformComponent:GetEntity():GetRotation()
	if(self:GetType() == Component.TYPE_TRANSLATION) then self.m_moveStartPos = intersectPos
	else self.m_rotStartAngle = self:GetCursorAxisAngle() end
	self:SetSelected(true)
	self:BroadcastEvent(Component.EVENT_ON_TRANSFORM_START)

	util.remove(self.m_elLine)
	local elLine = gui.create("WILine")
	self.m_elLine = elLine

	pfm.tag_render_scene_as_dirty()
end

function Component:StopTransform()
	util.remove(self.m_elLine)
	self:SetSelected(false)
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

local diskModel
function Component:GetDiskModel()
	if(diskModel ~= nil) then return diskModel end
	local mdl = game.create_model()
	local meshGroup = mdl:GetMeshGroup(0)

	local scale = 1.5
	scale = Vector(scale,scale,scale)
	local mesh = game.Model.Mesh.Create()

	local meshDisk = game.Model.Mesh.Sub.CreateRing(7.5,8,true)
	meshDisk:SetSkinTextureIndex(0)
	meshDisk:Scale(scale)
	mesh:AddSubMesh(meshDisk)

	meshGroup:AddMesh(mesh)

	mdl:Update(game.Model.FUPDATE_ALL)
	mdl:AddMaterial(0,"pfm/gizmo")

	diskModel = mdl
	return mdl
end
ents.COMPONENT_UTIL_TRANSFORM_ARROW = ents.register_component("util_transform_arrow",Component)
Component.EVENT_ON_TRANSFORM_START = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM_ARROW,"on_transform_start")
Component.EVENT_ON_TRANSFORM_END = ents.register_component_event(ents.COMPONENT_UTIL_TRANSFORM_ARROW,"on_transform_end")
