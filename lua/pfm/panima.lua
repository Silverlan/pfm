--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}

util.register_class("pfm.AnimationManager",util.CallbackHandler)
function pfm.AnimationManager:Initialize(track)
end

function pfm.AnimationManager:Reset()
	self.m_filmClip = nil
end

function pfm.AnimationManager:SetFilmClip(filmClip)
	self.m_filmClip = filmClip

	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
		self:PlayActorAnimation(ent)
	end
end

local cvPanima = console.get_convar("pfm_experimental_enable_panima_for_flex_and_skeletal_animations")
function pfm.AnimationManager:PlayActorAnimation(ent)
	if(self.m_filmClip == nil or cvPanima:GetBool() == false) then return end
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actorData = actorC:GetActorData()

	local clip = self.m_filmClip:FindActorAnimationClip(actorData)
	if(clip == nil) then return end
	local animC = ent:AddComponent(ents.COMPONENT_PANIMA)
	local animManager = animC:AddAnimationManager("pfm")
	local player = animManager:GetPlayer()
	player:SetPlaybackRate(0.0)
	local anim = clip:GetPanimaAnimation()
	pfm.log("Playing actor animation '" .. tostring(anim) .. "' for actor '" .. tostring(ent) .. "'...",pfm.LOG_CATEGORY_PFM)
	animC:PlayAnimation(animManager,anim)
end

function pfm.AnimationManager:SetTime(t)
	if(self.m_filmClip == nil) then return end
	self.m_time = t
	for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR),ents.IteratorFilterComponent(ents.COMPONENT_PANIMA)}) do
		local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
		local manager = animC:GetAnimationManager("pfm")
		if(manager ~= nil) then
			local player = manager:GetPlayer()
			local lt = t
			if(lt) then
				local pfmActorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
				local animClip = (pfmActorC ~= nil) and self.m_filmClip:FindActorAnimationClip(pfmActorC:GetActorData()) or nil
				if(animClip ~= nil) then
					local start = animClip:GetTimeFrame():GetStart()
					lt = lt -start
				end
			end
			player:SetCurrentTime(lt or player:GetCurrentTime())
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

function pfm.AnimationManager:SetAnimationDirty(actor)
	local ent = actor:FindEntity()
	if(util.is_valid(ent) == false) then return end
	local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
	local animManager = (animC ~= nil) and animC:GetAnimationManager("pfm") or nil
	if(animManager == nil) then return end
	local player = animManager:GetPlayer()
	player:SetAnimationDirty()
end

