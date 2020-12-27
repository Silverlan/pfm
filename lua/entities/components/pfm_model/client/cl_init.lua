--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMModel",BaseEntityComponent)

function ents.PFMModel:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_EYE)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent("pfm_actor")
	if(renderC ~= nil) then
		renderC:SetCastShadows(true)
	end

	self.m_listeners = {}
end
function ents.PFMModel:OnRemove()
	if(util.is_valid(self.m_cbOnSkeletonUpdated)) then self.m_cbOnSkeletonUpdated:Remove() end
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
end
function ents.PFMModel:OnEntitySpawn()
	local modelData = self:GetModelData()
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	local mdl = (mdlC ~= nil) and mdlC:GetModel() or nil
	if(mdl == nil) then return end
	local bones = modelData:GetBoneList():GetTable()
	local animSetC = (#bones > 0) and self:AddEntityComponent("pfm_animation_set") or nil
	if(animSetC == nil) then return end -- TODO: What if flexes, but no bones? (Animation component shouldn't be needed in this case)
	animSetC:Setup(self:GetActorData())

	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		--[[local function apply_bone_transforms(entInvPose,bone)
			local boneName = bone:GetName()
			local boneId = mdl:LookupBone(boneName) -- TODO: Cache this
			if(boneId ~= -1) then
				local pose = entInvPose *bone:GetTransform():GetAbsolutePose()
				animC:SetEffectiveBoneTransform(boneId,pose)
			end

			for _,child in ipairs(bone:GetChildBones():GetTable()) do
				apply_bone_transforms(entInvPose,child)
			end
		end]]

		--[[self.m_cbOnSkeletonUpdated = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_SKELETON_UPDATED,function()
			local entInvPose = ent:GetPose():GetInverse()
			entInvPose:SetScale(Vector(1,1,1)) -- Entity scale will be applied separately
			for _,bone in ipairs(modelData:GetRootBones():GetTable()) do
				apply_bone_transforms(entInvPose,bone)
			end
		end)]]
		--[[self.m_cbOnSkeletonUpdated = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_SKELETON_UPDATED,function()
			local testPose = phys.Transform()
			local function iterate_skeleton(bone,parentPose)
				local boneName = bone:GetName()
				local boneId = mdl:LookupBone(boneName) -- TODO: Cache bone id
				local pose = parentPose *testPose
				for _,child in ipairs(bone:GetChildBones():GetTable()) do
					iterate_skeleton(child,pose)
				end
			end
			local pose = phys.ScaledTransform()
			for _,bone in ipairs(modelData:GetRootBones():GetTable()) do
				iterate_skeleton(bone,pose)
			end
		end)]]
	end

	for _,bone in ipairs(bones) do
		bone = bone:GetTarget()
		local boneName = bone:GetName()
		local boneId = mdl:LookupBone(boneName)
		if(boneId ~= -1) then
			local t = bone:GetTransform() -- TODO: Remove this
			local pose = t:GetPose()
			animSetC:SetBonePos(boneId,pose:GetOrigin())
			animSetC:SetBoneRot(boneId,pose:GetRotation())
			table.insert(self.m_listeners,t:GetPositionAttr():AddChangeListener(function(newPos)
				-- print("New bone pos (" .. tostring(self:GetEntity()) .. ": ",boneName,boneId,newPos)
				animSetC:SetBonePos(boneId,newPos)
			end))
			table.insert(self.m_listeners,t:GetRotationAttr():AddChangeListener(function(newRot)
				-- print("Rot: ",boneName,boneId,newRot)
				animSetC:SetBoneRot(boneId,newRot)
			end))
		else
			pfm.log("Unknown bone '" .. boneName .. "' for actor with model '" .. mdl:GetName() .. "'! Bone pose will be ignored...",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
		end
	end

	local flexWeights = modelData:GetFlexWeights():GetTable()
	-- Flex controller names are only specified sometimes?
	local globalFlexControllers = modelData:GetGlobalFlexControllers()
	local flexNames = modelData:GetFlexControllerNames():GetTable()
	for i,fc in ipairs(globalFlexControllers:GetTable()) do
		local fcId = mdl:LookupFlexController(flexNames[i]:GetValue())
		if(fcId ~= -1) then
			local weight = fc:GetFlexWeightAttr()
			animSetC:SetFlexController(fcId,weight:GetValue())
			table.insert(self.m_listeners,weight:AddChangeListener(function(newValue)
				if(animSetC:IsValid()) then
					animSetC:SetFlexController(fcId,newValue)
				end
			end))
		else
			pfm.log("Unknown flex controller '" .. fc:GetName() .. "' for actor with model '" .. mdl:GetName() .. "'! Flex controller will be ignored...",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
		end
	end

	-- TODO: Init value
	table.insert(self.m_listeners,modelData:GetFlexControllerScaleAttr():AddChangeListener(function(newScale)
		local flexC = self:GetEntity():GetComponent(ents.COMPONENT_FLEX)
		if(flexC ~= nil) then flexC:SetFlexControllerScale(newScale) end
	end))
end
function ents.PFMModel:GetModelData() return self.m_mdlInfo end
function ents.PFMModel:GetActorData() return self.m_actorData end

-- Calculates local bodygroup indices from a global bodygroup index
function ents.PFMModel:GetBodyGroups(bgIdx)
	local mdl = self:GetEntity():GetModel()
	if(mdl == nil) then return {} end
	local bodyGroups = mdl:GetBodyGroups()

	-- Calculate total number of bodygroup combinations
	local numCombinations = 1
	for _,bg in ipairs(bodyGroups) do
		numCombinations = numCombinations *#bg.meshGroups
	end

	local localBgIndices = {}
	for i=#bodyGroups,1,-1 do
		local bg = bodyGroups[i]
		numCombinations = numCombinations /#bg.meshGroups
		local localBgIdx = math.floor(bgIdx /numCombinations)
		bgIdx = bgIdx %numCombinations

		-- TODO: This is in reverse order because that's how it's done in the SFM,
		-- but there's really no reason to. Instead the global index should be inversed
		-- in the SFM->PFM conversion script!
		table.insert(localBgIndices,1,localBgIdx)
	end
	return localBgIndices
end

function ents.PFMModel:Setup(actorData,mdlInfo)
	self.m_mdlInfo = mdlInfo
	self.m_actorData = actorData
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	table.insert(self.m_listeners,mdlInfo:GetModelNameAttr():AddChangeListener(function(newModel) ent:SetModel(newModel) end))
	table.insert(self.m_listeners,mdlInfo:GetSkinAttr():AddChangeListener(function(newSkin) ent:SetSkin(newSkin) end))
	local mdlName = mdlInfo:GetModelName()
	mdlC:SetModel(mdlName)
	mdlC:SetSkin(mdlInfo:GetSkin())

	local mdl = mdlC:GetModel()
	if(mdl == nil) then return end
	local materials = mdl:GetMaterials()
	for _,matOverride in ipairs(mdlInfo:GetMaterialOverrides():GetTable()) do
		local matName = matOverride:GetMaterialName()
		local origMat = game.load_material(matName)
		if(origMat ~= nil) then
			local newMat = origMat:Copy()
			local data = newMat:GetDataBlock()
			for key,val in pairs(matOverride:GetOverrideValues():GetTable()) do
				local type = data:GetValueType(key)
				if(type ~= nil and val:GetType() == udm.ATTRIBUTE_TYPE_STRING) then
					if(type == "texture") then newMat:SetTexture(key,val:GetValue())
					else data:SetValue(type,key,val:GetValue()) end
				end
			end
			newMat:UpdateTextures()
			newMat:InitializeShaderDescriptorSet()
			for matIdx,matMdl in ipairs(materials) do
				if(matMdl:GetName() == origMat:GetName()) then
					mdlC:SetMaterialOverride(matIdx -1,newMat)
					break
				end
			end
		end
	end

	local globalBgIdx = mdlInfo:GetBodyGroup()
	for bgIdx,bgMdlIdx in ipairs(self:GetBodyGroups(globalBgIdx)) do
		mdlC:SetBodyGroup(bgIdx -1,bgMdlIdx)
	end
end
ents.COMPONENT_PFM_MODEL = ents.register_component("pfm_model",ents.PFMModel)
