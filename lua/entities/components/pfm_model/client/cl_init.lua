-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

console.register_variable(
	"pfm_experimental_use_hitbox_bvh",
	udm.TYPE_BOOLEAN,
	false,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Use hitbox BVH for PFM actors."
)

local Component = util.register_class("ents.PFMModel", BaseEntityComponent)

Component:RegisterMember("MaterialOverrides", ents.MEMBER_TYPE_ELEMENT, "", {
	onChange = function(self)
		self:UpdateMaterialOverrides()
	end,
}, bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT))

function ents.PFMModel:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local renderC = self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent("pfm_actor")
	if renderC ~= nil then
		renderC:SetCastShadows(true)
	end

	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED, "UpdateModel")
	self:BindEvent(ents.BaseStaticBvhUserComponent.EVENT_ON_ACTIVATION_STATE_CHANGED, "UpdateBvhState")
	self:BindEvent(ents.AnimatedComponent.EVENT_MAINTAIN_ANIMATIONS, "MaintainAnimations")
	self.m_listeners = {}
end
function ents.PFMModel:OnEntitySpawn()
	self:UpdateMaterialOverrides()
	self:UpdateBvhState()
end
function ents.PFMModel:UpdateMaterialOverrides()
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	local matOverrideC = self:GetEntity():GetComponent(ents.COMPONENT_MATERIAL_OVERRIDE)
	if mdlC == nil or matOverrideC == nil then
		return
	end
	matOverrideC:ClearMaterialOverrides()
	local udmMatOverrides = self:GetMaterialOverrides():Get("materialOverrides")
	for _, udmMatOverride in ipairs(udmMatOverrides:GetArrayValues()) do
		local srcMaterial = udmMatOverride:GetValue("srcMaterial", udm.TYPE_STRING)
		local dstMaterial = udmMatOverride:GetValue("dstMaterial", udm.TYPE_STRING) or ""
		if srcMaterial ~= nil and #srcMaterial > 0 then
			local matOverride

			local udmOverride = udmMatOverride:Get("override")
			local children = udmOverride:GetChildren()
			local shaderName, properties = pairs(children)(children)
			if shaderName ~= nil then
				local matRef
				if #dstMaterial > 0 then
					matRef = dstMaterial
				else
					matRef = srcMaterial
				end

				matRef = asset.load(matRef, asset.TYPE_MATERIAL)
				if util.is_valid(matRef) then
					-- TODO: Update shader
					local cpy = matRef:Copy()
					cpy:MergePropertyDataBlock(properties)
					cpy:ReloadTextures()
					cpy:InitializeShaderDescriptorSet(true)
					matOverride = cpy
				end
			else
				matOverride = asset.load(dstMaterial, asset.TYPE_MATERIAL)
			end

			if util.is_valid(matOverride) then
				matOverrideC:SetMaterialOverride(srcMaterial, matOverride)
			else
				self:LogWarn(
					"Failed to apply material override for material '"
						.. srcMaterial
						.. "': Target material is not valid!"
				)
			end
		end
	end
	mdlC:UpdateRenderMeshes()
end
function ents.PFMModel:UpdateBvhState()
	if self:GetEntity():IsSpawned() == false then
		return
	end
	local c = self:GetEntityComponent(ents.COMPONENT_STATIC_BVH_USER)
	if
		c ~= nil --[[and c:IsActive()]]
	then
		-- Remove the BVH component, but only if it's managed by us (static bvh may manage BVH component separately)
		if util.is_valid(self.m_bvhC) then
			self:GetEntity():RemoveComponent(ents.COMPONENT_BVH)
			self:GetEntity():RemoveComponent(ents.COMPONENT_HITBOX_BVH)
		end
	else
		local bvhType = ents.COMPONENT_HITBOX_BVH
		local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_EDITOR_ACTOR)
		if actorC ~= nil and console.get_convar_bool("pfm_experimental_use_hitbox_bvh") == false then
			-- If we're in the editor, we'll use the regular BVH component, which is
			-- much more accurate but also much slower.
			bvhType = ents.COMPONENT_BVH
		end
		self.m_bvhC = self:GetEntity():AddComponent(bvhType)
	end
end
function ents.PFMModel:OnRemove()
	util.remove(self.m_listeners)
end
function ents.PFMModel:SetAnimationFrozen(frozen)
	self.m_animFrozen = frozen
end
function ents.PFMModel:IsAnimationFrozen()
	return self.m_animFrozen or false
end
function ents.PFMModel:MaintainAnimations()
	-- Disable default skeletal animation playback
	return util.EVENT_REPLY_HANDLED
