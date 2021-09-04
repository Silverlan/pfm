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
		["intensity"] = "light/intensity"
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
	if(self.m_filmClipAnims[self.m_filmClip] == nil) then return end
	local anims = self.m_filmClipAnims[self.m_filmClip]
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
		local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
		local actorData = actorC:GetActorData()
		if(anims[actorData] ~= nil) then
			local animC = ent:AddComponent(ents.COMPONENT_ANIMATED2)
			if(animC:GetAnimationManager(0) == nil) then animC:AddAnimationManager() end
			local animManager = animC:GetAnimationManager(0)
			local player = animManager:GetPlayer()
			player:SetPlaybackRate(0.0)
			animC:PlayAnimation(animManager,anims[actorData])
		end
	end
end

function pfm.AnimationManager:SetTime(t)
	if(self.m_filmClip == nil or self.m_filmClipAnims[self.m_filmClip] == nil) then return end
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR),ents.IteratorFilterComponent(ents.COMPONENT_ANIMATED2)}) do
		local animC = ent:GetComponent(ents.COMPONENT_ANIMATED2)
		local manager = animC:GetAnimationManager(0)
		if(manager ~= nil) then manager:GetPlayer():SetCurrentTime(t) end
	end
end

function pfm.AnimationManager:InitializeFilmClip(filmClip)
	self.m_filmClipAnims[filmClip] = self:GenerateAnimations(filmClip)
end

function pfm.AnimationManager:GenerateAnimations(filmClip)
	local animChannelTrack = filmClip:FindAnimationChannelTrack()
	if(animChannelTrack == nil) then return end
	local actorChannels = {}
	for _,channelClip in ipairs(animChannelTrack:GetChannelClips():GetTable()) do
		for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
			local toElement = channel:GetToElement()
			local attr = channel:GetToAttribute()
			local parent = (toElement ~= nil) and toElement:FindParentElement(function(el) return el:GetType() == fudm.ELEMENT_TYPE_PFM_ACTOR end) or nil
			if(parent ~= nil) then
				local channelPath = channel:GetTargetPath()
				if(#channelPath == 0) then channelPath = nil end
				channelPath = channelPath or get_channel_path(channel:GetToElement(),attr)
				if(channelPath ~= nil) then
					actorChannels[parent] = actorChannels[parent] or {}
					actorChannels[parent][channelPath] = {channel,channelClip}
				else
					console.print_warning("Unable to determine channel path for channel animating attribute '" .. attr .. "' of element '" .. tostring(toElement) .. "'!")
				end
			end
		end
	end
	local varTypeToUdmType = {
		[util.VAR_TYPE_BOOL] = udm.TYPE_BOOLEAN,
		[util.VAR_TYPE_DOUBLE] = udm.TYPE_DOUBLE,
		[util.VAR_TYPE_FLOAT] = udm.TYPE_FLOAT,
		[util.VAR_TYPE_INT8] = udm.TYPE_INT8,
		[util.VAR_TYPE_INT16] = udm.TYPE_INT16,
		[util.VAR_TYPE_INT32] = udm.TYPE_INT32,
		[util.VAR_TYPE_INT64] = udm.TYPE_INT64,
		[util.VAR_TYPE_LONG_DOUBLE] = udm.TYPE_DOUBLE,
		[util.VAR_TYPE_STRING] = udm.TYPE_STRING,
		[util.VAR_TYPE_UINT8] = udm.TYPE_UINT8,
		[util.VAR_TYPE_UINT16] = udm.TYPE_UINT16,
		[util.VAR_TYPE_UINT32] = udm.TYPE_UINT32,
		[util.VAR_TYPE_UINT64] = udm.TYPE_UINT64,
		[util.VAR_TYPE_EULER_ANGLES] = udm.TYPE_EULER_ANGLES,
		[util.VAR_TYPE_COLOR] = udm.TYPE_SRGBA,
		[util.VAR_TYPE_VECTOR] = udm.TYPE_VECTOR3,
		[util.VAR_TYPE_VECTOR2] = udm.TYPE_VECTOR2,
		[util.VAR_TYPE_VECTOR4] = udm.TYPE_VECTOR4,
		[util.VAR_TYPE_QUATERNION] = udm.TYPE_QUATERNION
	}
	local animations = {}
	for actorData,channels in pairs(actorChannels) do
		local anim = animation.Animation2.create()
		for channelPath,channelData in pairs(channels) do
			local channel = channelData[1]
			local channelClip = channelData[2]
			local log = channel:GetLog()
			local layer = log:GetLayers():Get(1)
			local times = layer:GetTimes():GetTable()
			for i=0,#times -1 do
				times:Set(i,channelClip:GetTimeFrame():GlobalizeOffset(times:At(i)))
			end
			local values = layer:GetValues():GetTable()

			console.print_table(times:ToTable())
			console.print_table(values:ToTable())
			local animChannel = anim:AddChannel(channelPath,varTypeToUdmType[layer:GetValues():GetValueType()])
			local expr = channel:GetExpression()
			if(#expr > 0) then
				local r = animChannel:SetValueExpression(expr)
				if(r ~= true) then console.print_warning("Unable to translate SFM expression operator expression '" .. expr .. "': " .. r) end
			end
			animChannel:SetValues(times:ToTable(),values:ToTable())
		end
		anim:UpdateDuration()
		animations[actorData] = anim
	end
	return animations
end
