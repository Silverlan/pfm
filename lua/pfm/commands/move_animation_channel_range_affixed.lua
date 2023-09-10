--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
function AnimationDataBuffer:StoreAnimationData(animManager, actor, propertyPath, startTime, endTime)
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return false, "Animation clip not found!"
	end
	local idxStart, idxEnd = channel:FindIndexRangeInTimeRange(startTime, endTime)
	if idxStart == nil or idxEnd < idxStart then
		return false, "End time index precedes start time index!"
	end

	local data = self:GetData()
	local numIndices = (idxEnd - idxStart + 1)
	local valueType = channel:GetValueType()
	local udmAnimData = data:Add("animationData")
	udmAnimData:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	udmAnimData:SetValue("startTime", udm.TYPE_FLOAT, startTime)
	udmAnimData:SetValue("endTime", udm.TYPE_FLOAT, endTime)
	local udmTimes = udmAnimData:AddArray("times", numIndices, udm.TYPE_FLOAT, udm.ARRAY_TYPE_COMPRESSED)
	local udmValues = udmAnimData:AddArray("values", numIndices, valueType, udm.ARRAY_TYPE_COMPRESSED)
	local idx = 0
	for i = idxStart, idxStart + (numIndices - 1) do
		udmTimes:SetValue(idx, udm.TYPE_FLOAT, channel:GetTime(i))
		udmValues:SetValue(idx, valueType, channel:GetValue(i))
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

	if timeOffset ~= nil then
		local tmpValues = {}
		for _, v in ipairs(values) do
			table.insert(tmpValues, v + valueOffset)
		end
		panimaChannel:InsertValues(times, tmpValues, timeOffset)
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
		local res, startIdx = animDataBuffer:StoreAnimationData(animManager, actor, propertyPath, startTime, endTime)
		if res then
			local animDataTimeStart = channel:GetTime(startIdx)
			local animDataValueStart = udm.get_numeric_component(channel:GetValue(startIdx), baseIndex)

			-- This will move the time and data from absolute time to relative (to the keyframe)
			animDataBuffer:GetData():SetValue(
				"timeOffset",
				udm.TYPE_FLOAT,
				-animDataTimeStart + (animDataTimeStart - udmAnimDataInfo.keyframeTime)
			)

			animDataBuffer:GetData():SetValue(
				"dataOffset",
				udm.TYPE_FLOAT,
				-animDataValueStart + (animDataValueStart - udmAnimDataInfo.keyframeValue)
			)
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