end
function ents.PFMModel:InitModel()
	local modelData = self:GetModelData()
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	local mdl = (mdlC ~= nil) and mdlC:GetModel() or nil
	if mdl == nil then
		return
	end
	--local animSetC = (not mdl:HasFlag(game.Model.FLAG_BIT_INANIMATE)) and self:AddEntityComponent("pfm_animation_set") or nil
	--if(animSetC == nil) then return end -- TODO: What if flexes, but no bones? (Animation component shouldn't be needed in this case)
	--animSetC:Setup(self:GetActorData())

	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	if animC ~= nil then
		--[[local function apply_bone_transforms(entInvPose,bone)
			local boneName = bone:GetName()
			local boneId = mdl:LookupBone(boneName) -- TODO: Cache this
			if(boneId ~= -1) then
				local pose = entInvPose *bone:GetTransform():GetAbsolutePose()
				animC:SetEffectiveBonePose(boneId,pose)
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
			local testPose = math.Transform()
			local function iterate_skeleton(bone,parentPose)
				local boneName = bone:GetName()
				local boneId = mdl:LookupBone(boneName) -- TODO: Cache bone id
				local pose = parentPose *testPose
				for _,child in ipairs(bone:GetChildBones():GetTable()) do
					iterate_skeleton(child,pose)
				end
			end
			local pose = math.ScaledTransform()
			for _,bone in ipairs(modelData:GetRootBones():GetTable()) do
				iterate_skeleton(bone,pose)
			end
		end)]]
	end

	--[[for _,bone in ipairs(bones) do
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
			self:LogWarn("Unknown bone '" .. boneName .. "' for actor with model '" .. mdl:GetName() .. "'! Bone pose will be ignored...")
		end
	end

	local flexWeights = modelData:GetFlexWeights():GetTable()
	-- Flex controller names are only specified sometimes?
	local globalFlexControllers = modelData:GetGlobalFlexControllers()
	local flexNames = modelData:GetFlexControllerNames():GetTable()
	for i,fc in ipairs(globalFlexControllers:GetTable()) do
		if(flexNames[i] == nil) then self:LogWarn("Missing flex controller name for flex controller " .. i .. " for actor with model '" .. mdl:GetName() .. "'! Flex controller will be ignored...")
		else
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
				self:LogWarn("Unknown flex controller '" .. fc:GetName() .. "' for actor with model '" .. mdl:GetName() .. "'! Flex controller will be ignored...")
			end
		end
	end

	-- TODO: Init value
	table.insert(self.m_listeners,modelData:GetFlexControllerScaleAttr():AddChangeListener(function(newScale)
		local flexC = self:GetEntity():GetComponent(ents.COMPONENT_FLEX)
		if(flexC ~= nil) then flexC:SetFlexControllerScale(newScale) end
	end))]]
end
function ents.PFMModel:GetModelData()
	return self.m_mdlInfo
end
function ents.PFMModel:GetActorData()
	return self.m_actorData
end

-- Calculates local bodygroup indices from a global bodygroup index
function ents.PFMModel:GetBodyGroups(bgIdx)
	local mdl = self:GetEntity():GetModel()
	if mdl == nil then
		return {}
	end
	local bodyGroups = mdl:GetBodyGroups()

	-- Calculate total number of bodygroup combinations
	local numCombinations = 1
	for _, bg in ipairs(bodyGroups) do
		numCombinations = numCombinations * #bg.meshGroups
	end

	local localBgIndices = {}
	for i = #bodyGroups, 1, -1 do
		local bg = bodyGroups[i]
		numCombinations = numCombinations / #bg.meshGroups
		local localBgIdx = math.floor(bgIdx / numCombinations)
		bgIdx = bgIdx % numCombinations

		-- TODO: This is in reverse order because that's how it's done in the SFM,
		-- but there's really no reason to. Instead the global index should be inversed
		-- in the SFM->PFM conversion script!
		table.insert(localBgIndices, 1, localBgIdx)
	end
	return localBgIndices
end

function ents.PFMModel:UpdateModel()
	self:InitModel()

	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	local mdlInfo = self.m_mdlInfo
	if mdlInfo ~= nil then
		mdlC:SetSkin(mdlInfo:GetMemberValue("skin") or 0)
	end
	local mdl = mdlC:GetModel()
	if mdl == nil then
		return
	end
	if mdl:GetEyeballCount() > 0 then
		self:AddEntityComponent(ents.COMPONENT_EYE)
	end
	local materials = mdl:GetMaterials()
	-- debug.print("Override")
	-- console.print_table(mdlInfo:GetMaterialMappings():GetTable())
	--[[for matSrc,matDst in pairs(mdlInfo:GetMaterialMappings():GetTable()) do
		mdlC:SetMaterialOverride(matSrc,matDst:GetValue())
	end
	for _,matOverride in ipairs(mdlInfo:GetMaterialOverrides():GetTable()) do
		local matName = matOverride:GetMaterialName()
		local origMat = game.load_material(matName)
		if(origMat ~= nil) then
			local newMat = origMat:Copy()
			local data = newMat:GetPropertyDataBlock()
			for key,val in pairs(matOverride:GetOverrideValues():GetTable()) do
				local type = data:GetValueType(key)
				if(type ~= nil and val:GetType() == fudm.ATTRIBUTE_TYPE_STRING) then
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
	end]]
end

function ents.PFMModel:Setup(actorData, mdlInfo)
	self.m_mdlInfo = actorData:FindComponent("model")
	self.m_actorData = actorData
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil or self.m_mdlInfo == nil then
		return
	end
	--[[table.insert(self.m_listeners,self.m_mdlInfo:AddChangeListener("model",function(c,newModel)
		local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
		if(mdlC ~= nil) then mdlC:SetModel(newModel) end
	end))
	table.insert(self.m_listeners,self.m_mdlInfo:AddChangeListener("skin",function(c,newSkin) ent:SetSkin(newSkin) end))
	mdlC:SetModel(self.m_mdlInfo:GetMemberValue("model") or "")]]
end
ents.register_component("pfm_model", ents.PFMModel, "rendering/model")
