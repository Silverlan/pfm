--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMIk",BaseEntityComponent)

local flags = bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT)
Component:RegisterMember("ConfigFile",udm.TYPE_STRING,"",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		c:InitializeFromConfiguration()
	end,
	metaData = {
		rootPath = "cfg/ik/",
		basePath = "ik/",
		extensions = {"udm"},
		stripExtension = true
	}
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	-- self:AddEntityComponent(ents.COMPONENT_IK)
	self:BindEvent(ents.AnimatedComponent.EVENT_UPDATE_BONE_POSES,"UpdateIkTrees")
	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,"OnModelChanged")
	-- self:BindEvent(ents.PanimaComponent.EVENT_ON_ANIMATIONS_UPDATED,"UpdateIkTrees")

	self.m_ikControllers = {}
	self.m_ikControllerNames = {}
	self.m_ikControllerPriorityDirty = false

	self:SetEnabled(true)
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:OnModelChanged()
	self:InitializeFromConfiguration()
end

function Component:GetNormalizedConfigFilePath()
	local cfg = self:GetConfigFile()
	if(#cfg == 0) then cfg = self:GetDefaultConfigurationFileName() end
	return "cfg/ik/" .. file.remove_file_extension(cfg,{"udm"}) .. ".udm"
end

local function model_path_to_identifier(mdlPath)
	if(type(mdlPath) ~= "string") then mdlPath = mdlPath:GetName() end
	mdlPath = asset.get_normalized_path(mdlPath,asset.TYPE_MODEL)
	return mdlPath:replace("/","_")
end

function Component:GetDefaultConfigurationFileName()
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local name = mdl:GetName()
	name = model_path_to_identifier(name)
	return name
end

function Component:SaveConfig()
	local filePath = util.Path.CreateFilePath(self:GetNormalizedConfigFilePath())
	local udmData,err = udm.create("PIKC",1)
	if(udmData == false) then
		pfm.log("Unable to save ik config '" .. filePath:GetString() .. "': " .. err,pfm.LOG_CATEGORY_RETARGET,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return false end
	local skeleton = mdl:GetSkeleton()

	local assetData = udmData:GetAssetData():GetData()
	local udmIks = assetData:Add("ik")
	for name,data in pairs(self.m_ikControllers) do
		if(data.ikChain ~= nil) then
			local udmIk = udmIks:Add(name)
			udmIk:SetValue("bone",udm.TYPE_STRING,skeleton:GetBone(data.ikChain[#data.ikChain]):GetName())
			udmIk:SetValue("chainLength",udm.TYPE_UINT16,#data.ikChain)
			udmIk:SetValue("offsetPose",udm.TYPE_TRANSFORM,data.effectorOffsetPose)
		end
	end

	if(file.create_path(filePath:GetPath()) == false) then return end
	local f = file.open(filePath:GetString(),file.OPEN_MODE_WRITE)
	if(f == nil) then
		pfm.log("Unable to open file '" .. filePath:GetString() .. "' for writing!",pfm.LOG_CATEGORY_RETARGET,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local res,err = udmData:SaveAscii(f) -- ,udm.ASCII_SAVE_FLAG_BIT_INCLUDE_HEADER)
	f:Close()
	if(res == false) then
		pfm.log("Failed to save ik config as '" .. filePath:GetString() .. "': " .. err,pfm.LOG_CATEGORY_RETARGET,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	return true
end

function Component:AddIkControllerByChain(boneName,chainLength,ikName,offsetPose)
	ikName = ikName or boneName

	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return false end
	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()

	local ikChain = {}
	local boneId = skeleton:LookupBone(boneName)
	if(boneId == -1) then return false end

	for name,data in pairs(self.m_ikControllers) do
		if(data.ikChain ~= nil and data.ikChain[1] == boneId) then
			self:RemoveIkController(name)
			break
		end
	end

	local bone = skeleton:GetBone(boneId)
	for i=1,chainLength do
		if(bone == nil) then return false end
		table.insert(ikChain,1,bone:GetID())
		bone = bone:GetParent()
	end

	if(#ikChain == 0) then return false end
	offsetPose = offsetPose or math.Transform()
	self:AddIkController(ikName,ikChain,offsetPose)

	--[[local pose = ent:GetPose() *ref:GetBonePose(boneId)
	self:SetMemberValue("effector/" .. ikName .. "/position",pose:GetOrigin())
	self:SetMemberValue("effector/" .. ikName .. "/rotation",pose:GetRotation())]]
	return true
end

function Component:InitializeFromConfiguration()
	self:ClearIkControllers()

	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local skeleton = mdl:GetSkeleton()
	local ref = mdl:GetReferencePose()
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)

	local udmData,err = udm.load(self:GetNormalizedConfigFilePath())
	if(udmData == false) then return false end
	local assetData = udmData:GetAssetData():GetData()
	local ikUdm = assetData:Get("ik")
	local ikChains = {}
	for name,udmIkChain in pairs(ikUdm:GetChildren()) do
		local bone = udmIkChain:GetValue("bone",udm.TYPE_STRING)
		local chainLength = udmIkChain:GetValue("chainLength",udm.TYPE_UINT32)
		if(bone ~= nil and chainLength ~= nil) then
			local ikChain = {}
			ikChain.bone = bone
			ikChain.chainLength = chainLength
			ikChain.offsetPose = udmIkChain:GetValue("offsetPose",udm.TYPE_TRANSFORM)

			local boneId = skeleton:LookupBone(bone)
			if(boneId ~= -1) then
				ikChain.pose = animC:GetGlobalBonePose(boneId)
			end
			ikChains[name] = ikChain
		end
	end

	for name,ikChain in pairs(ikChains) do
		self:AddIkControllerByChain(ikChain.bone,ikChain.chainLength,name,ikChain.offsetPose)
	end

	for name,ikChain in pairs(ikChains) do
		if(ikChain.pose ~= nil) then
			self:SetMemberValue("effector/" .. name .. "/position",ikChain.pose:GetOrigin())
			self:SetMemberValue("effector/" .. name .. "/rotation",ikChain.pose:GetRotation())
		end
	end
	self:UpdateIkTrees()
	return true
end

function Component:OnTick(dt)
	--self:UpdateIkTrees()
end

function Component:CreateEffector(ikControllerIdx,effectorIdx)
	local entEffector = ents.create("entity")
	--local ikC = entEffector:AddComponent("pfm_ik_effector_target")
	--if(ikC ~= nil) then ikC:SetTargetActor(self:GetEntity(),ikControllerIdx,effectorIdx) end -- TODO
	if(self:GetEntity():IsSpawned()) then entEffector:Spawn() end
	return entEffector
end

function Component:SortIkControllers()
	if(self.m_ikControllerPriorityDirty == false) then return end
	table.sort(self.m_ikControllerNames,function(a,b) return self:GetIkControllerPriority(a) < self:GetIkControllerPriority(b) end)
	self.m_ikControllerPriorityDirty = false
end

function Component:GetIkControllerPriority(name) return (self.m_ikControllers[name] ~= nil) and self.m_ikControllers[name].priority or -1 end
function Component:SetIkControllerPriority(name,priority)
	if(self.m_ikControllers[name] == nil) then return end
	self.m_ikControllers[name].priority = priority
end

function Component:GetIkControllerBoneChain(name) return (self.m_ikControllers[name] ~= nil) and self.m_ikControllers[name].ikChain or nil end
function Component:GetIkSolver(name) return (self.m_ikControllers[name] ~= nil) and self.m_ikControllers[name].ikSolver or nil end

function Component:ResetToReferencePose(name)
	local ikData = self.m_ikControllers[name]
	if(ikData == nil) then return end
	local mdl = self:GetEntity():GetModel()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local ref = mdl:GetReferencePose()
	local skeleton = mdl:GetSkeleton()
	for _,boneId in ipairs(ikData.ikChain) do
		local bone = skeleton:GetBone(boneId)
		local parent = bone:GetParent()
		local pose = (parent ~= nil) and ref:GetBonePose(parent:GetID()):GetInverse() or math.Transform()
		pose = pose *ref:GetBonePose(boneId)
		animC:SetBonePose(boneId,pose)
	end
end

function Component:ClearIkControllers()
	local names = {}
	for name,_ in pairs(self.m_ikControllers) do table.insert(names,name) end
	for _,name in ipairs(names) do
		self:RemoveIkController(name)
	end
end

function Component:AddIkController(name,ikChain,effectorOffsetPose)
	if(self.m_ikControllers[name] ~= nil) then return end

	self.m_ikControllers[name] = {
		trackedDevice = trackedDevice,
		effector = self:CreateEffector(ikControllerIdx,effectorIdx),
		effectorOffsetPose = effectorOffsetPose or math.Transform()
	}
	table.insert(self.m_ikControllerNames,name)
	self.m_ikControllerPriorityDirty = true
	self:InitializeIkTree(name,ikChain)
	self:RegisterMember("effector/" .. name .. "/position",udm.TYPE_VECTOR3,Vector(),{
		onChange = function(c)
			c:SetEffectorPos(name,self:GetMemberValue("effector/" .. name .. "/position"))
			self:ResetToReferencePose(name)
			self:UpdateIkTree(name)
		end
	})
	self:RegisterMember("effector/" .. name .. "/rotation",udm.TYPE_QUATERNION,Quaternion(),{
		onChange = function(c)
			c:SetEffectorRot(name,self:GetMemberValue("effector/" .. name .. "/rotation"))
			self:ResetToReferencePose(name)
			self:UpdateIkTree(name)
		end
	})
end

function Component:RemoveIkController(name)
	self:RemoveMember("effector/" .. name .. "/position")
	self:RemoveMember("effector/" .. name .. "/rotation")
	self.m_ikControllers[name] = nil

	for i,nameOther in ipairs(self.m_ikControllerNames) do
		if(nameOther == name) then
			table.remove(self.m_ikControllerNames,i)
			break
		end
	end
end

function Component:SetDebugDrawIkTree(draw)
	draw = draw or false
	if(draw == util.is_valid(self.m_cbDebugDraw)) then return end
	if(draw == false) then
		util.remove(self.m_cbDebugDraw)
		return
	end
	self.m_cbDebugDraw = game.add_callback("Think",function()
		self:DebugDraw()
	end)
end

function Component:DebugDraw(name)
	if(name == nil) then
		for name,_ in pairs(self.m_ikControllers) do
			self:DebugDraw(name)
		end
		return
	end

	local ikData = self.m_ikControllers[name]
	local effectorPos = self:GetEffectorPos(name)
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(ikData.ikSolver == nil or animC == nil) then return end

	local solver = ikData.ikSolver
	local originPose = animC:GetGlobalBonePose(ikData.ikChain[1])
	local parentPose = originPose
	originPose = originPose *solver:GetGlobalTransform(0):GetInverse()
	local drawInfo = debug.DrawInfo()
	drawInfo:SetDuration(0.0001)
	for i=2,solver:Size() do
		local pose = originPose *solver:GetGlobalTransform(i -1)

		drawInfo:SetColor(Color.Red)
		debug.draw_line(parentPose:GetOrigin(),pose:GetOrigin(),drawInfo)

		drawInfo:SetColor(Color.Yellow)
		debug.draw_line(pose:GetOrigin(),pose:GetOrigin() +pose:GetRotation():GetUp() *1,drawInfo)

		parentPose = pose
	end
	drawInfo:SetColor(Color.Aqua)
	debug.draw_line(effectorPos,effectorPos +Vector(0,10,0),drawInfo)
end

function Component:OnRemove()
	self:SetDebugDrawIkTree(false)
	for name,data in pairs(self.m_ikControllers) do
		util.remove(data.effector)
	end
end

function Component:SetIkControllerEnabled(name,enabled)
	if(self.m_ikControllers[name] == nil) then return end
	self.m_ikControllers[name].enabled = enabled
end

function Component:SetEffectorPos(name,pos)
	if(self.m_ikControllers[name] == nil or util.is_valid(self.m_ikControllers[name].effector) == false) then return end
	self.m_ikControllers[name].effector:SetPos(pos)
end
function Component:SetEffectorRot(name,rot)
	if(self.m_ikControllers[name] == nil or util.is_valid(self.m_ikControllers[name].effector) == false) then return end
	self.m_ikControllers[name].effector:SetRotation(rot)
end
function Component:SetEffectorPose(name,pose)
	if(self.m_ikControllers[name] == nil or util.is_valid(self.m_ikControllers[name].effector) == false) then return end
	self.m_ikControllers[name].effector:SetPose(pose)
end

function Component:GetEffectorPos(name) return (self.m_ikControllers[name] ~= nil and util.is_valid(self.m_ikControllers[name].effector)) and self.m_ikControllers[name].effector:GetPos() or nil end
function Component:GetEffectorPose(name) return (self.m_ikControllers[name] ~= nil and util.is_valid(self.m_ikControllers[name].effector)) and self.m_ikControllers[name].effector:GetPose() or nil end
function Component:GetEffectorTarget(name) return self.m_ikControllers[name] and self.m_ikControllers[name].effector or nil end

function Component:OnEntitySpawn()
	self:OnModelChanged()
	for name,data in pairs(self.m_ikControllers) do
		if(util.is_valid(data.effector) and data.effector:IsSpawned() == false) then
			data.effector:Spawn()
		end
	end
end

function Component:SetEnabled(enabled)
	if(enabled == self.m_enabled) then return end
	self.m_enabled = enabled
end

function Component:IsEnabled() return self.m_enabled end

function Component:UpdateIkTree(name)
	if(self:IsEnabled() == false) then return end
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return end
	if(self.m_ikControllerPriorityDirty) then self:SortIkControllers() end
	local ikData = self.m_ikControllers[name]
	if(ikData == nil or ikData.ikSolver == nil or ikData.enabled ~= true) then return end
	local effectorPose = self:GetEffectorPose(name)
	local targetPose = effectorPose

	local mdl = self:GetEntity():GetModel()
	local bone = mdl:GetSkeleton():GetBone(ikData.ikChain[1])
	local parent = bone:GetParent()
	local rootAnimPose = (parent ~= nil) and animC:GetGlobalBonePose(parent:GetID()) or self:GetEntity():GetPose()
	local test = animC:GetBonePose(ikData.ikChain[1])
	rootAnimPose:TranslateLocal(-test:GetOrigin())

	targetPose = rootAnimPose:GetInverse() *targetPose
	--test = test or ikData.ikSolver:GetGlobalTransform(1)
	--targetPose:SetOrigin(test:GetOrigin())
	ikData.ikSolver:Solve(targetPose)

	local rootIkPose = ikData.ikSolver:GetGlobalTransform(0)
	local rootPose = rootAnimPose *rootIkPose--math.ScaledTransform(rootAnimPose:GetOrigin(),rootIkPose:GetRotation(),rootAnimPose:GetScale())
	animC:SetGlobalBonePose(ikData.ikChain[1],rootPose)


	local parentPose = rootPose
	for i=2,#ikData.ikChain do
		local boneId = ikData.ikChain[i]
		local ikPose = ikData.ikSolver:GetGlobalTransform(i -2):GetInverse() *ikData.ikSolver:GetGlobalTransform(i -1)
		local relPose = parentPose:GetInverse() *ikPose
		animC:SetBonePose(boneId,ikPose)
		parentPose = ikPose

		if(i == #ikData.ikChain) then
			local pose = animC:GetGlobalBonePose(boneId)
			--pose:SetRotation(effectorPose:GetRotation() *EulerAngles(90,-90,0):ToQuaternion())--effectorPose:GetRotation() *ikPose:GetRotation())
			--pose:SetRotation(effectorPose:GetRotation() *EulerAngles(-90,90,0):ToQuaternion())--effectorPose:GetRotation() *ikPose:GetRotation())
			pose:SetRotation(effectorPose:GetRotation() *ikData.effectorOffsetPose:GetRotation())
			animC:SetGlobalBonePose(boneId,pose)
			--print(ikPose:GetRotation() *effectorPose:GetRotation():GetInverse())
		end
		--parentPose = ikPose
	end
	--[[for i=1,#ikData.ikChain -1 do
		local parentPose = ikData.ikSolver:GetGlobalTransform(i -1)
		local pose = ikData.ikSolver:GetGlobalTransform(i)
		local offset = Vector(0,70,0)
		debug.draw_line(parentPose:GetOrigin() +offset,pose:GetOrigin() +offset,Color.Magenta,0.1)
		if(i == #ikData.ikChain -1) then
			debug.draw_line(pose:GetOrigin() +offset,targetPose:GetOrigin() +offset,Color.Aqua,0.1)
		end
	end

	local parentPose = math.ScaledTransform()
	for i,boneId in ipairs(ikData.ikChain) do
		local ikPose = ikData.ikSolver:GetGlobalTransform(i -1)
		local relPose = parentPose:GetInverse() *ikPose
		animC:SetBonePose(boneId,relPose)
		parentPose = ikPose
	end]]
end

function Component:UpdateIkTrees(force)
	if(force ~= true) then return end
	if(self:IsEnabled() == false) then return end
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC == nil) then return end
	if(self.m_ikControllerPriorityDirty) then self:SortIkControllers() end
	for name,data in pairs(self.m_ikControllers) do
		self:ResetIkTree(name) -- TODO: This is very expensive, how can we optimize it?
		if(util.is_valid(data.trackedDevice)) then
			local pose = data.trackedDevice:GetEntity():GetPose()
			self:SetEffectorPose(name,pose)
		end
	end

	-- self:InvokeEventCallbacks(ents.VrIk.EVENT_PRE_IK_TREES_UPDATED)
	for _,name in ipairs(self.m_ikControllerNames) do
		local ikData = self.m_ikControllers[name]
		if(ikData.ikSolver ~= nil and ikData.enabled == true) then
			local effectorPose = self:GetEffectorPose(name)
			local targetPose = effectorPose

			local mdl = self:GetEntity():GetModel()
			local bone = mdl:GetSkeleton():GetBone(ikData.ikChain[1])
			local parent = bone:GetParent()
			local rootAnimPose = (parent ~= nil) and animC:GetGlobalBonePose(parent:GetID()) or self:GetEntity():GetPose()
			local test = animC:GetBonePose(ikData.ikChain[1])
			rootAnimPose:TranslateLocal(-test:GetOrigin())

			targetPose = rootAnimPose:GetInverse() *targetPose
			--test = test or ikData.ikSolver:GetGlobalTransform(1)
			--targetPose:SetOrigin(test:GetOrigin())
			ikData.ikSolver:Solve(targetPose)

			local rootIkPose = ikData.ikSolver:GetGlobalTransform(0)
			local rootPose = rootAnimPose *rootIkPose--math.ScaledTransform(rootAnimPose:GetOrigin(),rootIkPose:GetRotation(),rootAnimPose:GetScale())
			animC:SetGlobalBonePose(ikData.ikChain[1],rootPose)


			local parentPose = rootPose
			for i=2,#ikData.ikChain do
				local boneId = ikData.ikChain[i]
				local ikPose = ikData.ikSolver:GetGlobalTransform(i -2):GetInverse() *ikData.ikSolver:GetGlobalTransform(i -1)
				local relPose = parentPose:GetInverse() *ikPose
				animC:SetBonePose(boneId,ikPose)
				parentPose = ikPose

				if(i == #ikData.ikChain) then
					local pose = animC:GetGlobalBonePose(boneId)
					--pose:SetRotation(effectorPose:GetRotation() *EulerAngles(90,-90,0):ToQuaternion())--effectorPose:GetRotation() *ikPose:GetRotation())
					--pose:SetRotation(effectorPose:GetRotation() *EulerAngles(-90,90,0):ToQuaternion())--effectorPose:GetRotation() *ikPose:GetRotation())
					pose:SetRotation(effectorPose:GetRotation() *ikData.effectorOffsetPose:GetRotation())
					animC:SetGlobalBonePose(boneId,pose)
					--print(ikPose:GetRotation() *effectorPose:GetRotation():GetInverse())
				end
				--parentPose = ikPose
			end
			--[[for i=1,#ikData.ikChain -1 do
				local parentPose = ikData.ikSolver:GetGlobalTransform(i -1)
				local pose = ikData.ikSolver:GetGlobalTransform(i)
				local offset = Vector(0,70,0)
				debug.draw_line(parentPose:GetOrigin() +offset,pose:GetOrigin() +offset,Color.Magenta,0.1)
				if(i == #ikData.ikChain -1) then
					debug.draw_line(pose:GetOrigin() +offset,targetPose:GetOrigin() +offset,Color.Aqua,0.1)
				end
			end

			local parentPose = math.ScaledTransform()
			for i,boneId in ipairs(ikData.ikChain) do
				local ikPose = ikData.ikSolver:GetGlobalTransform(i -1)
				local relPose = parentPose:GetInverse() *ikPose
				animC:SetBonePose(boneId,relPose)
				parentPose = ikPose
			end]]
		end
	end
	-- self:InvokeEventCallbacks(ents.VrIk.EVENT_ON_IK_TREES_UPDATED)
end

function Component:ResetIkTree(name)
	if(self.m_ikControllers[name] == nil) then return end
	local ikData = self.m_ikControllers[name]
	local mdl = self:GetEntity():GetModel()
	if(mdl == nil) then return end
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local ref = mdl:GetReferencePose()
	local skeleton = mdl:GetSkeleton()
	-- The ik tree is defined relative to the root bone it's assigned to.
	-- Since ik has an effect on the rotation only of the root bone (and not the translation),
	-- we use the inverse of the root bone rotation as base and ignore the position.
	local boneIds = ikData.ikChain
	local solver = ikData.ikSolver
	local bone = skeleton:GetBone(boneIds[1])
	local parent = bone:GetParent()
	local rootPose = (parent ~= nil) and animC:GetGlobalBonePose(parent:GetID()) or self:GetEntity():GetPose()
	local test = animC:GetGlobalBonePose(boneIds[1])
	test = rootPose:GetInverse() *test
	rootPose:TranslateLocal(-test:GetOrigin())

	local parentPose = rootPose
	for i=1,#boneIds do
		local boneId = boneIds[i]
		local bone = skeleton:GetBone(boneId)
		local pose = animC:GetGlobalBonePose(boneId)
		local relPose = parentPose:GetInverse() *pose
		parentPose = pose
		solver:SetLocalTransform(i -1,relPose)
	end
end

function Component:InitializeIkTree(name,ikChain)
	if(#ikChain == 0) then return end
	local ikData = self.m_ikControllers[name]
	local solver = ik.FABRIkSolver() -- CCDIkSolver()

	local mdl = self:GetEntity():GetModel()
	if(mdl == nil) then return end

	solver:Resize(#ikChain)

	local boneIds = {}
	for i=1,#ikChain do
		local boneId = (type(ikChain[i]) == "string") and mdl:LookupBone(ikChain[i]) or ikChain[i]
		if(boneId == -1) then
			console.print_warning("Unknown bone '" .. ikChain[i] .. "' for ik tree '" .. name .. "'!")
			self.m_ikControllers[name] = nil
			for i,nameOther in pairs(self.m_ikControllerNames) do
				if(nameOther == name) then
					self.m_ikControllerNames[i] = nil
					break
				end
			end
			return
		end
		table.insert(boneIds,boneId)
	end

	ikData.ikSolver = solver
	ikData.ikChain = boneIds
	ikData.enabled = true
	self:ResetIkTree(name)
end
ents.COMPONENT_PFM_IK = ents.register_component("pfm_ik",Component)
