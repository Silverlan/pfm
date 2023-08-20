--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetKeyframeValue", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, valueType, timestamp, oldValue, newValue, baseIndex)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	actorUuid = tostring(actor:GetUniqueId())
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	self:AddSubCommand("set_animation_value", actorUuid, propertyPath, timestamp, oldValue, newValue)

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	data:SetValue("oldValue", udm.TYPE_FLOAT, oldValue)
	data:SetValue("newValue", udm.TYPE_FLOAT, newValue)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex or 0)
	return pfm.Command.RESULT_SUCCESS
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
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local strType = data:GetValue("propertyType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strType)
	if valueType == nil then
		self:LogFailure("Invalid value type '" .. strType .. "'!")
		return
	end

	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return
	end

	local timestamp = self:GetLocalTime(animClip)
	local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)
	if keyIdx == nil then
		self:LogFailure("Keyframe doesn't exist!")
		return
	end

	local value = data:GetValue(keyNewValue, udm.TYPE_FLOAT)
	local res = editorChannel:SetKeyframeValue(keyIdx, value, valueBaseIndex)
	if res == false then
		self:LogFailure("Failed to apply keyframe value!")
		return
	end
end
function Command:DoExecute(data)
	return self:ApplyValue(data, "newValue")
end
function Command:DoUndo(data)
	return self:ApplyValue(data, "oldValue")
end
pfm.register_command("set_keyframe_value", Command)
