--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.IkSolver",BaseEntityComponent)

Component:RegisterMember("IkRig",ents.MEMBER_TYPE_ELEMENT,"",{
	onChange = function(self)
		self:UpdateIkRig()
	end,
	flags = ents.ComponentInfo.MemberInfo.FLAG_MEMBER_CONTROLLER_BIT
},bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT))

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:UpdateIkRig()
	local mdl = self:GetEntity():GetModel()
	local skel = mdl:GetSkeleton()
	self.m_skipUdm = true
	for _,bone in ipairs(self:GetIkRig():Get("bones"):GetArrayValues()) do
		local boneId = skel:LookupBone(bone:GetValue("name",udm.TYPE_STRING))
		if(boneId ~= -1) then
			local pose = mdl:GetReferencePose():GetBonePose(boneId)
			local ikBone = self:AddSimpleBone(boneId)
			if(ikBone ~= nil) then
				local locked = bone:GetValue("locked",udm.TYPE_BOOLEAN)
				ikBone:SetPinned(locked)
			end
		end
	end
	for _,handle in ipairs(self:GetIkRig():Get("handles"):GetArrayValues()) do
		local boneId = skel:LookupBone(handle:GetValue("bone",udm.TYPE_STRING))
		if(boneId ~= -1) then
			local type = handle:GetValue("type",udm.TYPE_STRING)
			if(type == "drag") then self:AddDragControl(boneId)
			else self:AddStateControl(boneId) end
		end
	end
	for _,constraint in ipairs(self:GetIkRig():Get("constraints"):GetArrayValues()) do
		local bone0 = constraint:GetValue("bone0",udm.TYPE_STRING)
		local bone1 = constraint:GetValue("bone1",udm.TYPE_STRING)
		if(bone0 ~= nil and bone1 ~= nil) then
			local boneId0 = skel:LookupBone(bone0)
			local boneId1 = skel:LookupBone(bone1)
			if(boneId0 ~= -1 and boneId1 ~= -1) then
				local minLimits = EulerAngles(-90,-90,-0.5)
				local maxLimits = EulerAngles(90,90,0.5)
				self:AddBallSocketJoint(boneId0,boneId1,minLimits,maxLimits)
			end
		end
	end
	self.m_skipUdm = nil
end
function Component:OnEntitySpawn()
	self:GetIkRig():AddArray("bones",0,udm.TYPE_ELEMENT)
	self:GetIkRig():AddArray("constraints",0,udm.TYPE_ELEMENT)
	self:GetIkRig():AddArray("handles",0,udm.TYPE_ELEMENT)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	self:InitializeSolver()
end
function Component:ClearBoneModels()
	if(self.m_bones == nil) then return end
	for _,boneData in ipairs(self.m_bones) do
		util.remove(boneData.entity)
	end
end
function Component:OnRemove()
	self:ClearBoneModels()
end
function Component:InitializeSolver()
	self:ClearBoneModels()
	local solver = ik.Solver(100,10)
	self.m_solver = solver
	self.m_relationships = {}
	self.m_bones = {}
	self.m_boneIdToIkBoneId = {}
	self.m_ikBoneIdToBoneId = {}
	self.m_handleControls = {}
	self:ClearMembers()
	self:OnMembersChanged()

	self:BroadcastEvent(Component.EVENT_INITIALIZE_SOLVER,{solver})

	self:UpdateEffector()
end
function Component:GetReferenceBonePose(boneId)
	local mdl = self:GetEntity():GetModel()
	local ref = mdl:GetReferencePose()
	return ref:GetBonePose(boneId)
end
function Component:GetDirectionFromBoneParent(childBoneId)
	local mdl = self:GetEntity():GetModel()
	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()

	local bone = skeleton:GetBone(childBoneId)
	local parentId = bone:GetParent():GetID()
	local poseParent = ref:GetBonePose(parentId)
	local pose = ref:GetBonePose(childBoneId)
	local n = pose:GetOrigin() -poseParent:GetOrigin()
	n:Normalize()
	return n
