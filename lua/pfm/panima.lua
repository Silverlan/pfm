--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}

util.register_class("pfm.AnimationManager")
function pfm.AnimationManager.__init()
end

local staticChannelPaths = {
	["PFMCamera"] = {
		["fov"] = "camera/fov"
	},
	["PFMPointLight"] = {
		["intensity"] = "light/intensity"
	},
	["PFMSpotLight"] = {
		["intensity"] = "light/intensity",
		["maxDistance"] = "radius/radius"
	},
	["PFMDirectionalLight"] = {
		["intensity"] = "light/intensity"
	},
	["actor"] = {
		["position"] = "transform/position",
		["rotation"] = "transform/rotation",
		["scale"] = "transform/scale"
	}
}

local function get_channel_path(toElement,attr)
	if(staticChannelPaths[toElement:GetTypeName()] ~= nil and staticChannelPaths[toElement:GetTypeName()][attr] ~= nil) then return staticChannelPaths[toElement:GetTypeName()][attr] end
	if(staticChannelPaths["actor"] ~= nil and staticChannelPaths["actor"][attr] ~= nil) then return staticChannelPaths["actor"][attr] end
end

function pfm.AnimationManager:Initialize(track)
	self.m_filmClipAnims = {}
	for _,filmClip in ipairs(track:GetFilmClips():GetTable()) do
		self:InitializeFilmClip(filmClip)
	end
end

function pfm.AnimationManager:Reset()
	self.m_filmClipAnims = {}
	self.m_filmClip = nil
end

function pfm.AnimationManager:SetFilmClip(filmClip)
	self.m_filmClip = filmClip
	if(self.m_filmClipAnims[util.get_object_hash(self.m_filmClip)] == nil) then return end
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
		self:PlayActorAnimation(ent)
	end
end

function pfm.AnimationManager:PlayActorAnimation(ent)
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actorData = actorC:GetActorData()
	local anims = self.m_filmClipAnims[util.get_object_hash(self.m_filmClip)]
	if(anims[util.get_object_hash(actorData)] == nil) then return end
	local animC = ent:AddComponent(ents.COMPONENT_PANIMA)
	local animManager = animC:AddAnimationManager("pfm")
	local player = animManager:GetPlayer()
	player:SetPlaybackRate(0.0)
	animC:PlayAnimation(animManager,anims[util.get_object_hash(actorData)])
end

function pfm.AnimationManager:SetTime(t)
	if(self.m_filmClip == nil or self.m_filmClipAnims[util.get_object_hash(self.m_filmClip)] == nil) then return end
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR),ents.IteratorFilterComponent(ents.COMPONENT_PANIMA)}) do
		local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
		local manager = animC:GetAnimationManager("pfm")
		if(manager ~= nil) then
			local player = manager:GetPlayer()
			player:SetCurrentTime(t or player:GetCurrentTime())
		end
	end
end

function pfm.AnimationManager:SetAnimationsDirty()
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR),ents.IteratorFilterComponent(ents.COMPONENT_PANIMA)}) do
		local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
		local animManager = (animC ~= nil) and animC:GetAnimationManager("pfm") or nil
		if(animManager ~= nil) then
			local player = animManager:GetPlayer()
			player:SetAnimationDirty()
		end
	end
	game.update_animations(0.0)
end

function pfm.AnimationManager:InitializeFilmClip(filmClip)
	self.m_filmClipAnims[util.get_object_hash(filmClip)] = self:GenerateAnimations(filmClip)
end

function pfm.AnimationManager:AddChannel(anim,channelClip,channelPath,type)
	pfm.log("Adding animation channel of type '" .. udm.enum_type_to_ascii(type) .. "' with path '" .. channelPath .. "' to animation '" .. tostring(anim) .. "'...",pfm.LOG_CATEGORY_PFM)
	local animChannel = anim:AddChannel(channelPath,type)
	local udmChannelTf = channelClip:GetTimeFrame()
	local channelTf = animChannel:GetTimeFrame()
	channelTf.startOffset = udmChannelTf:GetStart()
	channelTf.scale = udmChannelTf:GetScale()
	animChannel:SetTimeFrame(channelTf)
	return animChannel
end

