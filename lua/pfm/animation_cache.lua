--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.SceneAnimationCache")
pfm.SceneAnimationCache.FORMAT_VERSION = 2
function pfm.SceneAnimationCache:__init(session)
	self.m_session = session
	self.m_track = session:GetFilmTrack()
	self.m_cachedFrames = {}
	self.m_actorAnimationCache = {}
end

function pfm.SceneAnimationCache:MarkFrameAsDirty(frameIndex) self.m_cachedFrames[frameIndex] = nil end
function pfm.SceneAnimationCache:IsFrameDirty(frameIndex) return not self.m_cachedFrames[frameIndex] end

function pfm.SceneAnimationCache:GetCache() return self.m_actorAnimationCache end

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
	local rootPoseBoneId = mdl:GetSkeleton():LookupBone("%rootPose%")
	if(rootPoseBoneId ~= -1) then table.insert(boneList,rootPoseBoneId) end
	anim:SetBoneList(boneList)
	mdl:AddAnimation(self:GetAnimationName(filmClip,actor),anim)

	local settings = self.m_session:GetSettings()
	local renderSettings = settings:GetRenderSettings()
	local frameRate = renderSettings:GetFrameRate()
	anim:SetFPS(frameRate)
	return anim
end

function pfm.SceneAnimationCache:AddFlexAnimation(filmClip,actor)
	local modelC = actor:FindComponent("pfm_model")
	local mdl = (modelC ~= nil) and modelC:GetModel() or nil
	if(mdl == nil) then return end
	local flexAnim = mdl:AddFlexAnimation(self:GetAnimationName(filmClip,actor))
	local settings = self.m_session:GetSettings()
	local renderSettings = settings:GetRenderSettings()
	local frameRate = renderSettings:GetFrameRate()
	flexAnim:SetFps(frameRate)
	return flexAnim
end