end
function Component:AddBallSocketJoint(boneId0,boneId1,minLimits,maxLimits)
	local rotBone0 = self:GetReferenceBonePose(boneId0):GetRotation()
	local rotBone1 = self:GetReferenceBonePose(boneId1):GetRotation()

	-- The IK system only allows us to specify a general swing limit (in any direction). Since we want to be able to specify it in each
	-- direction independently, we have to shift the rotation axes accordingly.
	local rotBone1WithOffset = rotBone1 *EulerAngles(-(maxLimits.y +minLimits.y),-(maxLimits.p +minLimits.p),-(maxLimits.r +minLimits.r)):ToQuaternion()

	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])

	-- BallSocket is required to ensure the distance and rotation to the parent is locked
	self.m_solver:AddBallSocketJoint(bone0,bone1,bone1:GetPos())

	-- Revolute joint to lock rotation to a single axis
	--self.m_solver:AddRevoluteJoint(bone0,bone1,rotBone0:GetUp()) -- Test

	-- Apply the swing limit
	--self.m_solver:AddSwingLimit(bone0,bone1,rotBone1WithOffset:GetForward(),rotBone1:GetForward(),math.rad(maxLimits.y -minLimits.y)):SetRigidity(16)
	--self.m_solver:AddSwingLimit(bone0,bone1,rotBone1:GetForward(),rotBone1:GetForward(),math.rad(45)):SetRigidity(16)
	debug.draw_line((self:GetReferenceBonePose(boneId1)):GetOrigin(),(self:GetReferenceBonePose(boneId1)):GetOrigin() +rotBone1:GetUp() *-200)
	self.m_solver:AddEllipseSwingLimit(bone0,bone1,rotBone1WithOffset:GetForward(),rotBone1:GetForward(),rotBone1WithOffset:GetUp(),math.rad(maxLimits.p -minLimits.p),math.rad(maxLimits.y -minLimits.y)):SetRigidity(1000)

	self.m_solver:AddTwistLimit(bone0,bone1,rotBone1WithOffset:GetForward(),rotBone1:GetForward(),math.rad(maxLimits.r -minLimits.r)):SetRigidity(1000)

	if(self.m_skipUdm ~= true) then
		local mdl = self:GetEntity():GetModel()
		local skeleton = mdl:GetSkeleton()
		local udmConstraints = self:GetIkRig():Get("constraints")
		udmConstraints:Resize(udmConstraints:GetSize() +1)
		local udmConstraint = udmConstraints:Get(udmConstraints:GetSize() -1)
		udmConstraint:SetValue("bone0",udm.TYPE_STRING,skeleton:GetBone(boneId0):GetName())
		udmConstraint:SetValue("bone1",udm.TYPE_STRING,skeleton:GetBone(boneId1):GetName())
	end
	--self:GetIkRig():AddArray("constraints",udm.TYPE_ELEMENT)

	--[[local pose0 = self:GetReferenceBonePose(boneId0)
	local pose1 = self:GetReferenceBonePose(boneId1)
	local rot = pose0:GetRotation()
	local angOffset = (maxLimits -minLimits) /2.0
	rot = rot *angOffset:ToQuaternion()

	local swingSpan = math.max(
		maxLimits.p -minLimits.p,
		maxLimits.y -minLimits.y
	)
	local twistSpan = maxLimits.r -minLimits.r

	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])
	self.m_solver:AddBallSocketJoint(bone0,bone1,pose0:GetOrigin())

	local axis = rot:GetForward()
	--self.m_solver:AddSwingLimit(bone0,bone1,axis,(pose1:GetOrigin() -pose0:GetOrigin()):GetNormal(),math.rad(10)):SetRigidity(1000)
]]
	-- TODO: Add twist limit
