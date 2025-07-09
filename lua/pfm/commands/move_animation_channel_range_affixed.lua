-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}
local AnimationDataBuffer = util.register_class("pfm.util.AnimationDataBuffer")
function AnimationDataBuffer:__init(data)
	if data == nil then
		self.m_rootData = udm.create("PFMADB", 1)
		data = self.m_data:GetAssetData():GetData()
	end
	self.m_data = data
end
function AnimationDataBuffer:GetData()
	return self.m_data
end
function AnimationDataBuffer:FindIndexRange(channel, startTime, endTime)
	return channel:FindIndexRangeInTimeRange(startTime, endTime)
end
function AnimationDataBuffer:StoreAnimationData(
	animManager,
	actor,
	propertyPath,
	startTime,
	endTime,
	valueBaseIndex,
	timeOffset,
	dataOffset
)
	timeOffset = timeOffset or 0.0
	dataOffset = dataOffset or 0.0
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return false, "Animation clip not found!"
	end
	local idxStart, idxEnd = self:FindIndexRange(channel, startTime, endTime)
	if idxStart == nil or idxEnd < idxStart then
		return false, "End time index precedes start time index!"
	end

	local data = self:GetData()
	local numIndices = (idxEnd - idxStart + 1)
	local channelValueType = channel:GetValueType()
	local valueType = (valueBaseIndex == nil) and channelValueType or udm.TYPE_FLOAT
	local udmAnimData = data:Add("animationData")
	udmAnimData:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	udmAnimData:SetValue("startTime", udm.TYPE_FLOAT, startTime)
	udmAnimData:SetValue("endTime", udm.TYPE_FLOAT, endTime)
	if valueBaseIndex ~= nil then
		udmAnimData:SetValue("valueBaseIndex", udm.TYPE_UINT8, valueBaseIndex)
	end

	local udmTimes = udmAnimData:AddArray("times", numIndices, udm.TYPE_FLOAT, udm.ARRAY_TYPE_COMPRESSED)
	local udmValues = udmAnimData:AddArray("values", numIndices, valueType, udm.ARRAY_TYPE_COMPRESSED)
	local idx = 0
	for i = idxStart, idxStart + (numIndices - 1) do
		udmTimes:SetValue(idx, udm.TYPE_FLOAT, channel:GetTime(i) + timeOffset)
		local v = channel:GetValue(i)
		if valueBaseIndex ~= nil then
			v = udm.get_numeric_component(v, valueBaseIndex, channelValueType)
		end
		udmValues:SetValue(idx, valueType, v + dataOffset)
		idx = idx + 1
	end

	udmTimes:ClearUncompressedMemory()
	udmValues:ClearUncompressedMemory()
	return true, idxStart
