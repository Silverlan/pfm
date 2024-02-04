--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMAnimationManager", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_animatedActors = {}
end

function Component:Reset()
	self.m_filmClip = nil
end

function Component:GetProjectComponent()
	return self:GetEntity():GetComponent(ents.COMPONENT_PFM_PROJECT)
end

function Component:GetActorIterator(animatedOnly)
	local c = self:GetProjectComponent()
	if c == nil then
		return
	end
	return c:GetActorIterator(animatedOnly)
end

function Component:SetFilmClip(filmClip)
	self.m_filmClip = filmClip

	local it = self:GetActorIterator()
	if it ~= nil then
		for ent in it do
			self:PlayActorAnimation(ent)
		end
	end
end

function Component:PlayActorAnimation(ent)
	if self.m_filmClip == nil then
		return
	end
	local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
	local actorData = actorC:GetActorData()

	local clip = self.m_filmClip:FindActorAnimationClip(actorData)
	if clip == nil then
		return
	end
	local animC = ent:AddComponent(ents.COMPONENT_PANIMA)
	local animManager = animC:AddAnimationManager("pfm")
	local player = animManager:GetPlayer()
	player:SetPlaybackRate(0.0)
	local anim = clip:GetPanimaAnimation()
	pfm.log(
		"Playing actor animation '" .. tostring(anim) .. "' for actor '" .. tostring(ent) .. "'...",
		pfm.LOG_CATEGORY_PFM
	)
	animC:PlayAnimation(animManager, anim)

	local animClipTimeStart = clip:GetAbsStart()
	table.insert(self.m_animatedActors, {
		entity = ent,
		player = player,
		animClipTimeStart = animClipTimeStart,
	})
end

function Component:SetTime(t)
	if self.m_filmClip == nil then
		return
	end
	self.m_time = t

	for i = #self.m_animatedActors, 1, -1 do
		local animActorInfo = self.m_animatedActors[i]
		if animActorInfo.entity:IsValid() then
			local lt = t
			if lt and animActorInfo.animClipTimeStart ~= nil then
				lt = lt - animActorInfo.animClipTimeStart
			end
			animActorInfo.player:SetCurrentTime(lt or animActorInfo.player:GetCurrentTime())
		else
			table.remove(self.m_animatedActors, i)
		end
	end
end

function Component:SetAnimationsDirty()
	local it = self:GetActorIterator(true)
	if it ~= nil then
		for ent in it do
			local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
			local animManager = (animC ~= nil) and animC:GetAnimationManager("pfm") or nil
			if animManager ~= nil then
				local player = animManager:GetPlayer()
				player:SetAnimationDirty()
			end
		end
	end
	game.update_animations(0.0)
end

function Component:SetAnimationDirty(actor)
	local ent = actor:FindEntity()
	if util.is_valid(ent) == false then
		return
	end
	local animC = ent:GetComponent(ents.COMPONENT_PANIMA)
	local animManager = (animC ~= nil) and animC:GetAnimationManager("pfm") or nil
	if animManager == nil then
		return
	end
	local player = animManager:GetPlayer()
	player:SetAnimationDirty()
end

