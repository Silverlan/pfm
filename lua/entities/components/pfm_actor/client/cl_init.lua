util.register_class("ents.PFMActorComponent",BaseEntityComponent)

ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS = 1
ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS = 2
ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS = 3

ents.PFMActorComponent.CHANNEL_COUNT = 3

ents.PFMActorComponent.ROOT_TRANSFORM_ID = -2

include("channel.lua")

function ents.PFMActorComponent:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self:AddEntityComponent(ents.COMPONENT_NAME)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	local animC = self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	
	-- TODO: Only add these if this is an articulated actor
	self:AddEntityComponent(ents.COMPONENT_FLEX)
	self:AddEntityComponent(ents.COMPONENT_VERTEX_ANIMATED)
	
	self.m_channels = {}
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS] = ents.PFMActorComponent.TranslationChannel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS] = ents.PFMActorComponent.RotationChannel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS] = ents.PFMActorComponent.FlexControllerChannel()

	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	
	if(animC ~= nil) then
		self.m_cbUpdateSkeleton = animC:AddEventCallback(ents.AnimatedComponent.EVENT_ON_ANIMATIONS_UPDATED,function()
			-- TODO: Do this whenever the offset changes?
			self:ApplyTransforms()
		end)
	end
end

function ents.PFMActorComponent:OnRemove()
	if(util.is_valid(self.m_cbUpdateSkeleton)) then self.m_cbUpdateSkeleton:Remove() end
	if(util.is_valid(self.m_cbOnOffsetChanged)) then self.m_cbOnOffsetChanged:Remove() end
end

function ents.PFMActorComponent:OnEntitySpawn()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if(animC ~= nil) then
		animC:PlayAnimation("reference") -- Play reference animation to make sure animation callbacks are being called
	end
end

function ents.PFMActorComponent:OnClipOffsetChanged(newOffset)

end

function ents.PFMActorComponent:ApplyTransforms()
	if(util.is_valid(self.m_clipComponent) == false) then return end
	self.m_oldOffset = self.m_oldOffset or self.m_clipComponent:GetOffset()
	local newOffset = self.m_clipComponent:GetOffset()
	local tDelta = newOffset -self.m_oldOffset
	self.m_oldOffset = newOffset
	
	local ent = self:GetEntity()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	local mdl = mdlC:GetModel()
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS]:Apply(ent,newOffset)
	self.m_channels[ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS]:Apply(ent,newOffset)
	self.m_channels[ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS]:Apply(ent,newOffset)
end

function ents.PFMActorComponent:Setup(clipC,animSet)
	self.m_animationSet = animSet
	self.m_clipComponent = clipC
	
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end

	-- Setup animation set
	local mdlInfo = animSet:GetModel()
	mdlC:SetModel(mdlInfo:GetModelName())
	mdlC:SetSkin(mdlInfo:GetSkin())

	local transform = mdlInfo:GetTransform()
	-- Transform information seem to be composite of other data, we'll just ignore it for now.
	-- ent:SetPos(transform:GetPosition())
	-- ent:SetRotation(transform:GetRotation())

	local actorName = animSet:GetName()

	self.m_cbOnOffsetChanged = clipC:AddEventCallback(ents.PFMClip.EVENT_ON_OFFSET_CHANGED,function(newOffset)
		self:OnClipOffsetChanged(newOffset)
	end)
	
	self.m_boneIds = {}
	self.m_flexControllerIds = {}
	
	-- Initialize bone ids
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local boneControls = animSet:GetBoneControls():GetValue()
	for _,ctrl in ipairs(boneControls) do
		local boneName = ctrl:GetName()
		local boneId = mdl:LookupBone(boneName)
		if(boneId == -1 and boneName == "rootTransform") then boneId = ents.PFMActorComponent.ROOT_TRANSFORM_ID end -- Root transform will be handled as a special case
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
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
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
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
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
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_FLEX_CONTROLLER_TRANSFORMS,ctrlId,times[i]:GetValue(),values[i]:GetValue())
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
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_BONE_TRANSLATIONS,boneId,times[i]:GetValue(),values[i]:GetValue())
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
					self:AddChannelTransform(ents.PFMActorComponent.CHANNEL_BONE_ROTATIONS,boneId,times[i]:GetValue(),values[i]:GetValue())
				end
			end
		end
	end
	print("Done!")
end
function ents.PFMActorComponent:AddChannelTransform(channel,controllerName,time,value)
	if(self.m_channels[channel] == nil) then return end
	self.m_channels[channel]:AddTransform(controllerName,time,value)
end
ents.COMPONENT_PFM_ACTOR = ents.register_component("pfm_actor",ents.PFMActorComponent)