end
function Component:AddHingeConstraint(boneId0,boneId1,min,max)
	local rotBone0 = self:GetReferenceBonePose(boneId0):GetRotation()
	local rotBone1 = self:GetReferenceBonePose(boneId1):GetRotation()

	-- The IK system only allows us to specify a general swing limit (in any direction). Since we want to be able to specify it in each
	-- direction independently, we have to shift the rotation axes accordingly.
	local rotBone1WithOffset = rotBone1 *EulerAngles(-(max +min),0,0):ToQuaternion()

	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])

	-- BallSocket is required to ensure the distance and rotation to the parent is locked
	self.m_solver:AddBallSocketJoint(bone0,bone1,bone1:GetPos())

	-- Revolute joint to lock rotation to a single axis
	self.m_solver:AddRevoluteJoint(bone0,bone1,rotBone0:GetRight())

	-- Apply the swing limit
	self.m_solver:AddSwingLimit(bone0,bone1,rotBone1WithOffset:GetUp(),rotBone1:GetUp(),math.rad(max -min)):SetRigidity(1000)

--[[
	local rotBone0 = self:GetReferenceBonePose(boneId0):GetRotation()
	local rotBone1 = self:GetReferenceBonePose(boneId1):GetRotation()

	-- TODO: This does not belong here
	rotBone0 = self:GetEntity():GetPose() *rotBone0
	rotBone1 = self:GetEntity():GetPose() *rotBone1

	-- The IK system only allows us to specify a general swing limit (in any direction). Since we want to be able to specify it in each
	-- direction independently, we have to shift the rotation axes accordingly.
	local rotBone1WithOffset = rotBone1 *EulerAngles(0,-(max +min),0):ToQuaternion()

	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])

	-- BallSocket is required to ensure the distance and rotation to the parent is locked
	self.m_solver:AddBallSocketJoint(bone0,bone1,bone1:GetPos())

	-- Revolute joint to lock rotation to a single axis
	self.m_solver:AddRevoluteJoint(bone0,bone1,rotBone0:GetUp())

	-- Apply the swing limit
	self.m_solver:AddSwingLimit(bone0,bone1,rotBone1WithOffset:GetForward(),rotBone1:GetForward(),math.rad(max -min)):SetRigidity(1000)
]]
end
function Component:AddHingeConstraint2(boneId0,boneId1,min,max)
	local rotBone0 = self:GetReferenceBonePose(boneId0):GetRotation()
	local rotBone1 = self:GetReferenceBonePose(boneId1):GetRotation()

	-- The IK system only allows us to specify a general swing limit (in any direction). Since we want to be able to specify it in each
	-- direction independently, we have to shift the rotation axes accordingly.
	local rotBone1WithOffset = rotBone1 *EulerAngles(0,0,-(max +min)):ToQuaternion()

	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])

	-- BallSocket is required to ensure the distance and rotation to the parent is locked
	self.m_solver:AddBallSocketJoint(bone0,bone1,bone1:GetPos())

	-- Revolute joint to lock rotation to a single axis
	self.m_solver:AddRevoluteJoint(bone0,bone1,rotBone0:GetForward())

	-- Apply the swing limit
	self.m_solver:AddSwingLimit(bone0,bone1,rotBone1WithOffset:GetRight(),rotBone1:GetRight(),math.rad(max -min)):SetRigidity(1000)
end
function Component:AddHingeConstraint3(boneId0,boneId1,min,max)
	local rotBone0 = self:GetReferenceBonePose(boneId0):GetRotation()
	local rotBone1 = self:GetReferenceBonePose(boneId1):GetRotation()

	-- The IK system only allows us to specify a general swing limit (in any direction). Since we want to be able to specify it in each
	-- direction independently, we have to shift the rotation axes accordingly.
	local rotBone1WithOffset = rotBone1 *EulerAngles(0,-(max +min),0):ToQuaternion()

	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])

	-- BallSocket is required to ensure the distance and rotation to the parent is locked
	self.m_solver:AddBallSocketJoint(bone0,bone1,bone1:GetPos())

	-- Revolute joint to lock rotation to a single axis
	self.m_solver:AddRevoluteJoint(bone0,bone1,rotBone0:GetUp())

	-- Apply the swing limit
	self.m_solver:AddSwingLimit(bone0,bone1,rotBone1WithOffset:GetRight(),rotBone1:GetRight(),math.rad(max -min)):SetRigidity(1000)
