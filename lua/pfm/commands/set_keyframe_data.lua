--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("set_keyframe_property.lua")

local Command = util.register_class("pfm.CommandSetKeyframeDataBase", pfm.CommandSetKeyframeProperty)
function Command:Initialize(actorUuid, propertyPath, oldTime, newTime, valueType, oldValue, newValue, baseIndex)
	local res = pfm.CommandSetKeyframeProperty.Initialize(self, actorUuid, propertyPath, oldTime, baseIndex)

	if res ~= pfm.Command.RESULT_SUCCESS then
		return res
	end

	local data = self:GetData()
	newTime = newTime or oldTime
	data:SetValue("oldTime", udm.TYPE_FLOAT, oldTime)
	data:SetValue("newTime", udm.TYPE_FLOAT, newTime)
	if newValue ~= nil then
		data:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
		if oldValue ~= nil then
			data:SetValue("oldValue", valueType, oldValue)
		end
		data:SetValue("newValue", valueType, newValue)
	end
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

	if value ~= nil then
		local res = editorChannel:SetKeyframeValue(keyIdx, value, valueBaseIndex)
		if res == false then
			self:LogFailure("Failed to apply keyframe value!")
			return
		end
	end

	if time ~= nil then
		time = animClip:ToDataTime(time)
		local res = editorChannel:SetKeyTime(keyIdx, time, valueBaseIndex)
		if res == false then
			self:LogFailure("Failed to apply keyframe time!")
			return
		end
	end
end
pfm.register_command("set_keyframe_data_base", Command)

local Command = util.register_class("pfm.CommandSetKeyframeData", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, oldTime, newTime, valueType, oldValue, newValue, baseIndex)
	pfm.Command.Initialize(self)

	local actor = pfm.dereference(actorUuid)
	actorUuid = tostring(actor:GetUniqueId())

	self:AddSubCommand(
		"set_keyframe_data_base",
		actorUuid,
		propertyPath,
		oldTime,
		newTime,
		valueType,
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
