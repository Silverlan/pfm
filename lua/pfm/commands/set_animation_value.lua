--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetAnimationValue", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, timestamp, valueType, oldValue, newValue)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	actorUuid = tostring(actor:GetUniqueId())
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	--[[local channel = self:GetAnimationChannel(actor, propertyPath)
	if channel == nil then
		self:LogFailure(
			"Animation channel for property '" .. propertyPath .. "' of actor '" .. actorUuid .. "' not found!"
		)
		return pfm.Command.RESULT_FAILURE
	end]]

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	if oldValue ~= nil then
		data:SetValue("oldValue", valueType, oldValue)
	end
	data:SetValue("newValue", valueType, newValue)
	data:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetAnimationChannel(actor, propertyPath)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	return channel, anim, animClip
end
function Command:GetLocalTime(channelClip)
	local data = self:GetData()
	local time = data:GetValue("timestamp", udm.TYPE_FLOAT)
	return channelClip:LocalizeOffsetAbs(time)
end
function Command:ApplyValue(data, keyNewValue)
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local channel, anim = self:GetAnimationChannel(actor, propertyPath)
	if channel == nil then
		self:LogFailure(
			"Animation channel for property '" .. propertyPath .. "' of actor '" .. actorUuid .. "' not found!"
		)
		return false
	end

	local strValueType = data:GetValue("valueType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strValueType)
	if valueType == nil then
		return
	end

	local time = data:GetValue("timestamp", udm.TYPE_FLOAT)
	local value = data:GetValue(keyNewValue, valueType)
	local idx
	if value == nil then
		idx = channel:FindIndex(time)
		if idx ~= nil then
			channel:RemoveValue(idx)
		end
	else
		idx = channel:AddValue(time, value)
	end
	anim:UpdateDuration()
	return idx
end
function Command:DoExecute(data)
	return self:ApplyValue(data, "newValue")
end
function Command:DoUndo(data)
	return self:ApplyValue(data, "oldValue")
end
pfm.register_command("set_animation_value", Command)