end
function Component:AddFixedConstraint(boneId0,boneId1)
	local bone0 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId0])
	local bone1 = self.m_solver:GetBone(self.m_boneIdToIkBoneId[boneId1])

	local rotBone0 = self:GetReferenceBonePose(boneId0):GetRotation()
	local rotBone1 = self:GetReferenceBonePose(boneId1):GetRotation()

	-- Lock distance and rotation to the parent
	self.m_solver:AddBallSocketJoint(bone0,bone1,bone1:GetPos())

	-- Lock the angles
	self.m_solver:AddAngularJoint(bone0,bone1):SetRigidity(1000)
	-- Lock swing limit to 0
	--self.m_solver:AddSwingLimit(bone0,bone1,self:GetDirectionFromBoneParent(boneId1),self:GetDirectionFromBoneParent(boneId1),math.rad(5)):SetRigidity(1000)

	-- Restrict twist
	--self.m_solver:AddTwistLimit(bone0,bone1,rotBone1:GetForward(),rotBone1:GetForward(),math.rad(5)):SetRigidity(1000)
end
function Component:SetBoneLocked(boneId,locked)
	local ikBone = self:GetIkBone(boneId)
	if(ikBone == nil) then return end
	ikBone:SetPinned(locked)

	for i,boneData in ipairs(self.m_bones) do
		if(boneData.boneId == boneId) then
			local udmBones = self:GetIkRig():Get("bones")
			local udmBone = udmBones:Get(i -1)
			udmBone:SetValue("locked",udm.TYPE_BOOLEAN,locked)
			break
		end
	end
end
function Component:AddSimpleBone(id)
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()
	local bone = skeleton:GetBone(id)
	if(bone == nil) then return end
	local pose = ref:GetBonePose(bone:GetID())
	local ikBone = self:AddBone(bone:GetID(),pose:GetOrigin(),pose:GetRotation(),1,1)
	return ikBone
