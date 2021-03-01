--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMActorComponent",BaseEntityComponent)

include("channel.lua") -- TODO: This is obsolete; Remove the channels!

function ents.PFMActorComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)
	self:AddEntityComponent("click")
	self:BindComponentInitEvent(ents.COMPONENT_RENDER,function(renderC)
		renderC:SetExemptFromOcclusionCulling(true)
	end)
	self.m_channels = {}
	self.m_listeners = {}

	self.m_cvAnimCache = console.get_convar("pfm_animation_cache_enabled")

	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON,"UpdateRenderMode")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF,"UpdateRenderMode")

	self:SetShouldAutoUpdatePose(true)
end

function ents.PFMActorComponent:AddChannel(channel)
	table.insert(self.m_channels,channel)
	return channel
end

function ents.PFMActorComponent:GetChannels() return self.m_channels end
function ents.PFMActorComponent:GetActorData() return self.m_actorData end

function ents.PFMActorComponent:SetShouldAutoUpdatePose(autoUpdate) self.m_autoUpdatePose = autoUpdate end

function ents.PFMActorComponent:OnRemove()
	for _,listener in ipairs(self.m_listeners) do
		if(listener:IsValid()) then listener:Remove() end
	end
end

function ents.PFMActorComponent:OnEntitySpawn()
	local actorData = self:GetActorData()

	local ent = self:GetEntity()
	ent:SetPose(actorData:GetAbsolutePose())
	local t = actorData:GetTransform()
	local update_pose = function() self:UpdatePose() end
	table.insert(self.m_listeners,t:GetPositionAttr():AddChangeListener(update_pose))
	table.insert(self.m_listeners,t:GetRotationAttr():AddChangeListener(update_pose))
	table.insert(self.m_listeners,t:GetScaleAttr():AddChangeListener(update_pose))

	table.insert(self.m_listeners,actorData:GetVisibleAttr():AddChangeListener(function(visible) self:UpdateRenderMode() end))
end

function ents.PFMActorComponent:UpdatePose()
	if(self.m_autoUpdatePose ~= true) then return end
	local actorData = self:GetActorData()
	local pose = actorData:GetAbsolutePose()

	--print("Pose: ",pose:GetOrigin())
	--print(actorData:GetParents()[1]:GetParents()[1]:GetTransform():GetPosition())
	--print(actorData:FindParentElement())
	--print(actorData:GetTransform():GetPosition())
	self:GetEntity():SetPose(pose)
end

function ents.PFMActorComponent:SetDefaultRenderMode(renderMode)
	self.m_defaultRenderMode = renderMode
	self:UpdateRenderMode()
end

function ents.PFMActorComponent:GetDefaultRenderMode() return self.m_defaultRenderMode end

function ents.PFMActorComponent:UpdateRenderMode()
	local actorData = self:GetActorData()
	local renderMode
	if(self:GetEntity():IsTurnedOff()) then renderMode = ents.RenderComponent.RENDERMODE_NONE
	else
		renderMode = self.m_defaultRenderMode or ents.RenderComponent.RENDERMODE_WORLD
		if(actorData:IsAbsoluteVisible() == false) then
			renderMode = ents.RenderComponent.RENDERMODE_NONE
		end
	end
	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then renderC:SetRenderMode(renderMode) end
end

function ents.PFMActorComponent:OnOffsetChanged(clipOffset,gameViewFlags)
	local ent = self:GetEntity()
	if(bit.band(gameViewFlags,ents.PFMProject.GAME_VIEW_FLAG_BIT_USE_CACHE) == ents.PFMProject.GAME_VIEW_FLAG_NONE) then
		self:UpdatePose()
		self:UpdateOperators()
	end

	self:UpdateRenderMode()
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
	self:BroadcastEvent(ents.PFMActorComponent.EVENT_ON_OFFSET_CHANGED,{clipOffset})

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
	local poseOffset = phys.Transform(offset,rotOffset)
	target = target:GetTarget()
	local pose = (target ~= nil) and pfm.util.get_absolute_pose(target) or phys.Transform()
	if(opType == fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR or opType == fudm.ELEMENT_TYPE_PFM_RIG_PARENT_CONSTRAINT_OPERATOR) then
		pose:TranslateGlobal(offset)
	elseif(opType == fudm.ELEMENT_TYPE_PFM_RIG_ROTATION_CONSTRAINT_OPERATOR or opType == fudm.ELEMENT_TYPE_PFM_RIG_PARENT_CONSTRAINT_OPERATOR) then
		pose:RotateLocal(rotOffset)
	end
	-- pose = poseOffset *pose -- TODO: Not sure about this
	return pose
end]]
function ents.PFMActorComponent:UpdateOperators()
	local actorData = self:GetActorData()
	if(actorData == nil) then return end
	local operators = actorData:GetOperators():GetTable()
	for _,op in ipairs(operators) do
		local slave = op:GetSlave()
		local slaveTarget = (slave ~= nil) and slave:GetTarget() or nil
		if(slaveTarget ~= nil) then
			local slaveTargetTransform = slaveTarget:GetTransform()
			-- debug.draw_pose(slaveTarget:GetAbsoluteParentPose(),12)
			local poseBase = slaveTarget:GetAbsoluteParentPose():GetInverse()

			local poseConstraint = phys.Transform()
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
	end
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
				local pose = slaveTargetTransform:GetPose() *phys.Transform(slave:GetPosition(),slave:GetRotation())
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

function ents.PFMActorComponent:Setup(actorData)
	self.m_actorData = actorData
	self:GetEntity():SetName(actorData:GetName())

	pfm.log("Initializing " .. #actorData:GetComponents() .. " components for actor '" .. self:GetEntity():GetName() .. "'...",pfm.LOG_CATEGORY_PFM_GAME)
	for _,value in ipairs(actorData:GetComponents():GetTable()) do
		local componentData = value
		local err
		if(componentData.GetComponentName == nil) then
			err = "Component is missing method 'GetComponentName'"
		end
		if(err ~= nil) then
			pfm.log("Attempted to add malformed component '" .. componentData:GetTypeName() .. "' to actor '" .. self:GetEntity():GetName() .. "': " .. err .. "!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_ERROR)
		else
			local c = self:AddEntityComponent(componentData:GetComponentName())
			if(c == nil) then pfm.log("Attempted to add unknown component '" .. componentData:GetComponentName() .. "' to actor '" .. self:GetEntity():GetName() .. "'!",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
			else c:Setup(actorData,componentData) end
		end
	end
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",ents.PFMActorComponent)
ents.PFMActorComponent.EVENT_ON_OFFSET_CHANGED = ents.register_component_event(ents.COMPONENT_PFM_ACTOR,"on_offset_changed")
