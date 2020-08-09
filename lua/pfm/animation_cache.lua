--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.SceneAnimationCache")
function pfm.SceneAnimationCache:__init(session)
	self.m_session = session
	self.m_track = session:GetFilmTrack()
	self.m_cachedFrames = {}
	self.m_mdlAnimCache = {}
end

function pfm.SceneAnimationCache:MarkFrameAsDirty(frameIndex) self.m_cachedFrames[frameIndex] = nil end
function pfm.SceneAnimationCache:IsFrameDirty(frameIndex) return not self.m_cachedFrames[frameIndex] end

function pfm.SceneAnimationCache:GetCache() return self.m_mdlAnimCache end

function pfm.SceneAnimationCache:FrameOffsetToTimeOffset(frameIndex)
	local settings = self.m_session:GetSettings()
	local renderSettings = settings:GetRenderSettings()
	local frameRate = renderSettings:GetFrameRate()
	return frameIndex /frameRate
end

function pfm.SceneAnimationCache:GetFilmClip(frameIndex)
	local filmClip = self.m_session:GetFilmClip(self:FrameOffsetToTimeOffset(frameIndex))
	local animChannelTrack = (filmClip ~= nil) and filmClip:FindAnimationChannelTrack() or nil
	return filmClip,animChannelTrack
end

function pfm.SceneAnimationCache:GetAnimationName(filmClip,actor)
	return "pfm_" .. filmClip:GetName() .. "_" .. actor:GetName()
end

function pfm.SceneAnimationCache:AddAnimation(filmClip,actor)
	local modelC = actor:FindComponent("pfm_model")
	local mdl = (modelC ~= nil) and modelC:GetModel() or nil
	if(mdl == nil) then return end
	local anim = game.Model.Animation.Create()
	local boneList = {}
	for _,bone in ipairs(modelC:GetBoneList():GetTable()) do
		bone = bone:GetTarget()
		local boneName = bone:GetName()
		local boneId = mdl:LookupBone(boneName)
		table.insert(boneList,boneId)
	end
	anim:SetBoneList(boneList)
	mdl:AddAnimation(self:GetAnimationName(filmClip,actor),anim)

	local settings = self.m_session:GetSettings()
	local renderSettings = settings:GetRenderSettings()
	local frameRate = renderSettings:GetFrameRate()
	anim:SetFPS(frameRate)
	return anim
end

function pfm.SceneAnimationCache:UpdateCache(frameIndex)
	if(self:IsFrameDirty(frameIndex) == false) then return end
	local filmClip,animChannelTrack = self:GetFilmClip(frameIndex)
	if(animChannelTrack == nil) then return end
	self.m_cachedFrames[frameIndex] = true
	local actors = filmClip:GetActorList()
	for _,actor in ipairs(actors) do
		local modelC = actor:FindComponent("pfm_model")
		local mdl = (modelC ~= nil) and modelC:GetModel() or nil
		if(mdl ~= nil) then
			local mdlName = mdl:GetName()
			self.m_mdlAnimCache[mdlName] = self.m_mdlAnimCache[mdlName] or {}
			local cache = self.m_mdlAnimCache[mdlName]
			local animName = self:GetAnimationName(filmClip,actor)
			if(cache[animName] == nil) then
				local anim = self:AddAnimation(filmClip,actor)
				if(anim ~= nil) then cache[animName] = anim end
			end
			local anim = cache[animName]
			if(anim ~= nil) then
				local numFrames = anim:GetFrameCount()
				if(frameIndex >= numFrames) then
					local numBones = anim:GetBoneCount()
					for i=numFrames,frameIndex do
						local frame = game.Model.Animation.Frame.Create(numBones)
						anim:AddFrame(frame)
					end
				end

				local frame = anim:GetFrame(frameIndex)
				for i,bone in ipairs(modelC:GetBoneList():GetTable()) do
					bone = bone:GetTarget()
					local pose = bone:GetTransform():GetPose()
					-- local pose = modelC:CalcBonePose(self.m_track,i,t)
					frame:SetBoneTransform(i -1,pose:GetOrigin(),pose:GetRotation(),pose:GetScale())
				end
			end
		end
	end
end

function pfm.SceneAnimationCache:SaveToBinary(ds)
	ds:WriteString("PFA",false)
	ds:WriteUInt32(1) -- Version
	local mdlAnims = self.m_mdlAnimCache
	local numModels = 0
	for mdlName,_ in pairs(mdlAnims) do numModels = numModels +1 end

	ds:WriteUInt32(numModels)
	for mdlName,animData in pairs(mdlAnims) do
		ds:WriteString(mdlName)
		local numAnims = 0
		for _ in pairs(animData) do numAnims = numAnims +1 end
		ds:WriteUInt16(numAnims)
		for animName,anim in pairs(animData) do
			ds:WriteString(animName)
			anim:Save(ds)
		end
	end

	local maxFrame = 0
	for frameIndex,_ in pairs(self.m_cachedFrames) do
		maxFrame = math.max(maxFrame,frameIndex)
	end
	ds:WriteUInt32(maxFrame)

	local byte
	for i=0,maxFrame do
		byte = byte or 0
		if(self:IsFrameDirty(i)) then byte = bit.bor(byte,bit.lshift(1,i %8)) end
		if((i %8) == 7) then
			ds:WriteUInt8(byte)
			byte = nil
		end
	end
	if(byte ~= nil) then ds:WriteUInt8(byte) end
end
function pfm.SceneAnimationCache:LoadFromBinary(ds)
	local header = ds:ReadString(3)
	if(header ~= "PFA") then return end
	local version = ds:ReadUInt32()
	if(version < 0 or version > 1) then return end
	self.m_mdlAnimCache = {}
	local numModels = ds:ReadUInt32()
	for i=1,numModels do
		local mdlName = ds:ReadString()
		self.m_mdlAnimCache[mdlName] = {}
		local numAnims = ds:ReadUInt16()
		for j=1,numAnims do
			local animName = ds:ReadString()
			local anim = game.Model.Animation.Load(ds)
			if(anim ~= nil) then
				local mdl = game.load_model(mdlName)
				if(mdl ~= nil) then
					mdl:AddAnimation(animName,anim)
				end
				self.m_mdlAnimCache[mdlName][animName] = anim
			end
		end
	end

	local maxFrame = ds:ReadUInt32()
	if(maxFrame > 0) then
		local byte
		for i=0,maxFrame do
			byte = byte or ds:ReadUInt8()
			local isDirty = (bit.band(byte,bit.lshift(1,i %8)) ~= 0)
			if(isDirty == false) then self.m_cachedFrames[i] = true end
			if((i %8) == 7) then byte = nil end
		end
	end
end
