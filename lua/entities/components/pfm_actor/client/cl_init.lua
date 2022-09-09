--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMActorComponent",BaseEntityComponent)

-- include("channel.lua") -- TODO: This is obsolete; Remove the channels!

Component:RegisterMember("Position",udm.TYPE_VECTOR3,Vector(0,0,0),{
	onChange = function(self)
		self:UpdatePosition()
	end
})
Component:RegisterMember("Rotation",udm.TYPE_QUATERNION,Quaternion(),{
	onChange = function(self)
		self:UpdateRotation()
	end
})
Component:RegisterMember("Scale",udm.TYPE_VECTOR3,Vector(1,1,1),{
	onChange = function(self)
		self:UpdateScale()
	end
})
Component:RegisterMember("Visible",udm.TYPE_BOOLEAN,true,{
	onChange = function(self)
		self:UpdateVisibility()
	end
},bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))
Component:RegisterMember("Static",udm.TYPE_BOOLEAN,false,{},bit.bor(ents.BaseEntityComponent.MEMBER_FLAG_DEFAULT,ents.BaseEntityComponent.MEMBER_FLAG_BIT_USE_IS_GETTER))

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)
	self:AddEntityComponent("click")
	self:BindComponentInitEvent(ents.COMPONENT_RENDER,function(renderC)
		renderC:SetExemptFromOcclusionCulling(true)
	end)
	self.m_listeners = {}

	self.m_cvAnimCache = console.get_convar("pfm_animation_cache_enabled")

	self.m_boneChannels = {}
	self.m_flexControllerChannels = {}
	self.m_selected = false
end
function Component:IsSelected() return self.m_selected end
function Component:SetSelected(selected)
	if(selected == self.m_selected) then return end
	self.m_selected = selected
	self:BroadcastEvent(Component.EVENT_ON_SELECTION_CHANGED,{selected})
end
function Component:UpdateVisibility()
	local visible = self:IsVisible() and self:GetActorData():IsAbsoluteVisible() or false
	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then
		if(visible == false) then
			self.m_origSceneRenderPass = self.m_origSceneRenderPass or renderC:GetSceneRenderPass()
			renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE)
		elseif(renderC:GetSceneRenderPass() == game.SCENE_RENDER_PASS_NONE or self.m_origSceneRenderPass ~= nil) then
			renderC:SetSceneRenderPass(self.m_origSceneRenderPass or game.SCENE_RENDER_PASS_WORLD)
		end
	end

	self:BroadcastEvent(Component.EVENT_ON_VISIBILITY_CHANGED,{visible})
end
function Component:UpdatePosition()
	local pose = self:GetActorData():GetAbsoluteParentPose()
	pose:TranslateLocal(self:GetPosition())
	self:GetEntity():SetPos(pose:GetOrigin())
end
function Component:UpdateRotation()
	local pose = self:GetActorData():GetAbsoluteParentPose()
	pose:RotateLocal(self:GetRotation())
	self:GetEntity():SetRotation(pose:GetRotation())
end
function Component:UpdateScale()
	local pose = self:GetActorData():GetAbsoluteParentPose()
	self:GetEntity():SetScale(pose:GetScale() *self:GetScale())
end
function Component:SetBoneChannel(boneId,attr,channel)
	if(type(boneId) == "string") then
		local mdl = self:GetEntity():GetModel()
		if(mdl == nil) then return end
		boneId = mdl:LookupBone(boneId)
		if(boneId == -1) then return end
	end
	self.m_boneChannels[boneId] = self.m_boneChannels[boneId] or {}
	self.m_boneChannels[boneId][attr] = channel
end
function Component:GetBoneChannel(boneId,attr)
	return self.m_boneChannels[boneId] and self.m_boneChannels[boneId][attr] or nil
end
function Component:SetFlexControllerChannel(flexControllerId,channel)
	self.m_flexControllerChannels[flexControllerId] = channel
end
function Component:GetFlexControllerChannel(flexControllerId)
	return self.m_flexControllerChannels[flexControllerId]
end

function Component:GetActorData() return self.m_actorData end

function Component:OnRemove()
	for _,listener in ipairs(self.m_listeners) do
		if(listener:IsValid()) then listener:Remove() end
	end
end

function Component:OnEntitySpawn()
	local actorData = self:GetActorData()
	if(actorData == nil) then return end
	local ent = self:GetEntity()
	ent:SetPose(actorData:GetAbsolutePose())

	self:InitializeComponentProperties()
end

function Component:SetDefaultRenderMode(renderMode,useIfTurnedOff)
	self.m_defaultRenderMode = renderMode
	self.m_useDefaultRenderModeIfTurnedOff = useIfTurnedOff
end

function Component:GetDefaultRenderMode() return self.m_defaultRenderMode end

