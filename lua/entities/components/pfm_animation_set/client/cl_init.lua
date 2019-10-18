--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMAnimationSet",BaseEntityComponent)

include("channel")

ents.PFMAnimationSet.ROOT_TRANSFORM_ID = -2
function ents.PFMAnimationSet:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	local animC = self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:AddEntityComponent(ents.COMPONENT_RENDER)

	-- TODO: Only add these if this is an articulated actor
	self:AddEntityComponent(ents.COMPONENT_FLEX)
	self:AddEntityComponent(ents.COMPONENT_VERTEX_ANIMATED)
	local actorC = self:AddEntityComponent("pfm_actor")
	self.m_translationChannel = actorC:AddChannel(ents.PFMActorComponent.TranslationChannel())
	self.m_rotationChannel = actorC:AddChannel(ents.PFMActorComponent.RotationChannel())
	self.m_boneTranslationChannel = actorC:AddChannel(ents.PFMAnimationSet.BoneTranslationChannel(self))
	self.m_boneRotationChannel = actorC:AddChannel(ents.PFMAnimationSet.BoneRotationChannel(self))
	self.m_flexControllerChannel = actorC:AddChannel(ents.PFMAnimationSet.FlexControllerChannel())

	self.m_cbUpdateSkeleton = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
		-- We have to apply our bone transforms every time the entity's skeleton/animations have been updated
		self:ApplyBoneTransforms()
	end)

	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	self.m_currentBoneTransforms = {}
end

function ents.PFMAnimationSet:OnRemove()
	if(util.is_valid(self.m_cbUpdateSkeleton)) then self.m_cbUpdateSkeleton:Remove() end
end

function ents.PFMAnimationSet:SetBonePos(boneId,pos)
	self.m_currentBoneTransforms[boneId] = self.m_currentBoneTransforms[boneId] or {Vector(),Quaternion()}
	self.m_currentBoneTransforms[boneId][1] = pos
end

function ents.PFMAnimationSet:SetBoneRot(boneId,rot)
	self.m_currentBoneTransforms[boneId] = self.m_currentBoneTransforms[boneId] or {}
	self.m_currentBoneTransforms[boneId][2] = rot
end

function ents.PFMAnimationSet:ApplyBoneTransforms()
	local ent = self:GetEntity()
	local animC = ent:GetComponent(ents.COMPONENT_ANIMATED)
	local transformC = ent:GetComponent(ents.COMPONENT_TRANSFORM)
	if(transformC == nil or animC == nil) then return end
	for boneId,t in pairs(self.m_currentBoneTransforms) do
		if(boneId == ents.PFMAnimationSet.ROOT_TRANSFORM_ID) then
			if(t[1] ~= nil) then transformC:SetPos(t[1]) end
			if(t[2] ~= nil) then transformC:SetRotation(t[2]) end
		else
			if(t[1] ~= nil) then animC:SetBonePos(boneId,t[1]) end
			if(t[2] ~= nil) then animC:SetBoneRot(boneId,t[2]) end
		end
	end
end

function ents.PFMAnimationSet:OnEntitySpawn()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		animC:PlayAnimation("reference") -- Play reference animation to make sure animation callbacks are being called
	end
end

