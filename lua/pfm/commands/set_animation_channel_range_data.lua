--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetAnimationChannelRangeData", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, times, values, valueType)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	if #times == 0 then
		self:LogFailure("No data to insert!")
		return pfm.Command.RESULT_FAILURE
	end

	local startTime = times[1]
	local endTime = times[#times]

	self:StoreAnimationData("animationData", startTime, endTime, times, values, valueType)

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	if
		self:StoreAnimationDataInTimeRange("originalAnimationData", actor, propertyPath, startTime, endTime) == false
	then
		data:Clear()
		self:LogFailure("Failed to write original animation data!")
		return pfm.Command.RESULT_FAILURE
	end
	return pfm.Command.RESULT_SUCCESS
end
function Command:StoreAnimationData(keyName, startTime, endTime, times, values, valueType)
	local data = self:GetData()
	local udmAnimData = data:Add(keyName)
	udmAnimData:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	udmAnimData:SetValue("startTime", udm.TYPE_FLOAT, startTime)
	udmAnimData:SetValue("endTime", udm.TYPE_FLOAT, endTime)
	udmAnimData:SetArrayValues("times", udm.TYPE_FLOAT, times)
	udmAnimData:SetArrayValues("values", udm.TYPE_FLOAT, values)
	return true
end
function Command:StoreAnimationDataInTimeRange(keyName, actor, propertyPath, startTime, endTime)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return false
	end
	local idxStart, idxEnd = channel:FindIndexRangeInTimeRange(startTime, endTime)
	if idxEnd < idxStart then
		return false
	end

	local numIndices = (idxEnd - idxStart + 1)
	local valueType = channel:GetValueType()

	local times = {}
	local values = {}

	for i = idxStart, idxStart + (numIndices - 1) do
		table.insert(times, channel:GetTime(i))
		table.insert(values, channel:GetValue(i))
	end

	return self:StoreAnimationData(keyName, startTime, endTime, times, values, valueType)
end
function Command:RestoreAnimationData(keyName)
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

	local udmAnimData = data:Get(keyName)
	local strValueType = udmAnimData:GetValue("valueType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strValueType)
	if valueType == nil then
		return
	end

	local channel = animClip:FindChannel(panimaChannel:GetTargetPath():ToUri(false))
	if channel == nil then
		return
	end

	local times = udmAnimData:GetArrayValues("times", udm.TYPE_FLOAT)
	local values = udmAnimData:GetArrayValues("values", valueType)
	local startTime = udmAnimData:GetValue("startTime", udm.TYPE_FLOAT)
	local endTime = udmAnimData:GetValue("endTime", udm.TYPE_FLOAT)

	panimaChannel:InsertValues(times, values)
	animClip:UpdateAnimationChannel(channel)
end
function Command:DoExecute(data)
	self:RestoreAnimationData("animationData")
	return true
end
function Command:DoUndo(data)
	self:RestoreAnimationData("originalAnimationData")
	return true
end
pfm.register_command("set_animation_channel_range_data", Command)