function Component:OnOffsetChanged(clipOffset,gameViewFlags)
	local ent = self:GetEntity()
	if(bit.band(gameViewFlags,ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE) == ents.PFMProject.GAME_VIEW_FLAG_NONE) then
		--self:UpdatePose()
		self:UpdateOperators()
	end

	--print(ent,ent:GetPos())
	--[[self.m_oldOffset = self.m_oldOffset or clipOffset
	local newOffset = clipOffset
	local tDelta = newOffset -self.m_oldOffset
	self.m_oldOffset = newOffset

	print("Actor offset changed: ",clipOffset)
	
	local ent = self:GetEntity()
	for _,channel in ipairs(self:GetChannels()) do
		channel:Apply(ent,newOffset)
	end]]
	self:BroadcastEvent(Component.EVENT_ON_OFFSET_CHANGED,{clipOffset})

	--[[local actorData = self:GetActorData()
	if(actorData == nil) then return end
	local operators = actorData:GetOperators()
	for _,op in ipairs(operators:GetTable()) do
		local targets = op:GetTargets()
		for _,constraintTarget in ipairs(targets:GetTable()) do
			local target = constraintTarget:GetTarget()

		end

		local slave = op:GetSlave()
		local target = (slave ~= nil) and slave:GetTarget() or nil
		if(target ~= nil) then
			local pos = slave:GetPosition()
			local rot = slave:GetRotation()
			
		end
	end]]
end

--[[local function get_target_value(target,opType)
	local offset = target:GetOffset()
	local rotOffset = target:GetRotationOffset()

	--sfm.convert_source_anim_set_position_to_pragma(sfmTarget:GetVecOffset())
	local poseOffset = math.Transform(offset,rotOffset)
	target = target:GetTarget()
	local pose = (target ~= nil) and pfm.util.get_absolute_pose(target) or math.Transform()
	if(opType == fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR or opType == fudm.ELEMENT_TYPE_PFM_RIG_PARENT_CONSTRAINT_OPERATOR) then
		pose:TranslateGlobal(offset)
	elseif(opType == fudm.ELEMENT_TYPE_PFM_RIG_ROTATION_CONSTRAINT_OPERATOR or opType == fudm.ELEMENT_TYPE_PFM_RIG_PARENT_CONSTRAINT_OPERATOR) then
		pose:RotateLocal(rotOffset)
	end
	-- pose = poseOffset *pose -- TODO: Not sure about this
	return pose
end]]
function Component:UpdateOperators()
	-- TODO: Operators should be deprecated
	local actorData = self:GetActorData()
	if(actorData == nil) then return end
	--[[local operators = actorData:GetOperators():GetTable()
	for _,op in ipairs(operators) do
		local slave = op:GetSlave()
		local slaveTarget = (slave ~= nil) and slave:GetTarget() or nil
		if(slaveTarget ~= nil) then
			local slaveTargetTransform = slaveTarget:GetTransform()
			-- debug.draw_pose(slaveTarget:GetAbsoluteParentPose(),12)
			local poseBase = slaveTarget:GetAbsoluteParentPose():GetInverse()

			local poseConstraint = math.Transform()
			op:ApplyConstraint(poseConstraint)
			--local poseConstraint = slaveTarget:GetConstraintPose()

			--local poseConstraint = slaveTarget:GetAbsoluteParentPose(nil,true)
			--print("PC" ,poseConstraint:GetRotation(),Quaternion(0.70710504055023,-0.70710849761963,-2.9802382783828e-08,-3.427267074585e-06))
			--poseConstraint:SetRotation(Quaternion(0.70710504055023,-0.70710849761963,-2.9802382783828e-08,-3.427267074585e-06))
			local pose = poseBase *poseConstraint
			-- Should be unit quaternion for actor 32
			if(op:GetType() == fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR) then
				slaveTargetTransform:SetPosition(pose:GetOrigin())
			elseif(op:GetType() == fudm.ELEMENT_TYPE_PFM_RIG_ROTATION_CONSTRAINT_OPERATOR) then
				slaveTargetTransform:SetRotation(pose:GetRotation())
			else
				slaveTargetTransform:SetPose(pose)
			end
		end
	end]]
	--[[local actorData = self:GetActorData()
	if(actorData == nil) then return end
	local operators = actorData:GetOperators()
	for _,op in ipairs(operators:GetTable()) do
		--print(op:GetTypeName())
		--if(op:GetName() == "pointConstraint_rootTransform") then
			--local transform = op:GetSlave():GetTarget():GetTransform()
			--print(transform:GetPosition(),transform:GetRotation())
			local slave = op:GetSlave()
			local slaveTarget = (slave ~= nil) and slave:GetTarget() or nil
			if(slaveTarget ~= nil) then
				local slaveTargetTransform = slaveTarget:GetTransform()
				print("slaveTarget: ",slaveTarget)
				local pose = pfm.util.get_absolute_parent_pose(slaveTarget):GetInverse()

				local targetPose = get_target_value(op:GetTargets():Get(1),op:GetType())
				pose = pose *targetPose

				if(op:GetType() == fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR) then
					slaveTargetTransform:SetPosition(pose:GetOrigin())
				elseif(op:GetType() == fudm.ELEMENT_TYPE_PFM_RIG_ROTATION_CONSTRAINT_OPERATOR) then
					slaveTargetTransform:SetRotation(pose:GetRotation())
				else
					slaveTargetTransform:SetPose(pose)
				end]]

				--slaveTargetTransform:SetPose(pose *targetPose)

				--[[local slaveTargetTransform = slaveTarget:GetTransform()
				local pose = slaveTargetTransform:GetPose() *math.Transform(slave:GetPosition(),slave:GetRotation())
				--local absPose = slave:GetAbsoluteBonePose()
				--absPose:TransformGlobal(pose:GetInverse()) -- TODO
				--absPose = absPose:TransformGlobal() -- Inverse parent pose

				pose = pfm.util.get_absolute_pose(slaveTargetTransform):GetInverse() *pose

				local targetPose = get_target_value(op:GetTargets():Get(1))]]
				--targetPose = targetPose *pose

				--[[for _,target in ipairs(op:GetTargets():GetTable()) do
					-- TODO: Apply weight
					local targetPose = get_target_value(target)
					if(op:GetType() == fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR) then
						pose:TranslateGlobal(targetPose:GetOrigin())
					elseif(op:GetType() == fudm.ELEMENT_TYPE_PFM_RIG_ROTATION_CONSTRAINT_OPERATOR) then
						pose:RotateGlobal(targetPose:GetRotation())
					else
						pose:TransformGlobal(targetPose)
					end
				end]]
				--slaveTargetTransform:SetPose(pose)
			--end
		--end
	--end