function ents.PFMAnimationSet:Setup(actorData,animSet)
	local ent = self:GetEntity()

	local actorName = self:GetEntity():GetName()
	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	
	-- Initialize bone ids
	local mdl = ent:GetModel()
	if(mdl ~= nil) then
		local boneControls = animSet:GetTransformControls()
		for _,ctrl in ipairs(boneControls) do
			local boneName = ctrl:GetName()
			local boneId = mdl:LookupBone(boneName)
			if(boneId == -1 and boneName == "rootTransform") then boneId = ents.PFMAnimationSet.ROOT_TRANSFORM_ID end -- Root transform will be handled as a special case (i.e. for translating/rotating the actual entity)
			table.insert(self.m_boneIds,boneId)
			if(boneId == -1) then console.print_warning("Unknown bone '" .. boneName .. "'!") end
		end
		
		-- Initialize flex controller ids
		local flexControls = animSet:GetFlexControls()
		for _,ctrl in ipairs(flexControls) do
			local flexControllerName = ctrl:GetName()
			local ids = {
				mdl:LookupFlexController(flexControllerName),
				mdl:LookupFlexController("left_" .. flexControllerName),
				mdl:LookupFlexController("right_" .. flexControllerName)
			}
			table.insert(self.m_flexControllerIds,ids)
			if(ids[1] == -1) then console.print_warning("Unknown flex controller '" .. flexControllerName .. "'!") end
			if(ids[2] == -1) then console.print_warning("Unknown flex controller 'left_" .. flexControllerName .. "'!") end
			if(ids[3] == -1) then console.print_warning("Unknown flex controller 'right_" .. flexControllerName .. "'!") end
		end
		
		print("Applying flex transforms to actor '" .. actorName .. "'...")
		local flexControls = animSet:GetFlexControls()
		for iCtrl,ctrl in ipairs(flexControls) do
			local flexControllerName = ctrl:GetName()
			
			local channel = ctrl:GetChannel()
			local log = channel:GetLog()
			local ctrlId = self.m_flexControllerIds[iCtrl][1]
			if(ctrlId ~= -1) then
				self.m_flexControllerChannel:SetDefault(ctrlId,ctrl:GetValue())
				for _,layer in ipairs(log:GetLayers()) do
					local times = layer:GetTimes()
					local values = layer:GetValues()
					for i=1,#times do
						self.m_flexControllerChannel:AddTransform(ctrlId,times[i]:GetValue(),values[i]:GetValue())
					end
				end
			end
			
			channel = ctrl:GetLeftValueChannel()
			log = channel:GetLog()
			local ctrlId = self.m_flexControllerIds[iCtrl][2]
			if(ctrlId ~= -1) then
				self.m_flexControllerChannel:SetDefault(ctrlId,ctrl:GetLeftValue())
				for _,layer in ipairs(log:GetLayers()) do
					local times = layer:GetTimes()
					local values = layer:GetValues()
					for i=1,#times do
						self.m_flexControllerChannel:AddTransform(ctrlId,times[i]:GetValue(),values[i]:GetValue())
					end
				end
			end
			
			channel = ctrl:GetRightValueChannel()
			log = channel:GetLog()
			local ctrlId = self.m_flexControllerIds[iCtrl][3]
			if(ctrlId ~= -1) then
				self.m_flexControllerChannel:SetDefault(ctrlId,ctrl:GetRightValue())
				for _,layer in ipairs(log:GetLayers()) do
					local times = layer:GetTimes()
					local values = layer:GetValues()
					for i=1,#times do
						self.m_flexControllerChannel:AddTransform(ctrlId,times[i]:GetValue(),values[i]:GetValue())
					end
				end
			end
		end
	end

	print("Applying bone transforms to actor '" .. actorName .. "'...")
	local transformControls = animSet:GetTransformControls()
	for iCtrl,ctrl in ipairs(transformControls) do
		local boneControllerName = ctrl:GetName()
		if(boneControllerName ~= "transform") then -- Transform control is handled by actor component
			local boneId = self.m_boneIds[iCtrl]
			-- Root transform will be handled as a special case
			if(boneId ~= -1) then
				local posChannel = ctrl:GetPositionChannel()
				self.m_boneTranslationChannel:SetDefault(boneId,ctrl:GetValuePosition())
				local log = posChannel:GetLog()
				for _,layer in ipairs(log:GetLayers()) do
					local times = layer:GetTimes()
					local values = layer:GetValues()
					for i=1,#times do
						self.m_boneTranslationChannel:AddTransform(boneId,times[i]:GetValue(),values[i]:GetValue())
					end
				end

				local rotChannel = ctrl:GetRotationChannel()
				self.m_boneRotationChannel:SetDefault(boneId,ctrl:GetValueRotation())
				log = rotChannel:GetLog()
				for _,layer in ipairs(log:GetLayers()) do
					local times = layer:GetTimes()
					local tPrev = 0.0
					for _,t in ipairs(times) do
						tPrev = t:GetValue()
					end
					local values = layer:GetValues()
					for i=1,#times do
						self.m_boneRotationChannel:AddTransform(boneId,times[i]:GetValue(),values[i]:GetValue())
					end
				end
			end
		end
	end

	-- Position / rotation transform controls
	local transformControls = animSet:GetTransformControls()
	for iCtrl,ctrl in ipairs(transformControls) do
		local boneControllerName = ctrl:GetName()
		if(boneControllerName == "transform") then
			local posChannel = ctrl:GetPositionChannel()
			self.m_translationChannel:SetDefault(0,ctrl:GetValuePosition())
			local log = posChannel:GetLog()
			for _,layer in ipairs(log:GetLayers()) do
				local times = layer:GetTimes()
				local values = layer:GetValues()
				for i=1,#times do
					self.m_translationChannel:AddTransform(0,times[i]:GetValue(),values[i]:GetValue())
				end
			end

			local rotChannel = ctrl:GetRotationChannel()
			self.m_rotationChannel:SetDefault(0,ctrl:GetValueRotation())
			log = rotChannel:GetLog()
			for _,layer in ipairs(log:GetLayers()) do
				local times = layer:GetTimes()
				local tPrev = 0.0
				for _,t in ipairs(times) do
					tPrev = t:GetValue()
				end
				local values = layer:GetValues()
				for i=1,#times do
					self.m_rotationChannel:AddTransform(0,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end
end
ents.COMPONENT_PFM_ANIMATION_SET = ents.register_component("pfm_animation_set",ents.PFMAnimationSet)