end
function Component:GetBones() return self.m_bones end
function Component:AddBone(boneId,pos,rot,radius,length,parent)
	local ikBone = self:GetIkBone(boneId)
	if(ikBone ~= nil) then return ikBone end

	local bone = self.m_solver:AddBone(pos,rot,radius,length)
	if(parent ~= nil) then table.insert(self.m_relationships,{parent,bone}) end

	local mdl = game.Model.create_cylinder(radius,length,4)

	local ent = ents.create("prop_dynamic")
	ent:SetModel(mdl)
	ent:Spawn()

	table.insert(self.m_bones,{
		entity = ent,
		bone = bone,
		length = length,
		radius = radius,
		boneId = boneId
	})
	self.m_boneIdToIkBoneId[boneId] = #self.m_bones -1
	self.m_ikBoneIdToBoneId[#self.m_bones -1] = boneId
	if(self.m_skipUdm ~= true) then
		local udmBones = self:GetIkRig():Get("bones")
		udmBones:Resize(udmBones:GetSize() +1)
		local udmBone = udmBones:Get(udmBones:GetSize() -1)
		udmBone:SetValue("name",udm.TYPE_STRING,self:GetEntity():GetModel():GetSkeleton():GetBone(boneId):GetName())
		udmBone:SetValue("locked",udm.TYPE_BOOLEAN,false)
	end
	return bone
end
function Component:GetIkBone(id)
	local ikBoneId = self.m_boneIdToIkBoneId[id]
	if(ikBoneId == nil) then return end
	return self.m_solver:GetBone(ikBoneId)
end
function Component:GetIkBoneId(id)
	return self.m_boneIdToIkBoneId[id]
end
function Component:UpdatePosition()
	--[[local effectorIdx = self:GetEffectorIndex()
	if(self.m_handleControls[effectorIdx] == nil) then return end
	self.m_handleControls[effectorIdx]:SetTargetPosition(self:GetEffectorPos())]]
end
function Component:UpdateRotation()

end
function Component:GetDragControl(boneId)
	return self.m_handleControls[boneId]
end
function Component:UpdateControlPoses()
	--[[local skeleton = self:GetEntity():GetModel():GetSkeleton()
	for boneId,dragControl in pairs(self.m_handleControls) do
		dragControl:SetTargetPosition(self:GetMemberValue("control/" .. skeleton:GetBone(boneId):GetName() .. "/position"))
	end]]
end
function Component:ResetIkBones()
	for _,boneData in ipairs(self.m_bones) do
		local pose = self:GetReferenceBonePose(boneData.boneId)
		boneData.bone:SetPos(pose:GetOrigin())
		boneData.bone:SetRot(pose:GetRotation())
	end
end
function Component:AddControl(boneId,translation,rotation)
	assert((translation and rotation) or (translation and not rotation))
	if(self.m_handleControls[boneId] ~= nil) then return end
	local ikBoneId = self:GetIkBoneId(boneId)
	if(ikBoneId == nil) then return end
	local bone = self.m_solver:GetBone(ikBoneId)
	if(bone == nil) then return end
	local control
	if(not rotation) then control = self.m_solver:AddDragControl(bone)
	else control = self.m_solver:AddStateControl(bone) end
	control:SetTargetPosition(bone:GetPos())
	if(rotation) then control:SetTargetOrientation(bone:GetRot()) end
	self.m_handleControls[boneId] = control

	local name = self:GetEntity():GetModel():GetSkeleton():GetBone(boneId):GetName()
	self:RegisterMember("control/" .. name .. "/position",udm.TYPE_VECTOR3,Vector(),{
		onChange = function(c)
			control:SetTargetPosition(self:GetMemberValue("control/" .. name .. "/position"))
			self.m_updateRequired = true
		end,
		flags = ents.ComponentInfo.MemberInfo.FLAG_OBJECT_SPACE_BIT
	})

	if(rotation) then
		self:RegisterMember("control/" .. name .. "/rotation",udm.TYPE_QUATERNION,Quaternion(),{
			onChange = function(c)
				control:SetTargetOrientation(self:GetMemberValue("control/" .. name .. "/rotation"))
				self.m_updateRequired = true
			end,
			flags = ents.ComponentInfo.MemberInfo.FLAG_OBJECT_SPACE_BIT
		})
	end
	self:RegisterMember("control/" .. name .. "/locked",udm.TYPE_BOOLEAN,false,{
		onChange = function(c)
			if(self.m_solver == nil) then return end
			local bone = self.m_solver:GetBone(ikBoneId)
			if(bone == nil) then return end
			bone:SetPinned(self:GetMemberValue("control/" .. name .. "/locked"))
		end
	})
	-- TODO: Position weight and rotation weight
	self:OnMembersChanged()

	self:SetMemberValue("control/" .. name .. "/position",bone:GetPos())
	if(rotation) then self:SetMemberValue("control/" .. name .. "/rotation",bone:GetRot()) end

	if(self.m_skipUdm ~= true) then
		local udmHandles = self:GetIkRig():Get("handles")
		udmHandles:Resize(udmHandles:GetSize() +1)
		local udmHandle = udmHandles:Get(udmHandles:GetSize() -1)
		udmHandle:SetValue("bone",udm.TYPE_STRING,name)

		if(not rotation) then udmHandle:SetValue("type",udm.TYPE_STRING,"drag")
		else udmHandle:SetValue("type",udm.TYPE_STRING,"state") end
	end
end
function Component:AddDragControl(boneId)
	return self:AddControl(boneId,true,false)
end
function Component:AddStateControl(boneId)
	return self:AddControl(boneId,true,true)
end
function Component:UpdateEffector()
	--[[local effectorIdx = self:GetEffectorIndex()
	if(self.m_handleControls[effectorIdx] == nil) then return end
	self:SetEffectorPos(self.m_handleControls[effectorIdx]:GetTargetPosition())]]
end
function Component:OnTick(dt)
	self:InvokeEventCallbacks(Component.EVENT_UPDATE_IK)
	if(self.m_updateRequired ~= true) then return end
	self.m_updateRequired = nil

	local dbgInfo = debug.DrawInfo()
	dbgInfo:SetColor(Color.Lime)
	dbgInfo:SetDuration(0.1)

	pfm.tag_render_scene_as_dirty()
	--[[local effectorIdx = self:GetEffectorIndex()
	if(self.m_handleControls[effectorIdx] ~= nil) then
		dbgInfo:SetColor(Color.Red)
		local effectorPos = self.m_handleControls[effectorIdx]:GetTargetPosition()
		--debug.draw_line(effectorPos,effectorPos +Vector(0,10,0),dbgInfo)
	end]]

	-- TODO: Reset pose?
	self:UpdateControlPoses()
	self:ResetIkBones()
	for i=1,100 do self.m_solver:Solve() end

	dbgInfo:SetColor(Color.Lime)
	--debug.draw_line(points[1],points[2],dbgInfo)
	
	dbgInfo:SetColor(Color.Aqua)
	--debug.draw_line(self.m_bones[1]:GetPos(),self.m_bones[2]:GetPos(),dbgInfo)

	for _,boneData in ipairs(self.m_bones) do
		if(boneData.entity:IsValid()) then
			local pose = self:GetEntity():GetPose() *math.Transform(boneData.bone:GetPos(),boneData.bone:GetRot() *EulerAngles(90,0,0):ToQuaternion())
			boneData.entity:SetPose(pose)

			local pose = boneData.entity:GetPose()
			--pose:TranslateLocal(Vector(boneData.length,0,0))
			boneData.entity:SetPose(pose)
		end
	end

	--[[if(self.m_handleControls[effectorIdx] ~= nil) then
		dbgInfo:SetColor(Color.Aqua)
		--debug.draw_line(self.m_dragControl:GetTargetPosition() *drawScale,(self.m_dragControl:GetTargetPosition() +Vector(0,1,0)) *drawScale,dbgInfo)
	end]]

	dbgInfo:SetColor(Color.Lime)
	for _,pair in ipairs(self.m_relationships) do
		local pos0 = pair[1]:GetPos()
		local pos1 = pair[2]:GetPos()
		--debug.draw_line(pos0,pos1,dbgInfo)
	end
	dbgInfo:SetColor(Color.White)
	for i=0,self.m_solver:GetBoneCount() -1 do
		local pos = self.m_solver:GetBone(i):GetPos()
		--debug.draw_line(pos *drawScale,(pos +Vector(0.2,0,0)) *drawScale,dbgInfo)
		--debug.draw_line(pos *drawScale,(pos +Vector(0,0.2,0)) *drawScale,dbgInfo)
		--debug.draw_line(pos *drawScale,(pos +Vector(0,0,0.2)) *drawScale,dbgInfo)
	end
end
ents.COMPONENT_IK_SOLVER = ents.register_component("ik_solver",Component)
Component.EVENT_INITIALIZE_SOLVER = ents.register_component_event(ents.COMPONENT_IK_SOLVER,"initialize_solver")
Component.EVENT_UPDATE_IK = ents.register_component_event(ents.COMPONENT_IK_SOLVER,"update_ik")
