--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetAnimationChannelRangeData", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, times, values)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	if self:StoreAnimationData(startTime, endTime) == false then
		data:Clear()
		self:LogFailure("Failed to write animation data!")
		return pfm.Command.RESULT_FAILURE
	end
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

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return false
	end
	local idxStart, idxEnd = channel:FindIndexRangeInTimeRange(startTime, endTime)
	if idxEnd < idxStart then
		return false
	end

	local numIndices = (idxEnd - idxStart + 1)
	local data = self:GetData()
	local valueType = channel:GetValueType()
	local udmAnimData = data:Add("animationData")
	udmAnimData:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	udmAnimData:SetValue("startTime", udm.TYPE_FLOAT, startTime)
	udmAnimData:SetValue("endTime", udm.TYPE_FLOAT, endTime)
	local udmTimes = udmAnimData:AddArray("times", numIndices, udm.TYPE_FLOAT)
	local udmValues = udmAnimData:AddArray("values", numIndices, valueType)
	local idx = 0
	for i = idxStart, idxStart + (numIndices - 1) do
		udmTimes:SetValue(idx, udm.TYPE_FLOAT, channel:GetTime(i))
		udmValues:SetValue(idx, valueType, channel:GetValue(i))
		idx = idx + 1
	end
	return true
end
function Command:RestoreAnimationData()
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

	local udmAnimData = data:Get("animationData")
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
	self:RestoreAnimationData()
	return true
end
pfm.register_command("set_animation_channel_range_data", Command)