function pfm.SceneAnimationCache:UpdateCache(frameIndex)
	if(self:IsFrameDirty(frameIndex) == false) then return end
	local filmClip,animChannelTrack = self:GetFilmClip(frameIndex)
	if(animChannelTrack == nil) then return end
	pfm.log("Updating animation cache for frame " .. frameIndex .. "...",pfm.LOG_CATEGORY_PFM_CACHE)
	self.m_cachedFrames[frameIndex] = true
	local actors = filmClip:GetActorList()
	for _,actor in ipairs(actors) do
		local modelC = actor:FindComponent("pfm_model")
		local mdl = (modelC ~= nil) and modelC:GetModel() or nil
		if(mdl ~= nil) then
			local mdlName = mdl:GetName()
			local uniqueId = actor:GetUniqueId()
			self.m_actorAnimationCache[uniqueId] = self.m_actorAnimationCache[uniqueId] or {model = mdlName,animations = {},flexAnimations = {}}
			local cache = self.m_actorAnimationCache[uniqueId]
			local animName = self:GetAnimationName(filmClip,actor)
			if(cache.animations[animName] == nil) then
				local anim = self:AddAnimation(filmClip,actor)
				if(anim ~= nil) then cache.animations[animName] = anim end
			end
			local anim = cache.animations[animName]
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

				local boneIdRoot = mdl:LookupBone("%rootPose%")
				if(boneIdRoot ~= -1) then
					local pose = actor:GetPose()
					frame:SetBonePose(boneIdRoot,phys.Transform(pose:GetOrigin(),pose:GetRotation()))
				end
			end

			-- Flex animation
			if(cache.flexAnimations[animName] == nil) then
				local anim = self:AddFlexAnimation(filmClip,actor)
				if(anim ~= nil) then cache.flexAnimations[animName] = anim end
			end
			local flexAnim = cache.flexAnimations[animName]
			if(flexAnim ~= nil) then
				local globalFlexControllers = modelC:GetGlobalFlexControllers()
				local flexNames = modelC:GetFlexControllerNames():GetTable()
				for i,fc in ipairs(globalFlexControllers:GetTable()) do
					if(flexNames[i] == nil) then pfm.log("Missing flex controller name for clex controller " .. i .. " for actor with model '" .. mdl:GetName() .. "'! Flex controller will be ignored...",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
					else
						local fcId = mdl:LookupFlexController(flexNames[i]:GetValue())
						if(fcId ~= -1) then
							local weight = fc:GetFlexWeight()
							if(weight > 0) then
								flexAnim:SetFlexControllerValue(frameIndex,fcId,pfm.translate_flex_controller_value(mdl:GetFlexController(fcId),weight))
							end
						else
							pfm.log("Unknown flex controller '" .. fc:GetName() .. "' for actor with model '" .. mdl:GetName() .. "'! Flex controller will be ignored...",pfm.LOG_CATEGORY_PFM_GAME,pfm.LOG_SEVERITY_WARNING)
						end
					end
				end
			end
			--
		end
	end
end

function pfm.SceneAnimationCache:SaveToBinary(fileName)
	pfm.log("Saving animation cache '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)
	local udmData,err = udm.create("PFAC",pfm.SceneAnimationCache.FORMAT_VERSION)
	if(udmData == false) then
		console.print_warning(err)
		return false
	end

	local assetData = udmData:GetAssetData():GetData()
	local udmActors = assetData:Add("actors")
	for uniqueId,actorAnimations in pairs(self.m_actorAnimationCache) do
		local udmActor = udmActors:Add(uniqueId)

		udmActor:SetValue("model",udm.TYPE_STRING,actorAnimations.model)
		local udmAnimations = udmActor:Add("animations")
		for animName,anim in pairs(actorAnimations.animations) do
			local udmAnimation = udmAnimations:AddAssetData(animName)
			anim:Save(udmAnimation)
		end

		local udmFlexAnimations = udmActor:Add("flexAnimations")
		for animName,anim in pairs(actorAnimations.flexAnimations) do
			local udmFlexAnimation = udmFlexAnimations:AddAssetData(animName)
			anim:Save(udmFlexAnimation)
		end
	end

	local cachedFrames = {}
	for frameIndex,_ in pairs(self.m_cachedFrames) do
		table.insert(cachedFrames,frameIndex)
	end
	assetData:AddBlobFromArrayValues("cachedFrames",udm.TYPE_UINT32,cachedFrames)

	local f = file.open(fileName,bit.bor(file.OPEN_MODE_WRITE,file.OPEN_MODE_BINARY))
	if(f == nil) then
		pfm.log("Unable to open file '" .. fileName .. "' for writing!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	local res,err = udmData:Save(f)
	f:Close()
	if(res == false) then
		pfm.log("Failed to save animation cache as '" .. fileName .. "': " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end
	return true
--[[
	ds:WriteString("PFA",false)
	ds:WriteUInt32(pfm.SceneAnimationCache.FORMAT_VERSION) -- Version


	local mdlAnims = self.m_mdlAnimCache
	local numModels = 0
	for mdlName,_ in pairs(mdlAnims) do numModels = numModels +1 end

	ds:WriteUInt32(numModels)
	for mdlName,animData in pairs(mdlAnims) do
		ds:WriteString(mdlName)
		local numAnims = 0
		for _ in pairs(animData) do numAnims = numAnims +1 end
		ds:WriteUInt16(numAnims)
		for animName,animData in pairs(animData) do
			ds:WriteString(animName)

			ds:WriteBool(animData.animation ~= nil)
			if(animData.animation ~= nil) then animData.animation:SaveLegacy(ds) end

			ds:WriteBool(animData.flexAnimation ~= nil)
			if(animData.flexAnimation ~= nil) then animData.flexAnimation:Save(ds) end
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
]]
end
function pfm.SceneAnimationCache:LoadFromBinary(fileName)
	pfm.log("Loading animation cache '" .. fileName .. "'...",pfm.LOG_CATEGORY_PFM)

	local f = file.open(fileName,bit.bor(file.OPEN_MODE_READ,file.OPEN_MODE_BINARY))
	if(f == nil) then
		pfm.log("File '" .. fileName .. "' not found! Playback may be very slow!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local udmData,err = udm.load(f)
	f:Close()
	if(udmData == false) then
		pfm.log("Failed to load animation cache: " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local assetData = udmData:GetAssetData()
	if(assetData:GetAssetType() ~= "PFAC") then
		console.print_warning("Invalid animation cache format!")
		return false
	end
	local version = assetData:GetAssetVersion()
	if(version < 1) then
		console.print_warning("Invalid animation cache version!")
		return false
	end

	assetData = assetData:GetData()
	for uniqueId,udmActor in pairs(assetData:Get("actors"):GetChildren()) do
		local modelName = udmActor:GetValue("model")
		self.m_actorAnimationCache[uniqueId] = {model = modelName,animations = {},flexAnimations = {}}
		local cache = self.m_actorAnimationCache[uniqueId]
		for animName,udmAnim in pairs(udmActor:Get("animations"):GetChildren()) do
			local anim = game.Model.Animation.Load(udmAnim:GetAssetData())
			if(anim ~= nil) then
				local mdl = game.load_model(modelName)
				if(mdl ~= nil) then mdl:AddAnimation(animName,anim) end
				cache.animations = cache.animations or {}
				cache.animations[animName] = anim
			end
		end

		for animName,udmAnim in pairs(udmActor:Get("flexAnimations"):GetChildren()) do
			local flexAnim = game.Model.FlexAnimation.Load(udmAnim:GetAssetData())
			if(flexAnim ~= nil) then
				local mdl = game.load_model(modelName)
				if(mdl ~= nil) then
					mdl:AddFlexAnimation(animName,flexAnim)
				end
				cache.flexAnimations = cache.flexAnimations or {}
				cache.flexAnimations[animName] = flexAnim
			end
		end
	end

	local cachedFrames = assetData:Get("cachedFrames"):GetArrayValuesFromBlob(udm.TYPE_UINT32)
	for _,idx in ipairs(cachedFrames) do self.m_cachedFrames[idx] = true end
	return true
end