end
function AnimationDataBuffer:RestoreAnimationData(animManager, actor, propertyPath, timeOffset, valueOffset)
	local anim, panimaChannel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return false, "Animation clip not found!"
	end

	local data = self:GetData()
	local udmAnimData = data:Get("animationData")
	if udmAnimData:IsValid() == false then
		return false, "Animation data is invalid!"
	end
	local strValueType = udmAnimData:GetValue("valueType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strValueType)
	if valueType == nil then
		return "Unknown value type '" .. strValueType .. "'!"
	end

	local targetPath = panimaChannel:GetTargetPath():ToUri(false)
	local channel = animClip:FindChannel(targetPath)
	if channel == nil then
		return false, "Channel with target path '" .. targetPath .. "' not found!"
	end

	local times = udmAnimData:GetArrayValues("times", udm.TYPE_FLOAT)
	local values = udmAnimData:GetArrayValues("values", valueType)
	local startTime = udmAnimData:GetValue("startTime", udm.TYPE_FLOAT)
	local endTime = udmAnimData:GetValue("endTime", udm.TYPE_FLOAT)
	local valueBaseIndex = udmAnimData:GetValue("valueBaseIndex", udm.TYPE_UINT8)
	if timeOffset ~= nil or valueBaseIndex ~= nil then
		local channelValueType = panimaChannel:GetValueType()
		local n = udm.get_numeric_component_count(channelValueType)
		if valueBaseIndex ~= nil and n > 1 then
			-- We want to insert the values into panimaChannel, but we don't want to overwrite any existing values.
			-- Since our values are floats, but the value type of panimaChannel may be a composite type, like vec3,
			-- there are several steps we need to do:
			-- 1) Go through each time-value pair of panimaChannel in the time range [startTime,endTime] and calculate the interpolated
			-- component value at that time using our new values, then assign that value.
			-- 2) Calculate the corresponding values from panimaChannel for each t of our new times.
			-- The component value should then be replaced with the new value.
			-- 3) Merge the temporary channel into panimaChannel. Decimation should also be applied at this step, which will prevent the channel
			-- from growing continuously every time we do this.

			local tmpChannel = panima.Channel()
			tmpChannel:SetValueType(udm.TYPE_FLOAT)
			tmpChannel:InsertValues(times, values)
			-- Step 1)
			startTime = startTime + timeOffset
			endTime = endTime + timeOffset
			local curTimes, curValues = panimaChannel:GetDataInRange(startTime, endTime)
			for i, t in ipairs(curTimes) do
				local v = curValues[i]

				-- Calculate component value at t and assign: v[valueBaseIndex] = tmpChannel[t]
				v = udm.set_numeric_component(
					v,
					valueBaseIndex,
					channelValueType,
					tmpChannel:GetInterpolatedValue(t - timeOffset, false) + valueOffset
				)
				panimaChannel:InsertValue(t, v)
			end

			-- Step 2)
			local newValues = {}
			for i, t in ipairs(times) do
				local v = panimaChannel:GetInterpolatedValue(t + timeOffset, false)
				v = udm.set_numeric_component(v, valueBaseIndex, channelValueType, values[i] + valueOffset)
				table.insert(newValues, v)
			end

			-- Step 3)
			panimaChannel:InsertValues(
				times,
				newValues,
				timeOffset,
				panima.Channel.INSERT_FLAG_BIT_DECIMATE_INSERTED_DATA
			)
		else
			local tmpValues = {}
			for _, v in ipairs(values) do
				table.insert(tmpValues, v + valueOffset)
			end
			panimaChannel:InsertValues(times, tmpValues, timeOffset)
		end
	else
		panimaChannel:InsertValues(times, values)
	end
	animClip:UpdateAnimationChannel(channel)

	udmAnimData:Get("times"):ClearUncompressedMemory()
	udmAnimData:Get("values"):ClearUncompressedMemory()
	return true
end

--