function Component:AddChannel(anim, channelClip, channelPath, type)
	pfm.log(
		"Adding animation channel of type '"
			.. udm.enum_type_to_ascii(type)
			.. "' with path '"
			.. channelPath
			.. "' to animation '"
			.. tostring(anim)
			.. "'...",
		pfm.LOG_CATEGORY_PFM
	)
	local animChannel = anim:AddChannel(channelPath, type)
	if animChannel == nil then
		pfm.log(
			"Failed to add animation channel of type '"
				.. udm.enum_type_to_ascii(type)
				.. "' with path '"
				.. channelPath
				.. "' to animation '"
				.. tostring(anim)
				.. "'...",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	local udmChannelTf = channelClip:GetTimeFrame()
	local channelTf = animChannel:GetTimeFrame()
	channelTf.startOffset = udmChannelTf:GetStart()
	channelTf.scale = udmChannelTf:GetScale()
	animChannel:SetTimeFrame(channelTf)
	return animChannel
end

function Component:FindAnimation(actor, addIfNotExists)
	if self.m_filmClip == nil or self.m_filmClip == nil then
		return
	end
	local animClip, newAnim = self.m_filmClip:FindActorAnimationClip(actor, addIfNotExists)
	if animClip == nil then
		return
	end

	if newAnim then
		local ent = actor:FindEntity()
		if ent ~= nil then
			self:PlayActorAnimation(ent)
		end
	end
	return animClip:GetPanimaAnimation(), animClip, newAnim
end

function Component:FindAnimationChannel(actor, path, addIfNotExists, type)
	local anim, animClip, newAnim = self:FindAnimation(actor, addIfNotExists)
	if anim == nil then
		return
	end
	local channel = anim:FindChannel(path)
	local newChannel = false
	if channel == nil and addIfNotExists then
		channel, newChannel = animClip:GetChannel(path, type, true)
		animClip:SetPanimaAnimationDirty()

		-- New channel added; Reload animation
		local ent = actor:FindEntity()
		if util.is_valid(ent) then
			self:PlayActorAnimation(ent)
		end
		anim = animClip:GetPanimaAnimation()

		if newChannel then
			self:InvokeEventCallbacks(Component.EVENT_ON_CHANNEL_ADDED, { actor, path })
		end
	end
	return anim, anim:FindChannel(path), animClip, newChannel
end

function Component:InitChannelWithBaseValue(actor, path, addIfNotExists, type)
	local anim, channel = self:FindAnimationChannel(actor, path, addIfNotExists, type)
	if channel == nil or channel:GetValueCount() > 0 then
		return
	end
	local value = actor:GetMemberValue(path)
	if value == nil then
		return
	end
	channel:AddValue(0.0, value)
end

function Component:SetValueExpression(actor, path, expr, type)
	local anim, channel = self:FindAnimationChannel(actor, path, (type ~= nil), type)
	if channel == nil then
		return false
	end
	self:InitChannelWithBaseValue(actor, path)
	if expr == nil then
		channel:ClearValueExpression()
		return false
	end
	local r = channel:SetValueExpression(expr)
	if r ~= true then
		pfm.log(
			"Unable to apply channel value expression '" .. expr .. "' for channel with path '" .. path .. "': " .. r,
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
	end
	return r == true, (r ~= true) and r or nil
end

function Component:GetValueExpression(actor, path)
	local anim, channel = self:FindAnimationChannel(actor, path)
	if channel == nil then
		return
	end
	return channel:GetValueExpression()
end

function Component:RemoveChannel(actor, path)
	if self.m_filmClip == nil or self.m_filmClip == nil then
		return false
	end
	self:SetAnimationDirty(actor)
	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	if animClip ~= nil then
		animClip:RemoveChannel(path)
	end
	if channel == nil then
		return false
	end
	anim:RemoveChannel(path)
	self:InvokeEventCallbacks(Component.EVENT_ON_CHANNEL_REMOVED, { actor, path })
	return true
end

function Component:RemoveKeyframe(actor, path, keyIdx, baseIndex)
	if self.m_filmClip == nil or self.m_filmClip == nil then
		pfm.log(
			"Unable to apply channel value: No active film clip selected, or film clip has no animations!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	local udmChannel = animClip:GetChannel(path, type)
	if channel == nil or udmChannel == nil then
		return
	end
	pfm.log(
		"Removing keyframe " .. keyIdx .. " with channel path '" .. path .. "' of actor '" .. tostring(actor) .. "'...",
		pfm.LOG_CATEGORY_PFM
	)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path)
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	editorChannel:RemoveKey(keyData:GetTime(keyIdx), baseIndex)

	self:InvokeEventCallbacks(Component.EVENT_ON_KEYFRAME_UPDATED, {
		{
			actor = actor,
			animation = anim,
			channel = channel,
			udmChannel = udmChannel,
			oldKeyIndex = keyIdx,
			typeComponentIndex = baseIndex,
		},
	})
end

function Component:GetChannelValueByIndex(actor, path, idx)
	if self.m_filmClip == nil then
		return
	end
	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	if channel == nil then
		return
	end
	return channel:GetTime(idx), channel:GetValue(idx)
end

function Component:GetChannelValueByKeyframeIndex(actor, path, panimaChannel, keyIdx, baseIndex)
	if self.m_filmClip == nil then
		return
	end
	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	if channel == nil then
		return
	end
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path)
	local udmChannel = animClip:GetChannel(path, type)
	if editorChannel == nil or udmChannel == nil then
		return
	end
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if keyData == nil then
		return
	end
	local valueIdx = panimaChannel:FindIndex(keyData:GetTime(keyIdx), pfm.udm.EditorChannelData.TIME_EPSILON)
	if valueIdx == nil then
		return
	end
	return channel:GetTime(valueIdx), channel:GetValue(valueIdx)
end

function Component:UpdateKeyframe(actor, path, panimaChannel, keyIdx, time, value, baseIndex)
	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	if channel == nil then
		return
	end
	pfm.log(
		"Updating keyframe index "
			.. keyIdx
			.. " with value "
			.. (value and tostring(value) or "n/a")
			.. " at timestamp "
			.. (time and tostring(time) or "n/a")
			.. " with channel path '"
			.. path
			.. "' of actor '"
			.. tostring(actor)
			.. "'...",
		pfm.LOG_CATEGORY_PFM
	)

	time = animClip:LocalizeOffsetAbs(time)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path)
	local udmChannel = animClip:GetChannel(path, type)
	if editorChannel == nil or udmChannel == nil then
		return
	end

	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if keyData ~= nil then
		-- Update animation value

		local fullUpdateRequired = false
		if time ~= keyData:GetTime(keyIdx) then
			if editorChannel:FindKeyIndexByTime(time, baseIndex) ~= nil then
				-- Two keyframes must not occupy the same timestamp, so we'll keep the old timestamp
				time = keyData:GetTime(keyIdx)
			else
				-- The keyframes timestamp has changed, which affects the curves to the next and the previous keyframes.
				-- We'll temporarily delete all animation values for those curves to avoid potential collisions.
				-- The curve animation data will have to be re-generated anyway.
				local tPrev = (keyIdx > 0) and keyData:GetTime(keyIdx - 1) or nil
				local t = keyData:GetTime(keyIdx)
				local tNext = keyData:GetTime(keyIdx + 1)

				local valueIndexPrev = (tPrev ~= nil)
						and panimaChannel:FindIndex(tPrev, pfm.udm.EditorChannelData.TIME_EPSILON)
					or nil
				local valueIndex = (t ~= nil) and panimaChannel:FindIndex(t, pfm.udm.EditorChannelData.TIME_EPSILON)
					or nil
				local valueIndexNext = (tNext ~= nil)
						and panimaChannel:FindIndex(tNext, pfm.udm.EditorChannelData.TIME_EPSILON)
					or nil
				if valueIndex ~= nil then
					if valueIndexNext ~= nil then
						self:SetCurveChannelValueCount(actor, path, valueIndex, valueIndexNext, 0, true)
					end
					if valueIndexPrev ~= nil then
						self:SetCurveChannelValueCount(actor, path, valueIndexPrev, valueIndex, 0, true)
					end

					-- Value index may have changed; Re-query
					valueIndex = panimaChannel:FindIndex(t, pfm.udm.EditorChannelData.TIME_EPSILON)
					panimaChannel:SetTime(valueIndex, time, true)
				end
			end
		end

		-- Update keyframe
		keyData:SetValue(keyIdx, value)

		-- Update dependent handles
		keyData:UpdateKeyframeDependencies(keyIdx)
		keyData:UpdateKeyframeDependencies(keyIdx + 1, true, false)
		keyData:UpdateKeyframeDependencies(keyIdx - 1, false, true)

		local oldKeyIndex = keyIdx
		local newKeyIdx = editorChannel:SetKeyTime(keyIdx, time, baseIndex)

		if newKeyIdx ~= nil then -- Key has been swapped
		else
			oldKeyIndex = nil
		end

		self:InvokeEventCallbacks(Component.EVENT_ON_KEYFRAME_UPDATED, {
			{
				actor = actor,
				animation = anim,
				channel = channel,
				udmChannel = udmChannel,
				keyIndex = newKeyIdx or keyIdx,
				oldKeyIndex = oldKeyIndex,
				typeComponentIndex = baseIndex,
			},
		})
		--
	end
