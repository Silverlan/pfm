--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMModel",BaseEntityComponent)

ents.PFMModel.CHANNEL_BONE_TRANSLATIONS = 1
ents.PFMModel.CHANNEL_BONE_ROTATIONS = 2
ents.PFMModel.CHANNEL_FLEX_CONTROLLER_TRANSFORMS = 3

ents.PFMModel.CHANNEL_COUNT = 3

ents.PFMModel.ROOT_TRANSFORM_ID = -2
function ents.PFMModel:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local animC = self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:AddEntityComponent(ents.COMPONENT_RENDER)

	-- TODO: Only add these if this is an articulated actor
	self:AddEntityComponent(ents.COMPONENT_FLEX)
	self:AddEntityComponent(ents.COMPONENT_VERTEX_ANIMATED)

	self.m_channels = {}
	self.m_channels[ents.PFMModel.CHANNEL_BONE_TRANSLATIONS] = ents.PFMModel.TranslationChannel()
	self.m_channels[ents.PFMModel.CHANNEL_BONE_ROTATIONS] = ents.PFMModel.RotationChannel()
	self.m_channels[ents.PFMModel.CHANNEL_FLEX_CONTROLLER_TRANSFORMS] = ents.PFMModel.FlexControllerChannel()

	self.m_boneIds = {}
	self.m_flexControllerIds = {}
end

function ents.PFMModel:Setup(mdlInfo)
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	local mdlName = mdlInfo:GetModelName()
	mdlC:SetModel(mdlName)
	mdlC:SetSkin(mdlInfo:GetSkin())

	local transform = mdlInfo:GetTransform()
	-- Transform information seem to be composite of other data, we'll just ignore it for now.
	-- ent:SetPos(transform:GetPosition())
	-- ent:SetRotation(transform:GetRotation())

	local actorName = self:GetEntity():GetName()
	
	-- TODO: Only if model!!
	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	
	-- Initialize bone ids
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local boneControls = animSet:GetBoneControls():GetValue()
	for _,ctrl in ipairs(boneControls) do
		local boneName = ctrl:GetName()
		local boneId = mdl:LookupBone(boneName)
		if(boneId == -1 and boneName == "rootTransform") then boneId = ents.PFMModel.ROOT_TRANSFORM_ID end -- Root transform will be handled as a special case
		table.insert(self.m_boneIds,boneId)
		if(boneId == -1) then console.print_warning("Unknown bone '" .. boneName .. "'!") end
	end
	
	-- Initialize flex controller ids
	local flexControls = animSet:GetFlexControls():GetValue()
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
	local flexControls = animSet:GetFlexControls():GetValue()
	for iCtrl,ctrl in ipairs(flexControls) do
		local flexControllerName = ctrl:GetName()
		
		local channel = ctrl:GetChannel()
		local log = channel:GetLog()
		local ctrlId = self.m_flexControllerIds[iCtrl][1]
		if(ctrlId ~= -1) then
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMModel.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
		
		channel = ctrl:GetLeftValueChannel()
		log = channel:GetLog()
		local ctrlId = self.m_flexControllerIds[iCtrl][2]
		if(ctrlId ~= -1) then
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMModel.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
		
		channel = ctrl:GetRightValueChannel()
		log = channel:GetLog()
		local ctrlId = self.m_flexControllerIds[iCtrl][3]
		if(ctrlId ~= -1) then
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMModel.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end

	print("Applying bone transforms to actor '" .. actorName .. "'...")
	local boneControls = animSet:GetBoneControls():GetValue()
	for iCtrl,ctrl in ipairs(boneControls) do
		local boneControllerName = ctrl:GetName()
		local boneId = self.m_boneIds[iCtrl]
		-- Root transform will be handled as a special case
		if(boneId ~= -1) then
			local posChannel = ctrl:GetPositionChannel()
			local log = posChannel:GetLog()
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMModel.CHANNEL_BONE_TRANSLATIONS,boneId,times[i]:GetValue(),values[i]:GetValue())
				end
			end

			local rotChannel = ctrl:GetRotationChannel()
			log = rotChannel:GetLog()
			for _,layer in ipairs(log:GetLayers():GetValue()) do
				local times = layer:GetTimes():GetValue()
				local tPrev = 0.0
				for _,t in ipairs(times) do
					tPrev = t:GetValue()
				end
				local values = layer:GetValues():GetValue()
				for i=1,#times do
					self:AddChannelTransform(ents.PFMModel.CHANNEL_BONE_ROTATIONS,boneId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end
end
ents.COMPONENT_PFM_MODEL = ents.register_component("pfm_model",ents.PFMModel)
