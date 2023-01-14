--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/ik_rig.lua")

local Component = util.register_class("ents.IkSolver",BaseEntityComponent)

Component:RegisterMember("IkRig",ents.MEMBER_TYPE_ELEMENT,"",{
	onChange = function(self)
		self:UpdateIkRig()
	end
},bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT))

Component:RegisterMember("IkRigFile",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		c:UpdateIkRigFile()
	end,
	metaData = {
		rootPath = "scripts/ik_rigs/",
		extensions = util.IkRig.extensions,
		stripExtension = true
	}
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:UpdateIkRigFile()
	local ikRig = util.IkRig.load(self:GetIkRigFile())
	if(ikRig == false) then return end
	self:AddIkSolverByRig(ikRig)
end
function Component:AddIkSolverByRig(rig)
	local mdl = self:GetEntity():GetModel()
	local skeleton = (mdl ~= nil) and mdl:GetSkeleton() or nil
	if(skeleton == nil) then return end
	for _,boneData in ipairs(rig:GetBones()) do
		local boneId = skeleton:LookupBone(boneData.name)
		if(boneId == -1) then return false end
		self:AddSimpleBone(boneId)
		if(boneData.locked) then self:SetBoneLocked(boneId,true) end
	end

	for _,controlData in ipairs(rig:GetControls()) do
		local boneId = skeleton:LookupBone(controlData.bone)
		if(boneId == -1) then return false end
		if(controlData.type == "drag") then
			self:AddDragControl(boneId)
		elseif(controlData.type == "state") then
			self:AddStateControl(boneId)
		end
	end

	for _,constraintData in ipairs(rig:GetConstraints()) do
		local boneId0 = skeleton:LookupBone(constraintData.bone0)
		local boneId1 = skeleton:LookupBone(constraintData.bone1)
		if(boneId0 == -1 or boneId1 == -1) then return false end
		if(constraintData.type == "fixed") then
			self:AddFixedConstraint(boneId0,boneId1)
		elseif(constraintData.type == "hinge") then
			self:AddHingeConstraint(boneId0,boneId1,constraintData.min,constraintData.max)
		elseif(constraintData.type == "ballSocket") then
			self:AddBallSocketJoint(boneId0,boneId1,constraintData.min,constraintData.max)
		end
	end
	-- self:OnMembersChanged()
	return true
end
function Component:AddIkSolverByChain(boneName,chainLength,ikName,offsetPose)
	chainLength = chainLength +1
	ikName = ikName or boneName

	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return false end
	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()

	local ikChain = {}
	local boneId = skeleton:LookupBone(boneName)
	if(boneId == -1) then return false end

	-- TODO: Remove existing solver?

	local bone = skeleton:GetBone(boneId)
	for i=1,chainLength do
		if(bone == nil) then return false end
		table.insert(ikChain,1,bone:GetID())
		bone = bone:GetParent()
	end

	if(#ikChain == 0) then return false end
	offsetPose = offsetPose or math.Transform()

	local rig = util.IkRig()
	for _,id in ipairs(ikChain) do
		local bone = skeleton:GetBone(id)
		rig:AddBone(bone:GetName())
	end

	-- Pin the top-most parent of the chain (e.g. shoulder)
	rig:SetBoneLocked(skeleton:GetBone(ikChain[1]):GetName(),true)

	-- Add handles for all other bones in the chain (e.g. forearm or hand)
	for i=3,#ikChain do
		-- We want to be able to control the rotation of the last element in the chain (the effector), but
		-- not the other elements
		if(i == #ikChain) then rig:AddStateControl(skeleton:GetBone(ikChain[i]):GetName())
		else rig:AddDragControl(skeleton:GetBone(ikChain[i]):GetName()) end
	end

	-- Add generic ballsocket constraints with no twist
	for i=2,#ikChain do
		-- We need to allow some minor twisting to avoid instability
		rig:AddBallSocketConstraint(
			skeleton:GetBone(ikChain[i -1]):GetName(),
			skeleton:GetBone(ikChain[i]):GetName(),
			EulerAngles(-90,-90,-0.5),
			EulerAngles(90,90,0.5)
		)
		--solverC:AddBallSocketJoint(ikChain[i -1],ikChain[i],EulerAngles(-90,-90,-0.5),EulerAngles(90,90,0.5))
	end
	self:AddIkSolverByRig(rig)
	rig:ToUdmData(self:GetIkRig())

			--[[add_hinge_constaint("Bind_LeftUpLeg","Bind_LeftLeg",-10,60)
			add_fixed_constaint("Bind_LeftLeg","Bind_LeftFoot",EulerAngles(-20,-40,-5),EulerAngles(20,10,5))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftFoot"))
			solverC:GetIkBone(skeleton:LookupBone("Bind_LeftUpLeg")):SetPinned(true)]]
	-- TODO: Lock top-most bone
	-- TODO: Add handles for all others
	-- TODO: Ballsocket constraints with no wist?

	--local ikBone = solverC:AddBone(bone:GetID(),get_bone_pos(bone:GetID()), get_bone_rot(bone:GetID()), 1, 1);
	--self:AddIkController(ikName,ikChain,offsetPose)

	--[[local pose = ent:GetPose() *ref:GetBonePose(boneId)
	self:SetMemberValue("effector/" .. ikName .. "/position",pose:GetOrigin())
	self:SetMemberValue("effector/" .. ikName .. "/rotation",pose:GetRotation())]]
	return true
end
function Component:UpdateIkRig()
	local rig = util.IkRig.load_from_udm_data(self:GetIkRig())
	if(rig == false) then return false end
	self:AddIkSolverByRig(rig)
	return true
end
function Component:OnEntitySpawn()
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	self:InitializeSolver()
end
function Component:OnRemove()
end
function Component:InitializeSolver()
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

	table.insert(self.m_bones,{
		bone = bone,
		length = length,
		radius = radius,
		boneId = boneId
	})
	self.m_boneIdToIkBoneId[boneId] = #self.m_bones -1
	self.m_ikBoneIdToBoneId[#self.m_bones -1] = boneId
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
function Component:GetHandle(boneId)
	return self.m_handleControls[boneId]
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
	for i=1,1 do self.m_solver:Solve() end

	dbgInfo:SetColor(Color.Lime)
	--debug.draw_line(points[1],points[2],dbgInfo)
	
	dbgInfo:SetColor(Color.Aqua)
	--debug.draw_line(self.m_bones[1]:GetPos(),self.m_bones[2]:GetPos(),dbgInfo)

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