local AffixedAnimationData = util.register_class("pfm.util.AffixedAnimationData")
function AffixedAnimationData:__init(data, animManager, actor, propertyPath, channel, keyData, baseIndex)
	local firstKeyframeIndex = 0
	local firstAnimDataTime = channel:GetTime(0)
	local firstKeyframeTime = keyData:GetTime(firstKeyframeIndex)
	local firstAnimDataValue = channel:GetValue(0)
	local firstKeyframeValue = keyData:GetValue(firstKeyframeIndex)

	local numKeyframes = keyData:GetKeyframeCount()
	local lastKeyframeIndex = numKeyframes - 1
	local lastAnimDataTime = channel:GetTime(channel:GetValueCount() - 1)
	local lastKeyframeTime = keyData:GetTime(lastKeyframeIndex)
	local lastKeyframeValue = keyData:GetValue(lastKeyframeIndex)

	local animDataInfo = {
		{
			identifier = "preAnimationData",
			animDataTime = firstAnimDataTime,
			keyframeTime = firstKeyframeTime,
			keyframeValue = firstKeyframeValue,
			prefix = true,
		},
		{
			identifier = "postAnimationData",
			animDataTime = lastAnimDataTime,
			keyframeTime = lastKeyframeTime,
			keyframeValue = lastKeyframeValue,
			prefix = false,
		},
	}
	for _, udmAnimDataInfo in ipairs(animDataInfo) do
		local animDataBuffer = pfm.util.AnimationDataBuffer(data:Add(udmAnimDataInfo.identifier))
		local startTime = udmAnimDataInfo.prefix and udmAnimDataInfo.animDataTime or udmAnimDataInfo.keyframeTime
		local endTime = udmAnimDataInfo.prefix and udmAnimDataInfo.keyframeTime or udmAnimDataInfo.animDataTime
		if endTime >= startTime then
			local startIdx = animDataBuffer:FindIndexRange(channel:GetPanimaChannel(), startTime, endTime)
			local animDataTimeStart = channel:GetTime(startIdx)
			local animDataValueStart = udm.get_numeric_component(channel:GetValue(startIdx), baseIndex)

			-- We want the data to start at (0,0) to simplify it
			local timeOffset = -animDataTimeStart
			local dataOffset = -animDataValueStart

			local res, startIdx = animDataBuffer:StoreAnimationData(
				animManager,
				actor,
				propertyPath,
				startTime,
				endTime,
				baseIndex,
				timeOffset,
				dataOffset
			)
			if res then
				-- Calculate the offsets of the animation data relative to the keyframe, so we can easily
				-- re-add the animation data later to the new keyframe position
				animDataBuffer
					:GetData()
					:SetValue("timeOffset", udm.TYPE_FLOAT, animDataTimeStart - udmAnimDataInfo.keyframeTime)
				animDataBuffer
					:GetData()
					:SetValue("dataOffset", udm.TYPE_FLOAT, animDataValueStart - udmAnimDataInfo.keyframeValue)
			end
		end
	end
end

local Command = util.register_class("pfm.CommandMoveAnimationChannelRangeAffixed", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, baseIndex, startTime, preStartTime, timeOffset, valueOffset)
	if preStartTime == nil then
		preStartTime = true
	end
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	self.m_animDataBuffer = pfm.util.AnimationDataBuffer(data)
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex or 0)
	data:SetValue("startTime", udm.TYPE_FLOAT, startTime)
	data:SetValue("preStartTime", udm.TYPE_BOOLEAN, preStartTime)
	data:SetValue("timeOffset", udm.TYPE_FLOAT, timeOffset)
	data:SetValue("valueOffset", udm.TYPE_FLOAT, valueOffset)
	return pfm.Command.RESULT_SUCCESS
end
function Command:StoreAnimationData(startTime, endTime)
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local res, err =
		self.m_animDataBuffer:StoreAnimationData(self:GetAnimationManager(), actor, propertyPath, startTime, endTime)
	if res == false then
		self:LogFailure(err)
	end
	return res
end
function Command:RestoreAnimationData()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		return false, "Actor '" .. actorUuid .. "' not found!"
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local res, err = self.m_animDataBuffer:RestoreAnimationData(self:GetAnimationManager(), actor, propertyPath)
	if res == false then
		self:LogFailure(err)
	end
	return res
end
function Command:DoExecute(data)
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)

	local anim, panimaChannel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return
	end

	local channel = animClip:FindChannel(panimaChannel:GetTargetPath():ToUri(false))
	if channel == nil then
		return
	end

	local udmAnimData = data:Get("animationData")
	local startTime = udmAnimData:GetValue("startTime", udm.TYPE_FLOAT)
	local endTime = udmAnimData:GetValue("endTime", udm.TYPE_FLOAT)
	panimaChannel:ClearRange(startTime, endTime, false)
	animClip:UpdateAnimationChannel(channel)
	return true
end
function Command:DoUndo(data)
	return self:RestoreAnimationData()
end
pfm.register_command("move_animation_channel_range_affixed", Command)