function pfm.AnimationManager:AddChannel(anim,channelClip,channelPath,type)
	pfm.log("Adding animation channel of type '" .. udm.enum_type_to_ascii(type) .. "' with path '" .. channelPath .. "' to animation '" .. tostring(anim) .. "'...",pfm.LOG_CATEGORY_PFM)
	local animChannel = anim:AddChannel(channelPath,type)
	if(animChannel == nil) then
		pfm.log("Failed to add animation channel of type '" .. udm.enum_type_to_ascii(type) .. "' with path '" .. channelPath .. "' to animation '" .. tostring(anim) .. "'...",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end
	local udmChannelTf = channelClip:GetTimeFrame()
	local channelTf = animChannel:GetTimeFrame()
	channelTf.startOffset = udmChannelTf:GetStart()
	channelTf.scale = udmChannelTf:GetScale()
	animChannel:SetTimeFrame(channelTf)
	return animChannel
end

function pfm.AnimationManager:FindAnimationChannel(actor,path,addIfNotExists,type)
	if(self.m_filmClip == nil or self.m_filmClip == nil) then return end
	local animClip,newAnim = self.m_filmClip:FindActorAnimationClip(actor,addIfNotExists)
	if(animClip == nil) then return end

	if(newAnim) then
		local ent = actor:FindEntity()
		if(ent ~= nil) then self:PlayActorAnimation(ent) end
	end
	local anim = animClip:GetPanimaAnimation()
	if(anim == nil) then return end
	local channel = anim:FindChannel(path)
	if(channel == nil and addIfNotExists) then
		channel = animClip:GetChannel(path,type,true)
		animClip:SetPanimaAnimationDirty()

		-- New channel added; Reload animation
		local ent = actor:FindEntity()
		if(util.is_valid(ent)) then self:PlayActorAnimation(ent) end
		anim = animClip:GetPanimaAnimation()
	end
	return anim,anim:FindChannel(path),animClip
end

function pfm.AnimationManager:SetValueExpression(actor,path,expr)
	local anim,channel = self:FindAnimationChannel(actor,path)
	if(channel == nil) then return end
	if(expr == nil) then
		channel:ClearValueExpression()
		return
	end
	local r = channel:SetValueExpression(expr)
	if(r ~= true) then pfm.log("Unable to apply channel value expression '" .. expr .. "' for channel with path '" .. path .. "': " .. r,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING) end
end

function pfm.AnimationManager:GetValueExpression(actor,path)
	local anim,channel = self:FindAnimationChannel(actor,path)
	if(channel == nil) then return end
	return channel:GetValueExpression()
end

function pfm.AnimationManager:RemoveChannel(actor,path)
	if(self.m_filmClip == nil or self.m_filmClip == nil) then return end
	self:SetAnimationDirty(actor)
	local anim,channel,animClip = self:FindAnimationChannel(actor,path)
	if(animClip ~= nil) then animClip:RemoveChannel(path) end
	if(channel == nil) then return end
	anim:RemoveChannel(path)
end

function pfm.AnimationManager:RemoveKeyframe(actor,path,keyIdx,baseIndex)
	if(self.m_filmClip == nil or self.m_filmClip == nil) then
		pfm.log("Unable to apply channel value: No active film clip selected, or film clip has no animations!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end
	local anim,channel,animClip = self:FindAnimationChannel(actor,path)
	local udmChannel = animClip:GetChannel(path,type)
	if(channel == nil or udmChannel == nil) then return end
	pfm.log("Removing keyframe " .. keyIdx .. " with channel path '" .. path .. "' of actor '" .. tostring(actor) .. "'...",pfm.LOG_CATEGORY_PFM)


	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path)
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	editorChannel:RemoveKey(keyData:GetTime(keyIdx),baseIndex)

	self:CallCallbacks("OnKeyframeUpdated",{
		actor = actor,
		animation = anim,
		channel = channel,
		udmChannel = udmChannel,
		oldKeyIndex = keyIdx
	})
end

function pfm.AnimationManager:GetChannelValueByIndex(actor,path,idx)
	if(self.m_filmClip == nil or self.m_filmClip == nil) then return end
	local anim,channel,animClip = self:FindAnimationChannel(actor,path)
	if(channel == nil) then return end
	return channel:GetTime(idx),channel:GetValue(idx)
end

function pfm.AnimationManager:UpdateKeyframe(actor,path,panimaChannel,keyIdx,time,value,baseIndex)
	local anim,channel,animClip = self:FindAnimationChannel(actor,path)
	if(channel == nil) then return end
	pfm.log("Updating keyframe index " .. keyIdx .. " with value " .. (value and tostring(value) or "n/a") .. " at timestamp " .. (time and tostring(time) or "n/a") .. " with channel path '" .. path .. "' of actor '" .. tostring(actor) .. "'...",pfm.LOG_CATEGORY_PFM)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path)
	local udmChannel = animClip:GetChannel(path,type)
	if(editorChannel == nil or udmChannel == nil) then return end

	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if(keyData ~= nil) then
		-- Update animation value

		local fullUpdateRequired = false
		if(time ~= keyData:GetTime(keyIdx)) then
			if(editorChannel:FindKeyIndexByTime(time,baseIndex) ~= nil) then
				-- Two keyframes must not occupy the same timestamp, so we'll keep the old timestamp
				time = keyData:GetTime(keyIdx)
			else
				-- The keyframes timestamp has changed, which affects the curves to the next and the previous keyframes.
				-- We'll temporarily delete all animation values for those curves to avoid potential collisions.
				-- The curve animation data will have to be re-generated anyway.
				local tPrev = (keyIdx > 0) and keyData:GetTime(keyIdx -1) or nil
				local t = keyData:GetTime(keyIdx)
				local tNext = keyData:GetTime(keyIdx +1)

				local valueIndexPrev = (tPrev ~= nil) and panimaChannel:FindIndex(tPrev,pfm.udm.EditorChannelData.TIME_EPSILON) or nil
				local valueIndex = (t ~= nil) and panimaChannel:FindIndex(t,pfm.udm.EditorChannelData.TIME_EPSILON) or nil
				local valueIndexNext = (tNext ~= nil) and panimaChannel:FindIndex(tNext,pfm.udm.EditorChannelData.TIME_EPSILON) or nil
				if(valueIndex ~= nil) then
					if(valueIndexNext ~= nil) then self:SetCurveChannelValueCount(actor,path,valueIndex,valueIndexNext,0,true) end
					if(valueIndexPrev ~= nil) then self:SetCurveChannelValueCount(actor,path,valueIndexPrev,valueIndex,0,true) end

					-- Value index may have changed; Re-query
					valueIndex = panimaChannel:FindIndex(t,pfm.udm.EditorChannelData.TIME_EPSILON)
					panimaChannel:SetTime(valueIndex,time,true)
				end
			end
		end

		-- Update keyframe
		keyData:SetValue(keyIdx,value)
		local oldKeyIndex = keyIdx
		local newKeyIdx = editorChannel:SetKeyTime(keyIdx,time,baseIndex)

		if(newKeyIdx ~= nil) then -- Key has been swapped
		else oldKeyIndex = nil end

		self:CallCallbacks("OnKeyframeUpdated",{
			actor = actor,
			animation = anim,
			channel = channel,
			udmChannel = udmChannel,
			keyIndex = newKeyIdx or keyIdx,
			oldKeyIndex = oldKeyIndex
		})
		--
	end