end

function Component:SetChannelValue(actor, path, time, value, udmType, addKey, baseIndex, keyframeValue, data)
	data = data or {}
	if addKey == nil then
		addKey = true
	end

	if addKey == true and baseIndex == nil and keyframeValue == nil then
		local keyframeValue = value
		local numComponents = 1
		if udmType < udm.TYPE_COUNT then
			numComponents = udm.get_numeric_component_count(udmType)
			if udmType == udm.TYPE_QUATERNION then
				keyframeValue = keyframeValue:ToEulerAngles()
				numComponents = udm.get_numeric_component_count(udm.TYPE_EULER_ANGLES)
			end
		end
		for i = 0, numComponents - 1 do
			self:SetChannelValue(actor, path, time, value, udmType, addKey, i, keyframeValue, data)
		end
		return
	end

	if self.m_filmClip == nil or self.m_filmClip == nil then
		pfm.log(
			"Unable to apply channel value: No active film clip selected, or film clip has no animations!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end
	pfm.log(
		"Setting channel value "
			.. tostring(value)
			.. " (base index "
			.. (baseIndex and baseIndex or "n/a")
			.. ") of type "
			.. udm.type_to_string(udmType)
			.. " at timestamp "
			.. time
			.. " with channel path '"
			.. path
			.. "' to actor '"
			.. tostring(actor)
			.. "'...",
		pfm.LOG_CATEGORY_PFM
	)
	local anim, channel, animClip, isNewChannel = self:FindAnimationChannel(actor, path, true, udmType)

	if isNewChannel then
		self:InvokeEventCallbacks(Component.EVENT_ON_ANIMATION_CHANNEL_ADDED, { actor, anim, channel })
	end

	assert(channel ~= nil)
	if channel == nil then
		pfm.log(
			"Unable to apply channel value: No channel for property '" .. path .. "'!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return
	end

	local idx = channel:AddValue(time, value)
	anim:UpdateDuration()

	local keyIndex
	if addKey then
		local editorData = animClip:GetEditorData()
		local editorChannel = editorData:FindChannel(path, true)

		local keyData
		keyData, keyIndex = editorChannel:AddKey(time, baseIndex or 0)
		keyData:SetValue(keyIndex, udm.get_numeric_component(keyframeValue or value, baseIndex or 0))

		local function get_dt(key, ref)
			if data[key] == nil then
				return
			end
			return data[key] - ref
		end
		local inTime = get_dt("inTime", time) or -0.5
		local inDelta = get_dt("inDelta", value) or 0.0
		local outTime = get_dt("outTime", time) or 0.5
		local outDelta = get_dt("outDelta", value) or 0.0

		if data["inHandleType"] ~= nil then
			keyData:SetInHandleType(keyIndex, data["inHandleType"])
		end
		if data["outHandleType"] ~= nil then
			keyData:SetOutHandleType(keyIndex, data["outHandleType"])
		end

		keyData:SetInTime(keyIndex, inTime)
		keyData:SetInDelta(keyIndex, inDelta)
		keyData:SetOutTime(keyIndex, outTime)
		keyData:SetOutDelta(keyIndex, outDelta)
	end

	local udmChannel = animClip:GetChannel(path, udmType)
	self:InvokeEventCallbacks(Component.EVENT_ON_CHANNEL_VALUE_CHANGED, {
		{
			actor = actor,
			animation = anim,
			channel = channel,
			udmChannel = udmChannel,
			index = idx,
			oldIndex = idx,
			keyIndex = keyIndex,
			typeComponentIndex = baseIndex,
		},
	})
end

function Component:SetCurveChannelValueCount(
	actor,
	path,
	startIndex,
	endIndex,
	numValues,
	suppressCallback,
	removeBoundaryPoints
)
	if self.m_filmClip == nil or self.m_filmClip == nil then
		pfm.log(
			"Unable to apply channel value: No active film clip selected, or film clip has no animations!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end

	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path, true)
	if channel == nil then
		return false
	end

	local startTime = channel:GetTime(startIndex)
	local endTime = channel:GetTime(endIndex)
	if startIndex == false or endTime == false then
		return false
	end

	local startVal = channel:GetValue(startIndex)
	local endVal = channel:GetValue(endIndex)

	if removeBoundaryPoints then
		startIndex = startIndex - 1
		endIndex = endIndex + 1
	end

	local numCurValues = endIndex - startIndex - 1
	local times
	if type(numValues) == "table" then
		times = numValues
		numValues = #times
	end
	if numCurValues > numValues then
		local nRemove = numCurValues - numValues
		channel:RemoveValueRange(startIndex + 1, nRemove)
		endIndex = endIndex - nRemove
	elseif numCurValues < numValues then
		local nAdd = numValues - numCurValues
		channel:AddValueRange(startIndex + 1, nAdd)
		endIndex = endIndex + nAdd
	end

	local dt = endTime - startTime
	local numValuesIncludingEndpoints = numValues + 2
	local dtPerValue = dt / (numValuesIncludingEndpoints - 1)
	local curTime = startTime + dtPerValue
	local curIndex = startIndex + 1
	for i = 0, numValues - 1 do
		channel:SetTime(curIndex, (times ~= nil and times[i + 1]) or curTime)
		local f = (i + 1) / (numValuesIncludingEndpoints - 1)
		channel:SetValue(curIndex, udm.lerp(startVal, endVal, f, channel:GetValueType()))

		curTime = curTime + dtPerValue
		curIndex = curIndex + 1
	end

	local udmChannel = animClip:GetChannel(path, type)
	if suppressCallback ~= true then
		self:InvokeEventCallbacks(Component.EVENT_ON_CHANNEL_VALUE_CHANGED, {
			{
				actor = actor,
				animation = anim,
				channel = channel,
				udmChannel = udmChannel,
			},
		})
	end
	return true, endIndex
end

function Component:SetCurveRangeChannelValueCount(actor, path, startTime, endTime, numValues, suppressCallback)
	if self.m_filmClip == nil or self.m_filmClip == nil then
		pfm.log(
			"Unable to apply channel value: No active film clip selected, or film clip has no animations!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		return false
	end

	local anim, channel, animClip = self:FindAnimationChannel(actor, path)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(path, true)
	if channel == nil then
		return false
	end

	local startIndex
	local i0, i1, f = channel:FindInterpolationIndices(startTime)
	if i0 == nil then
		startIndex = 0
	else
		if f <= pfm.udm.EditorChannelData.TIME_EPSILON then
			startIndex = i0
		else
			startIndex = i1
		end
	end

	local endIndex
	i0, i1, f = channel:FindInterpolationIndices(endTime)
	if i0 == nil then
		endIndex = channel:GetValueCount() - 1
	else
		endIndex = i0
	end

	return self:SetCurveChannelValueCount(actor, path, startIndex, endIndex, numValues, suppressCallback, true)
end

function Component:SetRawAnimationData(actor, path, times, values, valueType)
	if #times > 1 then
		local anim, actorChannel, animClip = self:FindAnimationChannel(actor, path)
		if actorChannel ~= nil then
			-- Clear all previous values for the recorded time range
			local tFirst = times[1]
			local tLast = times[#times]
			local idxStart, idxEnd = actorChannel:FindIndexRangeInTimeRange(tFirst, tLast)
			if idxStart ~= nil and idxEnd > idxStart then
				local n = (idxEnd - idxStart) + 1
				self:SetCurveChannelValueCount(actor, path, idxStart, idxEnd, 0, true)
			end
		end
	end
	for i = 1, #times do
		local t = times[i]
		local v = values[i]
		self:SetChannelValue(actor, path, t, v, valueType, false, nil)
	end
	self:SetAnimationDirty(actor)
	self:InvokeEventCallbacks(Component.EVENT_ON_ACTOR_PROPERTY_CHANGED, { actor, path })
end

function Component:TestSetRawAnimationData(actor, path, times, values, valueType)
	local t = {}
	local minTime = math.huge
	local maxTime = -math.huge
	local minVal = math.huge
	local maxVal = -math.huge
	for i = 1, #times do
		local v = Vector2(times[i], values[i])
		minTime = math.min(minTime, times[i])
		maxTime = math.max(maxTime, times[i])
		minVal = math.min(minVal, values[i])
		maxVal = math.max(maxVal, values[i])
		table.insert(t, v)
	end

	t = {
		Vector2(0, 92.537322998047),
		Vector2(1.9304947853088, 74.62686920166),
		Vector2(5.0193061828613, 61.194026947021),
		Vector2(11.196907997131, 50.746265411377),
		Vector2(18.146718978882, 47.761192321777),
		Vector2(25.868721008301, 47.761192321777),
		Vector2(33.204639434814, 49.253719329834),
		Vector2(45.173748016357, 59.70149230957),
		Vector2(50.965244293213, 65.671646118164),
		Vector2(55.598457336426, 74.62686920166),
		Vector2(59.845546722412, 85.07462310791),
		Vector2(65.637069702148, 94.029846191406),
		Vector2(69.884162902832, 97.014923095703),
		Vector2(79.922775268555, 100),
		Vector2(86.100395202637, 97.014923095703),
		Vector2(90.733581542969, 86.567169189453),
		Vector2(94.98070526123, 73.134315490723),
		Vector2(97.297294616699, 52.238796234131),
		Vector2(98.455596923828, 40.298503875732),
		Vector2(99.227783203125, 4.4776029586792),
		Vector2(100, 0),
	}
	local minTime = math.huge
	local maxTime = -math.huge
	local minVal = math.huge
	local maxVal = -math.huge
	for _, v in ipairs(t) do
		minTime = math.min(minTime, v.x)
		maxTime = math.max(maxTime, v.x)
		minVal = math.min(minVal, v.y)
		maxVal = math.max(maxVal, v.y)
	end

	-- math.test only works properly in large value ranges, so we temporarily remap
	local remapScale = 100.0
	for i, v in ipairs(t) do
		v.x = math.remap(v.x, minTime, maxTime, 0.0, remapScale)
		v.y = math.remap(v.y, minVal, maxVal, 0.0, remapScale)
	end
	print("t = {")
	for _, x in ipairs(t) do
		print("Vector2(" .. x.x .. "," .. x.y .. "),")
	end
	print("}")

	local error = 8
	local result = math.test(t, error)
	for i, bc in ipairs(result) do
		for j = 1, 4 do
			bc[j].x = math.remap(bc[j].x, 0.0, remapScale, minTime, maxTime)
			bc[j].y = math.remap(bc[j].y, 0.0, remapScale, minVal, maxVal)
		end
	end
	for _, bc in ipairs(result) do
		local p0 = bc[1]
		local h0 = bc[2]
		local h1 = bc[3]
		local p1 = bc[4]
		self:SetChannelValue(actor, path, p0.x, p0.y, valueType, true, nil, nil, {
			["outTime"] = h0.x,
			["outDelta"] = h0.y,
			["outHandleType"] = pfm.udm.KEYFRAME_HANDLE_TYPE_FREE,
		})
		self:SetChannelValue(actor, path, p1.x, p1.y, valueType, true, nil, nil, {
			["inTime"] = h1.x,
			["inDelta"] = h1.y,
			["inHandleType"] = pfm.udm.KEYFRAME_HANDLE_TYPE_FREE,
		})
	end
end
ents.COMPONENT_PFM_ANIMATION_MANAGER = ents.register_component("pfm_animation_manager", Component)
Component.EVENT_ON_ACTOR_PROPERTY_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_ANIMATION_MANAGER, "on_actor_property_changed")
Component.EVENT_ON_ANIMATION_CHANNEL_ADDED =
	ents.register_component_event(ents.COMPONENT_PFM_ANIMATION_MANAGER, "on_animation_channel_added")
Component.EVENT_ON_CHANNEL_ADDED =
	ents.register_component_event(ents.COMPONENT_PFM_ANIMATION_MANAGER, "on_channel_added")
Component.EVENT_ON_CHANNEL_REMOVED =
	ents.register_component_event(ents.COMPONENT_PFM_ANIMATION_MANAGER, "on_channel_removed")
Component.EVENT_ON_CHANNEL_VALUE_CHANGED =
	ents.register_component_event(ents.COMPONENT_PFM_ANIMATION_MANAGER, "on_channel_value_changed")
Component.EVENT_ON_KEYFRAME_UPDATED =
	ents.register_component_event(ents.COMPONENT_PFM_ANIMATION_MANAGER, "on_keyframe_updated")
