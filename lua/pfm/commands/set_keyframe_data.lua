--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("set_keyframe_property.lua")

local Command = util.register_class("pfm.CommandSetKeyframeDataBase", pfm.CommandSetKeyframeProperty)
function Command:Initialize(actorUuid, propertyPath, oldTime, newTime, oldValue, newValue, baseIndex)
	local res = pfm.CommandSetKeyframeProperty.Initialize(self, actorUuid, propertyPath, oldTime, baseIndex)

	if res ~= pfm.Command.RESULT_SUCCESS then
		return res
	end

	-- Test
	local actor = pfm.dereference(actorUuid)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return pfm.Command.RESULT_FAILURE
	end

	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	local numKeyframes = keyData:GetKeyframeCount()
	local data = self:GetData()
	if numKeyframes > 0 and channel:GetValueCount() > 0 then
		local firstKeyframeIndex = 0
		local firstAnimDataTime = channel:GetTime(0)
		local firstKeyframeTime = keyData:GetTime(firstKeyframeIndex)
		local firstAnimDataValue = channel:GetValue(0)
		local firstKeyframeValue = keyData:GetValue(firstKeyframeIndex)

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
			local res, startIdx =
				animDataBuffer:StoreAnimationData(animManager, actor, propertyPath, startTime, endTime)
			if res then
				local animDataTimeStart = channel:GetTime(startIdx)
				local animDataValueStart = channel:GetValue(startIdx)

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

	data:SetValue("oldTime", udm.TYPE_FLOAT, oldTime)
	data:SetValue("newTime", udm.TYPE_FLOAT, newTime)
	data:SetValue("oldValue", udm.TYPE_FLOAT, oldValue)
	data:SetValue("newValue", udm.TYPE_FLOAT, newValue)
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetLocalTime(channelClip, action)
	local keyName
	if action == pfm.Command.ACTION_DO then
		keyName = "oldTime"
	elseif action == pfm.Command.ACTION_UNDO then
		keyName = "newTime"
	end

	local data = self:GetData()
	local time = data:GetValue(keyName, udm.TYPE_FLOAT)
	return channelClip:LocalizeOffsetAbs(time)
end
function Command:ApplyProperty(data, action, editorChannel, keyIdx, timestamp, valueBaseIndex)
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)

	--------------------------

	local keyNameTime
	local keyNameValue
	if action == pfm.Command.ACTION_DO then
		keyNameTime = "newTime"
		keyNameValue = "newValue"
	elseif action == pfm.Command.ACTION_UNDO then
		keyNameTime = "oldTime"
		keyNameValue = "oldValue"
	end

	local time = data:GetValue(keyNameTime, udm.TYPE_FLOAT)
	local value = data:GetValue(keyNameValue, udm.TYPE_FLOAT)

	local res = editorChannel:SetKeyframeValue(keyIdx, value, valueBaseIndex)
	if res == false then
		self:LogFailure("Failed to apply keyframe value!")
		return
	end

	local res = editorChannel:SetKeyTime(keyIdx, time, valueBaseIndex)
	if res == false then
		self:LogFailure("Failed to apply keyframe time!")
		return
	end

	-- TEST
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local udmPreAnimationData = data:Get("preAnimationData")
	local udmPostAnimationData = data:Get("postAnimationData")
	local animDataInfo = {
		{
			data = udmPreAnimationData,
			prefix = true,
		},
		{
			data = udmPostAnimationData,
			prefix = false,
		},
	}
	for _, udmAnimDataInfo in ipairs(animDataInfo) do
		local udmAnimData = udmAnimDataInfo.data
		if udmAnimData ~= nil then
			local animManager = self:GetAnimationManager()
			local animDataBuffer = pfm.util.AnimationDataBuffer(udmAnimData)
			local keyData = editorChannel:GetGraphCurve():GetKey(valueBaseIndex)
			local idx
			if udmAnimDataInfo.prefix then
				idx = 0
			else
				idx = keyData:GetKeyframeCount() - 1
			end
			local kfTime = keyData:GetTime(idx)
			local kfValue = keyData:GetValue(idx)
			local timeOffset = kfTime + udmAnimData:GetValue("timeOffset", udm.TYPE_FLOAT)
			local dataOffset = kfValue + udmAnimData:GetValue("dataOffset", udm.TYPE_FLOAT)
			local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
			if udmAnimDataInfo.prefix then
				channel:ClearRange(-math.huge, kfTime, false)
			else
				channel:ClearRange(kfTime, math.huge, false)
			end
			local x = animDataBuffer:RestoreAnimationData(animManager, actor, propertyPath, timeOffset, dataOffset)
		end
	end
end
pfm.register_command("set_keyframe_data_base", Command)

local Command = util.register_class("pfm.CommandSetKeyframeData", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, oldTime, newTime, oldValue, newValue, baseIndex)
	pfm.Command.Initialize(self)

	local actor = pfm.dereference(actorUuid)
	actorUuid = tostring(actor:GetUniqueId())

	self:AddSubCommand(
		"set_keyframe_data_base",
		actorUuid,
		propertyPath,
		oldTime,
		newTime,
		oldValue,
		newValue,
		baseIndex
	)

	-- self:AddSubCommand("set_animation_value", actorUuid, propertyPath, newTime, oldValue, newValue)

	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	return true
end
function Command:DoUndo(data)
	return true
end
pfm.register_command("set_keyframe_data", Command)