end

function pfm.AnimationManager:SetChannelValue(actor,path,time,value,type,addKey)
	if(addKey == nil) then addKey = true end
	if(self.m_filmClip == nil or self.m_filmClip == nil) then
		pfm.log("Unable to apply channel value: No active film clip selected, or film clip has no animations!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end
	pfm.log("Setting channel value " .. tostring(value) .. " of type " .. udm.type_to_string(type) .. " at timestamp " .. time .. " with channel path '" .. path .. "' to actor '" .. tostring(actor) .. "'...",pfm.LOG_CATEGORY_PFM)
	local anim,channel,animClip = self:FindAnimationChannel(actor,path,true,type)
	assert(channel ~= nil)
	if(channel == nil) then return end
	local idx = channel:AddValue(time,value)
	anim:UpdateDuration()

	local keyIdx
	if(addKey) then
		local editorData = animClip:GetEditorData()
		local editorChannel = editorData:FindChannel(path,true)
		-- TODO: Vec3, etc. -> Split into components!
		local keyData
		keyData,keyIndex = editorChannel:AddKey(time)
		keyData:SetValue(keyIndex,value)

		keyData:SetInTime(keyIndex,-0.5)
		keyData:SetInDelta(keyIndex,0.0)
		keyData:SetOutTime(keyIndex,0.5)
		keyData:SetOutDelta(keyIndex,0.0)
	end

	local udmChannel = animClip:GetChannel(path,type)
	self:CallCallbacks("OnChannelValueChanged",{
		actor = actor,
		animation = anim,
		channel = channel,
		udmChannel = udmChannel,
		index = idx,
		oldIndex = idx,
		keyIndex = keyIndex
	})
end

function pfm.AnimationManager:SetCurveChannelValueCount(actor,path,startIndex,endIndex,numValues,suppressCallback)
	if(self.m_filmClip == nil or self.m_filmClip == nil) then
		pfm.log("Unable to apply channel value: No active film clip selected, or film clip has no animations!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return false
	end

	local anim,channel,animClip = self:FindAnimationChannel(actor,path)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path,true)
	if(channel == nil) then return false end

	local startTime = channel:GetTime(startIndex)
	local endTime = channel:GetTime(endIndex)
	if(startIndex == false or endTime == false) then return false end

	local startVal = channel:GetValue(startIndex)
	local endVal = channel:GetValue(endIndex)

	local numCurValues = endIndex -startIndex -1
	if(numCurValues > numValues) then
		local nRemove = numCurValues -numValues
		channel:RemoveValueRange(startIndex +1,nRemove)
		endIndex = endIndex -nRemove
	elseif(numCurValues < numValues) then
		local nAdd = numValues -numCurValues
		channel:AddValueRange(startIndex +1,nAdd)
		endIndex = endIndex +nAdd
	end

	local dt = endTime -startTime
	local numValuesIncludingEndpoints = numValues +2
	local dtPerValue = dt /(numValuesIncludingEndpoints -1)
	local curTime = startTime +dtPerValue
	local curIndex = startIndex +1
	for i=0,numValues -1 do
		channel:SetTime(curIndex,curTime)
		local f = (i +1) /(numValuesIncludingEndpoints -1)
		channel:SetValue(curIndex,math.lerp(startVal,endVal,f))

		curTime = curTime +dtPerValue
		curIndex = curIndex +1
	end

	local udmChannel = animClip:GetChannel(path,type)
	if(suppressCallback ~= true) then self:CallCallbacks("OnChannelValueChanged",actor,anim,channel,udmChannel) end
	return true,endIndex
end