function pfm.AnimationManager:GenerateAnimations(filmClip)
	local animChannelTrack = filmClip:FindAnimationChannelTrack()
	if(animChannelTrack == nil) then return end
	local actorChannels = {}
	for _,channelClip in ipairs(animChannelTrack:GetChannelClips():GetTable()) do
		local uuid = channelClip:GetActor()
		local actor = filmClip:FindActorByUniqueId(uuid)
		if(actor ~= nil) then
			for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
				local attr = channel:GetToAttribute()
				local channelPath = channel:GetTargetPath()
				if(#channelPath == 0) then channelPath = nil end
				channelPath = channelPath or get_channel_path(channel:GetToElement(),attr)
				if(channelPath ~= nil) then
					actorChannels[util.get_object_hash(actor)] = actorChannels[util.get_object_hash(actor)] or {}
					actorChannels[util.get_object_hash(actor)][channelPath] = {channel,channelClip}
				else
					pfm.log("Unable to determine channel path for channel animating attribute '" .. attr .. "' of element '" .. tostring(toElement) .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
				end
			end
		else
			pfm.log("Unable to find actor with uuid '" .. uuid .. "' for channel clip '" .. tostring(channelClip) .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		end
	end
	local animations = {}
	for actorDataHash,channels in pairs(actorChannels) do
		local anim = panima.Animation.create()
		for channelPath,channelData in pairs(channels) do
			local channel = channelData[1]
			local channelClip = channelData[2]
			local log = channel:GetLog()
			local layer = log:GetLayers():Get(1)
			local times = layer:GetTimes():GetTable()
			for i=0,#times -1 do
				times:Set(i,times:At(i))
			end
			local values = layer:GetValues():GetTable()
			local animChannel = self:AddChannel(anim,channelClip,channelPath,fudm.var_type_to_udm_type(layer:GetValues():GetValueType()))
			local expr = channel:GetExpression()
			if(#expr > 0) then
				local r = animChannel:SetValueExpression(expr)
				if(r ~= true) then pfm.log("Unable to initialize channel math expression '" .. expr .. "': " .. r,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING) end
			end
			animChannel:SetValues(times:ToTable(),values:ToTable())
		end
		anim:UpdateDuration()
		animations[actorDataHash] = anim
	end
	return animations
end

function pfm.AnimationManager:FindAnimationChannel(actor,path,addIfNotExists)
	if(self.m_filmClip == nil or self.m_filmClipAnims[util.get_object_hash(self.m_filmClip)] == nil) then return end
	local anims = self.m_filmClipAnims[util.get_object_hash(self.m_filmClip)]
	if(anims[util.get_object_hash(actor)] == nil) then
		if(addIfNotExists ~= true) then return end
		anims[util.get_object_hash(actor)] = panima.Animation.create()
		local ent = actor:FindEntity()
		if(ent ~= nil) then self:PlayActorAnimation(ent) end
		-- pfm.log("Unable to apply channel value for actor '" .. tostring(actor) .. "': No animation exists for this actor for the currently active film clip '" .. tostring(self.m_filmClip) .. "'!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		-- return
	end
	local anim = anims[util.get_object_hash(actor)]
	return anim,anim:FindChannel(path)
end

function pfm.AnimationManager:SetValueExpression(actor,path,expr)
	local anim,channel = self:FindAnimationChannel(actor,path)
	if(channel == nil) then return end
	local r = channel:SetValueExpression(expr)
	if(r ~= true) then pfm.log("Unable to apply channel value expression '" .. expr .. "' for channel with path '" .. path .. "': " .. r,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING) end
end

function pfm.AnimationManager:SetChannelValue(actor,path,time,value,channelClip,type)
	if(self.m_filmClip == nil or self.m_filmClipAnims[util.get_object_hash(self.m_filmClip)] == nil) then
		pfm.log("Unable to apply channel value: No active film clip selected, or film clip has no animations!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end
	local anim,channel = self:FindAnimationChannel(actor,path,true)
	local reloadRequired = false
	if(channel == nil and channelClip ~= nil and type ~= nil) then
		channel = self:AddChannel(anim,channelClip,path,type)
		reloadRequired = true
	end
	assert(channel ~= nil)
	if(channel == nil) then return end
	channel:AddValue(time,value)
	anim:UpdateDuration()

	if(reloadRequired) then
		for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PANIMA)}) do
			local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
			local animManager = animC:GetAnimationManager("pfm")
			local entAnim = animManager and animManager:GetCurrentAnimation() or nil
			if(entAnim == anim) then animC:ReloadAnimation(animManager) end
		end
	end
end
