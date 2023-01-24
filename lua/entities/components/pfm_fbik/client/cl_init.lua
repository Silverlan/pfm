--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/ik_rig.lua")

include_component("ik_solver")

local Component = util.register_class("ents.PFMFbIk",BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:BindEvent(ents.IkSolver.EVENT_INITIALIZE_SOLVER,"InitializeSolver")
	local ikSolverC = self:AddEntityComponent("ik_solver")

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:BindEvent(ents.AnimatedComponent.EVENT_MAINTAIN_ANIMATIONS,"MaintainAnimations")

	self.m_cbUpdateIk = ikSolverC:AddEventCallback(ents.IkSolver.EVENT_UPDATE_IK,function()
		self:UpdateIk()
	end)
end
function Component:OnRemove()
	util.remove(self.m_cbUpdateIk)
end
function Component:MaintainAnimations()
	-- Disable default skeletal animation playback
	return util.EVENT_REPLY_HANDLED
end
function Component:UpdateIk()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local ikSolverC = self:GetEntity():GetComponent(ents.COMPONENT_IK_SOLVER)
	local mdl = self:GetEntity():GetModel()
	if(ikSolverC == nil) then return end
	for _,boneData in ipairs(ikSolverC:GetBones()) do
		local boneId = boneData.boneId
		local bone = boneData.bone
		if(bone == false) then
			--local pose = animC:GetGlobalBonePose(mdl:GetSkeleton():GetBone(boneId):GetParent():GetID()) *mdl:GetReferencePose():GetBonePose(boneId)
			--animC:SetGlobalBonePose(boneId,pose)
		else
			local pos = bone:GetPos()
			local rot = bone:GetRot()
			local pose = self:GetEntity():GetPose() *math.ScaledTransform(pos,rot)
			--local pose = animC:GetGlobalBonePose(boneId)
			--pose:SetOrigin(pos)
			animC:SetGlobalBonePose(boneId,pose)
		end
	end
end
function Component:AddBone(id)
	local solverC = self:GetEntityComponent(ents.COMPONENT_IK_SOLVER)
	if(solverC == nil) then return end
	return solverC:AddSimpleBone(id)
end
function Component:UpdateIkRig()
	
end
function Component:InitializeSolver(solver)
	--self:GetEntity():SetModel("player/soldier")
	self:GetEntity():PlayAnimation("reference")
	local mdl = self:GetEntity():GetModel()

	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()

	local Bind_HeadId = skeleton:LookupBone("Bind_Head")
	local Bind_NeckId = skeleton:LookupBone("Bind_Neck")
	local Bind_LeftShoulderId = skeleton:LookupBone("Bind_LeftShoulder")
	local Bind_LeftArmId = skeleton:LookupBone("Bind_LeftArm")
	local Bind_LeftForeArmId = skeleton:LookupBone("Bind_LeftForeArm")
	local Bind_LeftHandId = skeleton:LookupBone("Bind_LeftHand")

	local function get_bone_pos(id)
		local pose = ref:GetBonePose(id)
		return pose:GetOrigin()
	end
	local function get_bone_rot(id)
		local pose = ref:GetBonePose(id)
		return pose:GetRotation()
	end
	local function get_bone_axis(id)
		local bone = skeleton:GetBone(id)
		local parentId = bone:GetParent():GetID()
		local poseParent = self:GetEntity():GetPose() *ref:GetBonePose(parentId)
		local pose = self:GetEntity():GetPose() *ref:GetBonePose(id)
		local n = pose:GetOrigin() -poseParent:GetOrigin()
		n:Normalize()
		return n
	end
	local function get_bone_hinge_rot(id)
		local poseParent = self:GetEntity():GetPose() *ref:GetBonePose(id)
		return poseParent:GetRotation()
	end
	local function get_bone_hinge_axis(baseRot)
		return baseRot:GetUp()
	end
	local function get_bone_hinge_axis2(baseRot)
		return baseRot:GetForward()
	end
	local solverC = self:GetEntityComponent(ents.COMPONENT_IK_SOLVER)

	local useModelBones = true

	if(true) then return end

	if(useModelBones == true) then
		if(true) then

			--[[local Bind_LeftArm = solverC:AddBone(Bind_LeftArmId,get_bone_pos(Bind_LeftArmId), get_bone_rot(Bind_LeftArmId), 1, 1);
			local Bind_LeftForeArm = solverC:AddBone(Bind_LeftForeArmId,get_bone_pos(Bind_LeftForeArmId), get_bone_rot(Bind_LeftForeArmId), 1, 1,Bind_LeftArm);
			local Bind_LeftHand = solverC:AddBone(Bind_LeftHandId,get_bone_pos(Bind_LeftHandId), get_bone_rot(Bind_LeftHandId), 1, 1,Bind_LeftForeArm);

			self.m_bones = {
				{Bind_LeftArmId,Bind_LeftArm or false},
				{Bind_LeftForeArmId,Bind_LeftForeArm or false},
				{Bind_LeftHandId,Bind_LeftHand or false}
			}

			--solverC:AddHingeConstraint(Bind_LeftArmId,Bind_LeftForeArmId,-20,50)
			solverC:AddBallSocketJoint(Bind_LeftArmId,Bind_LeftForeArmId,EulerAngles(-20,-5,0),EulerAngles(60,5,0))
			solverC:AddFixedConstraint(Bind_LeftForeArmId,Bind_LeftHandId)]]

			local rig = {
				["Bind_Head"] = {
					type = "ballSocket",
					min = EulerAngles(-45,-50,-45),
					max = EulerAngles(45,50,45)
				},
				["Bind_LeftUpLeg"] = {
					type = "ballSocket",
					min = EulerAngles(-70,-45,-45),
					max = EulerAngles(90,45,45)
				},
				["Bind_LeftLeg"] = {
					type = "hinge",
					min = EulerAngles(-120,0,0),
					max = EulerAngles(20,0,0)
				},
				["Bind_LeftFoot"] = {
					type = "ballSocket",
					min = EulerAngles(-45,-35,-2),
					max = EulerAngles(40,35,2)
				},
				["Bind_RightUpLeg"] = {
					type = "ballSocket",
					min = EulerAngles(-70,-45,-45),
					max = EulerAngles(90,45,45)
				},
				["Bind_RightLeg"] = {
					type = "hinge",
					min = EulerAngles(-120,0,0),
					max = EulerAngles(20,0,0)
				},
				["Bind_RightFoot"] = {
					type = "ballSocket",
					min = EulerAngles(-45,-35,-2),
					max = EulerAngles(40,35,2)
				},
				["Bind_Spine"] = {
					type = "ballSocket",
					min = EulerAngles(-30,-45,-55),
					max = EulerAngles(90,45,55)
				},
				["Bind_Spine1"] = {
					type = "ballSocket",
					min = EulerAngles(-20,-45,-45),
					max = EulerAngles(25,45,45)
				},
				["Bind_Neck"] = {
					type = "ballSocket",
					min = EulerAngles(-45,-30,-40),
					max = EulerAngles(30,30,40)
				},
				["Bind_LeftShoulder"] = {
					type = "ballSocket",
					min = EulerAngles(-70,-80,-20),
					max = EulerAngles(30,40,20)
				},
				["Bind_LeftArm"] = {
					type = "ballSocket",
					min = EulerAngles(-40,-80,-10),
					max = EulerAngles(10,40,10)
				},
				["Bind_LeftForeArm"] = {
					type = "ballSocket",
					min = EulerAngles(-5,-90,-45),
					max = EulerAngles(5,30,10)
				},
				["Bind_LeftHand"] = {
					type = "ballSocket",
					min = EulerAngles(-70,-45,-5),
					max = EulerAngles(40,45,5)
				},
				["Bind_RightShoulder"] = {
					type = "ballSocket",
					min = EulerAngles(-70,-40,-20),
					max = EulerAngles(30,80,20)
				},
				["Bind_RightArm"] = {
					type = "ballSocket",
					min = EulerAngles(-40,-80,-10),
					max = EulerAngles(10,40,10)
				},
				["Bind_RightForeArm"] = {
					type = "ballSocket",
					min = EulerAngles(-5,-30,-10),
					max = EulerAngles(5,90,45)
				},
				["Bind_RightHand"] = {
					type = "ballSocket",
					min = EulerAngles(-70,-45,-5),
					max = EulerAngles(40,45,5)
				}
			}
			self.m_bones = {}
			local function add_bone(bone)
				local ikBone = solverC:AddBone(bone:GetID(),get_bone_pos(bone:GetID()), get_bone_rot(bone:GetID()), 1, 1);

				table.insert(self.m_bones,{
					bone:GetID(),ikBone
				})

				for id,child in pairs(bone:GetChildren()) do
					add_bone(child)
				end
			end
			for boneId,bone in pairs(skeleton:GetRootBones()) do
				add_bone(bone)
			end

			local boneMap = {}
			local limitScale = 1
			local function add_hinge_constaint(parentName,name,min,max)
				solverC:AddHingeConstraint(skeleton:LookupBone(parentName),skeleton:LookupBone(name),min *limitScale,max *limitScale)
				boneMap[skeleton:LookupBone(name)] = true
			end
			local function add_hinge_constaint2(parentName,name,min,max)
				solverC:AddHingeConstraint2(skeleton:LookupBone(parentName),skeleton:LookupBone(name),min *limitScale,max *limitScale)
				boneMap[skeleton:LookupBone(name)] = true
			end
			local function add_hinge_constaint3(parentName,name,min,max)
				solverC:AddHingeConstraint3(skeleton:LookupBone(parentName),skeleton:LookupBone(name),min *limitScale,max *limitScale)
				boneMap[skeleton:LookupBone(name)] = true
			end
			local function add_fixed_constaint(parentName,name)
				solverC:AddFixedConstraint(skeleton:LookupBone(parentName),skeleton:LookupBone(name))
				boneMap[skeleton:LookupBone(name)] = true
			end
			local function add_ballsocket_constraint(parentName,name,minAng,maxAng)
				solverC:AddBallSocketJoint(skeleton:LookupBone(parentName),skeleton:LookupBone(name),minAng *limitScale,maxAng *limitScale)
				boneMap[skeleton:LookupBone(name)] = true
			end

			--solverC:GetIkBone(skeleton:LookupBone("Bind_LeftFoot")):SetPinned(true)
			--solverC:GetIkBone(skeleton:LookupBone("Bind_RightFoot")):SetPinned(true)
			--solverC:GetIkBone(skeleton:LookupBone("Bind_LeftHand")):SetPinned(true)
			--solverC:GetIkBone(skeleton:LookupBone("Bind_RightHand")):SetPinned(true)
			--solverC:AddDragControl(skeleton:LookupBone("Bind_LeftHand"))
			--[[solverC:AddDragControl(skeleton:LookupBone("Bind_LeftHandIndex2"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_RightHand"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftFoot"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_RightFoot"))]]
			--solverC:AddDragControl(skeleton:LookupBone("Bind_Hips"))
			--solverC:AddDragControl(skeleton:LookupBone("Bind_Spine"))
			--solverC:AddDragControl(skeleton:LookupBone("Bind_Spine2"))
			--solverC:GetIkBone(skeleton:LookupBone("Bind_LeftFoot")):SetPinned(true)
			--solverC:GetIkBone(skeleton:LookupBone("Bind_RightFoot")):SetPinned(true)
			--solverC:GetIkBone(skeleton:LookupBone("Bind_RightHand")):SetPinned(true)

			--[[add_hinge_constaint3("Bind_LeftArm","Bind_LeftForeArm",-10,60)
			add_fixed_constaint("Bind_LeftForeArm","Bind_LeftHand",EulerAngles(-20,-40,-5),EulerAngles(20,10,5))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftHand"))
			solverC:GetIkBone(skeleton:LookupBone("Bind_LeftShoulder")):SetPinned(true)]]

			add_hinge_constaint("Bind_LeftUpLeg","Bind_LeftLeg",-10,60)
			add_fixed_constaint("Bind_LeftLeg","Bind_LeftFoot",EulerAngles(-20,-40,-5),EulerAngles(20,10,5))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftFoot"))
			solverC:GetIkBone(skeleton:LookupBone("Bind_LeftUpLeg")):SetPinned(true)

			local dbgInfo = debug.DrawInfo()
			dbgInfo:SetColor(Color.Lime)
			dbgInfo:SetDuration(24)
			--local p = solverC:GetReferenceBonePose(skeleton:LookupBone("Bind_LeftForeArm"))
			local p = solverC:GetReferenceBonePose(skeleton:LookupBone("Bind_LeftLeg"))
			p = self:GetEntity():GetPose() *p
			local l = 30
			dbgInfo:SetColor(Color.Red) debug.draw_line(p:GetOrigin(),p:GetOrigin() +p:GetForward() *l,dbgInfo)
			dbgInfo:SetColor(Color.Green) debug.draw_line(p:GetOrigin(),p:GetOrigin() +p:GetRight() *l,dbgInfo)
			dbgInfo:SetColor(Color.Blue) debug.draw_line(p:GetOrigin(),p:GetOrigin() +p:GetUp() *l,dbgInfo)


			local function add_fixed_joints(bone)
				if(bone:GetParent() ~= nil and boneMap[bone:GetID()] ~= true) then
					add_fixed_constaint(bone:GetParent():GetName(),bone:GetName())
				end

				for boneId,child in pairs(bone:GetChildren()) do
					add_fixed_joints(child)
				end
			end
			for boneId,bone in pairs(skeleton:GetRootBones()) do
				add_fixed_joints(bone)
			end

			--[[solverC:AddDragControl(skeleton:LookupBone("Bind_Hips"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftLeg"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftFoot"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_RightLeg"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_RightFoot"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftForeArm"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_LeftHand"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_RightForeArm"))
			solverC:AddDragControl(skeleton:LookupBone("Bind_RightHand"))
			--solverC:AddDragControl(skeleton:LookupBone("Bind_LeftToeBase"))
			--solverC:AddDragControl(skeleton:LookupBone("Bind_LeftHandIndex2"))
			--solverC:SetEffectorIndex(skeleton:LookupBone("Bind_LeftToeBase"))


			--add_fixed_constaint("Bind_Hips","Bind_Root")
			-- Hips and Spine
			add_ballsocket_constraint("Bind_Hips","Bind_Root",EulerAngles(-20,-40,-5),EulerAngles(20,20,5))
			add_fixed_constaint("Bind_Root","Bind_Spine")

			--add_fixed_constaint("Bind_Spine","Bind_Spine1")
			add_ballsocket_constraint("Bind_Spine","Bind_Spine1",EulerAngles(-5,-5,-5),EulerAngles(5,5,5))

			--add_fixed_constaint("Bind_Spine1","Bind_Spine2")
			add_ballsocket_constraint("Bind_Spine1","Bind_Spine2",EulerAngles(-5,-5,-5),EulerAngles(5,5,5))

			--add_fixed_constaint("Bind_Spine2","Bind_Neck")
			add_ballsocket_constraint("Bind_Spine2","Bind_Neck",EulerAngles(-10,-15,-10),EulerAngles(10,10,10))

			add_fixed_constaint("Bind_Neck","Bind_Head")


			--solverC:GetIkBone(skeleton:LookupBone("Bind_LeftShoulder")):SetPinned(true)




			-- Left Arm
			add_fixed_constaint("Bind_Spine2","Bind_LeftShoulder")

			--add_fixed_constaint("Bind_LeftShoulder","Bind_LeftArm")
			add_ballsocket_constraint("Bind_LeftShoulder","Bind_LeftArm",EulerAngles(-35,-1,-5),EulerAngles(100,30,5))

			add_hinge_constaint3("Bind_LeftArm","Bind_LeftForeArm",-10,60)
			--add_fixed_constaint("Bind_LeftArm","Bind_LeftForeArm")

			--add_fixed_constaint("Bind_LeftForeArm","Bind_LeftHand")
			add_ballsocket_constraint("Bind_LeftForeArm","Bind_LeftHand",EulerAngles(-20,-40,-5),EulerAngles(20,10,5))

			add_fixed_constaint("Bind_LeftHand","Bind_LeftHandThumb1")
			add_fixed_constaint("Bind_LeftHandThumb1","Bind_LeftHandThumb2")
			add_fixed_constaint("Bind_LeftHandThumb2","Bind_LeftHandThumb3")
			add_fixed_constaint("Bind_LeftHand","Bind_LeftHandIndex1")
			add_fixed_constaint("Bind_LeftHandIndex1","Bind_LeftHandIndex2")
			add_fixed_constaint("Bind_LeftHandIndex2","Bind_LeftHandIndex3")
			add_fixed_constaint("Bind_LeftHand","Bind_LeftHandMiddle1")
			add_fixed_constaint("Bind_LeftHandMiddle1","Bind_LeftHandMiddle2")
			add_fixed_constaint("Bind_LeftHandMiddle2","Bind_LeftHandMiddle3")
			add_fixed_constaint("Bind_LeftHand","Bind_LeftHandRing1")
			add_fixed_constaint("Bind_LeftHandRing1","Bind_LeftHandRing2")
			add_fixed_constaint("Bind_LeftHandRing2","Bind_LeftHandRing3")
			add_fixed_constaint("Bind_LeftHand","Bind_LeftHandPinky1")
			add_fixed_constaint("Bind_LeftHandPinky1","Bind_LeftHandPinky2")
			add_fixed_constaint("Bind_LeftHandPinky2","Bind_LeftHandPinky3")

			-- Right Arm
			add_fixed_constaint("Bind_Spine2","Bind_RightShoulder")

			--add_fixed_constaint("Bind_RightShoulder","Bind_RightArm")
			add_ballsocket_constraint("Bind_RightShoulder","Bind_RightArm",EulerAngles(-100,-1,-5),EulerAngles(35,30,5))

			add_hinge_constaint3("Bind_RightArm","Bind_RightForeArm",-60,10)
			--add_fixed_constaint("Bind_RightArm","Bind_RightForeArm")

			--add_fixed_constaint("Bind_RightForeArm","Bind_RightHand")
			add_ballsocket_constraint("Bind_RightForeArm","Bind_RightHand",EulerAngles(-20,-40,-5),EulerAngles(20,10,5))

			add_fixed_constaint("Bind_RightHand","Bind_RightHandThumb1")
			add_fixed_constaint("Bind_RightHandThumb1","Bind_RightHandThumb2")
			add_fixed_constaint("Bind_RightHandThumb2","Bind_RightHandThumb3")
			add_fixed_constaint("Bind_RightHand","Bind_RightHandIndex1")
			add_fixed_constaint("Bind_RightHandIndex1","Bind_RightHandIndex2")
			add_fixed_constaint("Bind_RightHandIndex2","Bind_RightHandIndex3")
			add_fixed_constaint("Bind_RightHand","Bind_RightHandMiddle1")
			add_fixed_constaint("Bind_RightHandMiddle1","Bind_RightHandMiddle2")
			add_fixed_constaint("Bind_RightHandMiddle2","Bind_RightHandMiddle3")
			add_fixed_constaint("Bind_RightHand","Bind_RightHandRing1")
			add_fixed_constaint("Bind_RightHandRing1","Bind_RightHandRing2")
			add_fixed_constaint("Bind_RightHandRing2","Bind_RightHandRing3")
			add_fixed_constaint("Bind_RightHand","Bind_RightHandPinky1")
			add_fixed_constaint("Bind_RightHandPinky1","Bind_RightHandPinky2")
			add_fixed_constaint("Bind_RightHandPinky2","Bind_RightHandPinky3")

			-- add_fixed_constaint("Bind_Root","Bind_Hips")

			
			-- Left Leg
			add_ballsocket_constraint("Bind_Hips","Bind_LeftUpLeg",EulerAngles(-20,-35,-5),EulerAngles(20,30,5)) -- Foot left/right, up/down
			--add_fixed_constaint("Bind_Hips","Bind_LeftUpLeg")

			add_hinge_constaint("Bind_LeftUpLeg","Bind_LeftLeg",-10,60)
			--add_fixed_constaint("Bind_LeftUpLeg","Bind_LeftLeg")

			add_ballsocket_constraint("Bind_LeftLeg","Bind_LeftFoot",EulerAngles(-20,-20,0),EulerAngles(20,20,0)) -- Foot left/right, up/down
			--add_fixed_constaint("Bind_LeftLeg","Bind_LeftFoot")

			add_fixed_constaint("Bind_LeftFoot","Bind_LeftToeBase")

			-- Right Leg
			add_ballsocket_constraint("Bind_Hips","Bind_RightUpLeg",EulerAngles(-20,-35,-5),EulerAngles(20,30,5)) -- Foot left/right, up/down
			--add_fixed_constaint("Bind_Hips","Bind_RightUpLeg")

			add_hinge_constaint("Bind_RightUpLeg","Bind_RightLeg",-10,60)
			--add_fixed_constaint("Bind_RightUpLeg","Bind_RightLeg")

			add_ballsocket_constraint("Bind_RightLeg","Bind_RightFoot",EulerAngles(-20,-20,0),EulerAngles(20,20,0)) -- Foot left/right, up/down
			--add_fixed_constaint("Bind_RightLeg","Bind_RightFoot")

			add_fixed_constaint("Bind_RightFoot","Bind_RightToeBase")]]



			--solverC:GetIkBone(skeleton:LookupBone("Bind_Hips")):SetPinned(true)
			--solverC:SetEffectorIndex(solverC:GetIkBoneId(skeleton:LookupBone("Bind_RightToeBase")))
			






			--[[for name,boneData in pairs(rig) do
				local boneId = skeleton:LookupBone(name)
				if(boneMap[boneId] == nil) then
					local parent = skeleton:GetBone(boneId):GetParent()
					local bone = solverC:GetIkBone(boneId)
					table.insert(self.m_bones,{
						boneId,bone
					})

					if(boneData.type == "hinge") then
						--solverC:AddHingeConstraint(parent:GetID(),boneId,boneData.min.p,boneData.max.p)
						solverC:AddFixedConstraint(parent:GetID(),boneId)
					elseif(boneData.type == "ballSocket") then
						--solverC:AddBallSocketJoint(parent:GetID(),boneId,boneData.min,boneData.max)
						solverC:AddFixedConstraint(parent:GetID(),boneId)
					end
					boneMap[boneId] = true
				end
			end

			for _,bone in ipairs(skeleton:GetBones()) do
				if(boneMap[bone:GetID()] == nil) then
					if(bone:GetParent() ~= nil) then
						--if(bone:GetName() == "Bind_Neck" or bone:GetName() == "Bind_Spine2") then
							solverC:AddFixedConstraint(bone:GetParent():GetID(),bone:GetID())
						--end
					else
						solverC:AddFixedConstraint(bone:GetID(),skeleton:LookupBone("Bind_Hips"))
					end
				end
			end]]

			--Bind_Neck:SetPinned(true)
			--solverC:GetIkBone(skeleton:LookupBone("Bind_RightFoot")):SetPinned(true)

			--[[local rig = {
				["Bind_Head"] = {
					type = "ballSocket",
					min = EulerAngles(-45,-50,-45),
					max = EulerAngles(45,50,45)
				},]]


			--[[local Bind_Neck = solverC:AddBone(Bind_NeckId,get_bone_pos(Bind_NeckId), get_bone_rot(Bind_NeckId), 1, 1);
			local Bind_Head = solverC:AddBone(Bind_HeadId,get_bone_pos(Bind_HeadId), get_bone_rot(Bind_HeadId), 1, 1,Bind_Neck);

			self.m_bones = {
				{Bind_NeckId,Bind_Neck or false},
				{Bind_HeadId,Bind_Head or false}
			}

			solverC:AddBallSocketJoint(Bind_NeckId,Bind_HeadId,EulerAngles(-20,-20,0),EulerAngles(20,20,0))]]

			--[[local min = -20
			local max = 50
			local baseRot = get_bone_hinge_rot(Bind_LeftArmId)
			debug.draw_line(get_bone_pos(Bind_LeftForeArmId),get_bone_pos(Bind_LeftForeArmId) +baseRot:GetForward() *20)
			debug.draw_line(get_bone_pos(Bind_LeftForeArmId),get_bone_pos(Bind_LeftForeArmId) +baseRot:GetRight() *20)
			debug.draw_line(get_bone_pos(Bind_LeftForeArmId),get_bone_pos(Bind_LeftForeArmId) +baseRot:GetUp() *20)
			local baseRot2 = get_bone_hinge_rot(Bind_LeftForeArmId)
			local limitBaseRot = baseRot2 *EulerAngles(0,-(max +min),0):ToQuaternion()
			solver:AddBallSocketJoint(Bind_LeftArm, Bind_LeftForeArm, Bind_LeftForeArm:GetPos());
			solver:AddRevoluteJoint(Bind_LeftArm, Bind_LeftForeArm,get_bone_hinge_axis(baseRot))
			solver:AddSwingLimit(Bind_LeftArm, Bind_LeftForeArm, get_bone_hinge_axis2(limitBaseRot), get_bone_hinge_axis2(baseRot2), math.rad(max -min)):SetRigidity(16);
]]

			--debug.draw_line(get_bone_pos(Bind_LeftForeArmId),get_bone_pos(Bind_LeftForeArmId) +get_bone_hinge_axis(baseRot) *100)



			--Bind_Neck:SetPinned(true)
			--solverC:SetEffectorIndex(1)
		else
			local Bind_LeftShoulder = solverC:AddBone(Bind_LeftShoulderId,get_bone_pos(Bind_LeftShoulderId), get_bone_rot(Bind_LeftShoulderId), 1, 1);
			local Bind_LeftArm = solverC:AddBone(Bind_LeftArmId,get_bone_pos(Bind_LeftArmId), get_bone_rot(Bind_LeftArmId), 1, 1,Bind_LeftShoulder);
			local Bind_LeftForeArm = solverC:AddBone(Bind_LeftForeArmId,get_bone_pos(Bind_LeftForeArmId), get_bone_rot(Bind_LeftForeArmId), 1, 1,Bind_LeftArm);
			local Bind_LeftHand = solverC:AddBone(Bind_LeftHandId,get_bone_pos(Bind_LeftHandId), get_bone_rot(Bind_LeftHandId), 1, 1,Bind_LeftForeArm);

			Bind_LeftShoulder:SetPinned(true)

			local axis = get_bone_axis(Bind_LeftArmId)
			--solverC:AddBallSocketJoint(Bind_LeftShoulderId,Bind_LeftArmId,EulerAngles(0,0,0),EulerAngles(0,0,0))

			--solver:AddSwivelHingeJoint(Bind_LeftArm, Bind_LeftForeArm,get_bone_hinge_axis(Bind_LeftForeArmId),get_bone_axis(Bind_LeftForeArmId))
			--[[solver:AddBallSocketJoint(Bind_LeftArm, Bind_LeftForeArm, Bind_LeftForeArm:GetPos());
			solver:AddRevoluteJoint(Bind_LeftArm, Bind_LeftForeArm,get_bone_hinge_axis(Bind_LeftForeArmId))
			debug.draw_line(get_bone_pos(Bind_LeftForeArmId),get_bone_pos(Bind_LeftForeArmId) +get_bone_hinge_axis(Bind_LeftForeArmId) *100)]]
			--debug.draw_line(get_bone_pos(Bind_LeftForeArm),get_bone_pos(Bind_LeftForeArm) +get_bone_hinge_axis(Bind_LeftForeArm) *100)

			--[[solver:AddBallSocketJoint(Bind_LeftShoulder, Bind_LeftArm, Bind_LeftArm:GetPos());
			solver:AddBallSocketJoint(Bind_LeftForeArm, Bind_LeftHand, Bind_LeftHand:GetPos());
	]]
			--[[solver:AddSwingLimit(Bind_LeftShoulder, Bind_LeftArm, get_bone_axis(Bind_LeftArmId), get_bone_axis(Bind_LeftArmId), math.rad(10)):SetRigidity(100);
			solver:AddSwingLimit(Bind_LeftArm, Bind_LeftForeArm, get_bone_axis(Bind_LeftForeArmId), get_bone_axis(Bind_LeftForeArmId), math.rad(10)):SetRigidity(100);
			solver:AddSwingLimit(Bind_LeftForeArm, Bind_LeftHand, get_bone_axis(Bind_LeftHandId), get_bone_axis(Bind_LeftHandId), math.rad(10)):SetRigidity(100);

			solver:AddTwistLimit(Bind_LeftShoulder, Bind_LeftArm, get_bone_axis(Bind_LeftArmId), get_bone_axis(Bind_LeftArmId), math.rad(10)):SetRigidity(100);
			solver:AddTwistLimit(Bind_LeftArm, Bind_LeftForeArm, get_bone_axis(Bind_LeftForeArmId), get_bone_axis(Bind_LeftForeArmId), math.rad(10)):SetRigidity(100);
			solver:AddTwistLimit(Bind_LeftForeArm, Bind_LeftHand, get_bone_axis(Bind_LeftHandId), get_bone_axis(Bind_LeftHandId), math.rad(10)):SetRigidity(100);]]
			--solver:AddAngularJoint(Bind_LeftArm,Bind_LeftShoulder);
			--solver:AddSwingLimit(Bind_LeftShoulder, Bind_LeftArm, axis, axis, math.pi /4.0);

			--solver:AddDistanceJoint(Bind_LeftShoulder, Bind_LeftArm);

			--local Bind_LeftForeArm = solverC:AddBone(get_bone_pos(Bind_LeftForeArmId), Quaternion(), 1, 3,Bind_LeftArm);
			--local Bind_LeftHand = solverC:AddBone(get_bone_pos(Bind_LeftHandId), Quaternion(), 1, 3,Bind_LeftForeArm);
			self.m_bones = {
				{Bind_LeftShoulderId,Bind_LeftShoulder or false},
				{Bind_LeftArmId,Bind_LeftArm or false},
				{Bind_LeftForeArmId,Bind_LeftForeArm or false},
				{Bind_LeftHandId,Bind_LeftHand or false}
			}

			--solverC:SetEffectorIndex(2)
		end
	else

		local pose0 = self:GetEntity():GetPose() *solverC:GetReferenceBonePose(Bind_LeftShoulderId)
		local pose1 = self:GetEntity():GetPose() *solverC:GetReferenceBonePose(Bind_LeftArmId)


		local scale = 10
		local position = Vector(0,10,0)
		local Q = {Identity = Quaternion()}

		local dbgInfo = debug.DrawInfo()
		dbgInfo:SetColor(Color.Lime)
		dbgInfo:SetDuration(24)


		local parentBonePose = math.Transform(Vector(0,0,0),pose0:GetRotation())
		--local childBonePose = math.Transform(Vector(0,35,0),EulerAngles(45,0,0):ToQuaternion())
		local childBonePose = math.Transform(Vector(0,35,0),EulerAngles(0,0,0):ToQuaternion())
		local minLimit = EulerAngles(0,0,0)
		local maxLimit = EulerAngles(20,0,0)





		--local baseBone = solverC:AddBone(0,pose0:GetOrigin(), pose0:GetRotation(), 1, 3);
		--local upperArm = solverC:AddBone(1,pose1:GetOrigin(), pose1:GetRotation(), .4, 4,baseBone);
		local absChildPose = parentBonePose *childBonePose
		local baseBone = solverC:AddBone(0,parentBonePose:GetOrigin(), parentBonePose:GetRotation(), 10, 30);
		local subRot = parentBonePose:GetRotation() *childBonePose:GetRotation() -- Child bone rotation
		local upperArm = solverC:AddBone(1,baseBone:GetPos() + subRot:GetUp() *35, subRot, 4, 40,baseBone);
		debug.draw_line(baseBone:GetPos(),baseBone:GetPos() +Vector(20,0,0),dbgInfo)
		debug.draw_line(upperArm:GetPos(),upperArm:GetPos() +Vector(20,0,0),dbgInfo)
		print(upperArm:GetPos())

		--local lowerArm = solverC:AddBone(upperArm:GetPos() + Vector(0, 2 + 1, 0), Q.Identity, .7, 2,upperArm);
		--local bonkDevice = solverC:AddBone(lowerArm:GetPos() + Vector(0, 5, 0), Q.Identity, .6, 1.2,lowerArm);

		local minSwing = 0
		local maxSwing = 0
		local axisOffset = subRot *EulerAngles((minSwing +maxSwing) /2.0,0,0):ToQuaternion()
		local swingRange = (maxSwing -minSwing)

		solver:AddBallSocketJoint(baseBone, upperArm, baseBone:GetPos());
		solver:AddSwingLimit(baseBone, upperArm, axisOffset:GetUp(), subRot:GetUp(), math.rad(swingRange)):SetRigidity(1000)
		-- TODO: Twist Limit

		baseBone:SetPinned(true)
		--solverC:SetEffectorIndex(1)



		--[[
		local baseBone = solverC:AddBone(0,position *scale, Q.Identity, 1 *scale, 3 *scale);
		local upperArm = solverC:AddBone(1,baseBone:GetPos() + Vector(0, 3.5, 0) *scale, Q.Identity, .4 *scale, 4 *scale,baseBone);

		--local lowerArm = solverC:AddBone(upperArm:GetPos() + Vector(0, 2 + 1, 0), Q.Identity, .7, 2,upperArm);
		--local bonkDevice = solverC:AddBone(lowerArm:GetPos() + Vector(0, 5, 0), Q.Identity, .6, 1.2,lowerArm);

		solver:AddBallSocketJoint(baseBone, upperArm, baseBone:GetPos());
		solver:AddSwingLimit(baseBone, upperArm, vector.UP, vector.UP, math.rad(10)):SetRigidity(1000)

		baseBone:SetPinned(true)
		solverC:SetEffectorIndex(1)]]
	end

	--[[local position = Vector(0,40,0)
	local baseBone = solverC:AddBone(position, Quaternion(), 1, 3);
	local upperArm = solverC:AddBone(baseBone:GetPos() + Vector(0, 40, 0),Quaternion(), .4, 4,baseBone);

	solver:AddBallSocketJoint(baseBone, upperArm, baseBone:GetPos() + Vector(0, 1.5, 0));
	solver:AddSwingLimit(baseBone, upperArm, vector.UP, vector.UP, math.rad(0));

	self.m_bones = {
		{baseBone,upperArm or false}
	}

	baseBone:SetPinned(true)
	solverC:SetEffectorIndex(1)]]



	--[[solver:AddBallSocketJoint(upperArm, lowerArm, upperArm:GetPos() + Vector(0, 2, 0));
	solver:AddRevoluteJoint(upperArm, lowerArm, vector.FORWARD);
	solver:AddSwingLimit(upperArm, lowerArm, vector.UP, vector.UP, math.pi /4.0);

	solver:AddPointOnLineJoint(lowerArm, bonkDevice, lowerArm:GetPos(), vector.UP, bonkDevice:GetPos());
	solver:AddAngularJoint(lowerArm, bonkDevice);
	solver:AddLinearAxisLimit(lowerArm, bonkDevice, lowerArm:GetPos(), vector.UP, bonkDevice:GetPos(), 1.6, 5);]]


end
--[[function Component:AddBallSocketJoint(boneId0,boneId1,minLimits,maxLimits)
	local pose0 = self:GetReferenceBonePose(boneId0)
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

	-- TODO: Add twist limit
end]]
ents.COMPONENT_PFM_FBIK = ents.register_component("pfm_fbik",Component)