end

function Component:ApplyComponentMemberValue(path)
	local componentName,componentPath = ents.PanimaComponent.parse_component_channel_path(panima.Channel.Path(path))
	if(componentName == nil) then return end
	local actorData = self:GetActorData()
	local componentData = actorData:FindComponent(componentName)
	if(componentData == nil) then return end
	local val = componentData:GetMemberValue(componentPath:GetString())
	if(val == nil) then return end
	self:GetEntity():SetMemberValue(path,val)
end

function Component:InitializeComponentProperties()
	local actorData = self:GetActorData()
	pfm.log("Initializing " .. #actorData:GetComponents() .. " components for actor '" .. self:GetEntity():GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	for _,value in ipairs(actorData:GetComponents()) do
		local componentData = value
		local componentName = componentData:GetType()
		local c
		if(componentName ~= "pfm_actor") then
			c = self:AddEntityComponent(componentName)
			if(c == nil) then pfm.log("Attempted to add unknown component '" .. componentData:GetComponentName() .. "' to actor '" .. self:GetEntity():GetName() .. "'!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
			elseif(c.Setup ~= nil) then c:Setup(actorData,componentData) end
		else c = self end

		local isModelComponent = (componentName == "model")

		-- Initialize component member values
		local function applyProperties(el,path)
			if(isModelComponent and path == nil) then
				-- HACK: For the model component, the model has to be applied *before* other properties (like the skin or bodygroups).
				-- Since the UDM properties are unordered, we'll have to handle it as a special case.
				-- TODO: Find a better way to handle this (via schema properties?)
				local mdl = el:GetValue("model",udm.TYPE_STRING)
				if(mdl ~= nil) then self:GetEntity():SetModel(mdl) end
			end
			path = path or ""
			for name,udmVal in pairs(el:GetChildren()) do
				if(not isModelComponent or name ~= "model") then
					local childPath = path
					if(#childPath > 0) then childPath = childPath .. "/" end
					childPath = childPath .. name
					if(udmVal:GetType() == udm.TYPE_ELEMENT) then
						applyProperties(udmVal,childPath)
					else
						local val = udmVal:GetValue()
						if(val == nil) then pfm.log("Attempted to apply member value for unknown member '" .. childPath .. "' of component '" .. componentName .. "'! Ignoring...",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
						else
							if(c:SetMemberValue(childPath,val) == false) then
								pfm.log("Failed to apply member value for unknown member '" .. childPath .. "' of component '" .. componentName .. "'!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
							end
						end
					end
				end
			end
		end
		applyProperties(componentData:GetProperties())
	end
	self:UpdateVisibility()
end

function Component:Setup(actorData)
	self.m_actorData = actorData
	self:GetEntity():SetName(actorData:GetName())
	self:GetEntity():SetUuid(actorData:GetUniqueId())
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",Component)
Component.EVENT_ON_OFFSET_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_ACTOR,"on_offset_changed")
Component.EVENT_ON_VISIBILITY_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_ACTOR,"on_visibility_changed")
Component.EVENT_ON_SELECTION_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_ACTOR,"on_selection_changed")
