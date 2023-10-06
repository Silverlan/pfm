--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetKeyframeProperty", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, timestamp, baseIndex, handleId)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	actorUuid = tostring(actor:GetUniqueId())
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	if timestamp ~= nil then
		data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	end
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex or 0)

	if handleId ~= nil then
		data:SetValue("handle", udm.TYPE_UINT8, handleId)
	end

	return pfm.Command.RESULT_SUCCESS
end
function Command:GetAnimationClip()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end
	return animClip
end
function Command:RebuildDirtyGraphCurveSegments()
	local animClip = self:GetAnimationClip()
	if animClip == nil then
		return
	end
	local data = self:GetData()
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		return
	end
	local graphCurve = editorChannel:GetGraphCurve()
	graphCurve:RebuildDirtyGraphCurveSegments()
end
function Command:GetLocalTime(channelClip, action)
	local data = self:GetData()
	local time = data:GetValue("timestamp", udm.TYPE_FLOAT)
	return channelClip:ToDataTime(time)
end
function Command:GetHandleId()
	return self:GetData():GetValue("handle", udm.TYPE_UINT8)
end
function Command:ApplyValue(data, action)
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
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

	local timestamp = self:GetLocalTime(animClip, action)

	local data = self:GetData()
	local time = data:GetValue("timestamp", udm.TYPE_FLOAT)
	local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)

	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(valueBaseIndex)

	if keyIdx == nil then
		self:LogFailure("Keyframe doesn't exist!")
		return
	end

	local res = self:ApplyProperty(data, action, editorChannel, keyIdx, timestamp, valueBaseIndex)
	return res
end
function Command:ApplyProperty(data, action, editorChannel, keyIdx, timestamp, valueBaseIndex) end
function Command:DoExecute(data)
	return self:ApplyValue(data, pfm.Command.ACTION_DO)
end
function Command:DoUndo(data)
	return self:ApplyValue(data, pfm.Command.ACTION_UNDO)
end

local Command = util.register_class("pfm.CommandKeyframePropertyComposition", pfm.CommandSetKeyframeProperty)
function Command:Initialize(actorUuid, propertyPath, baseIndex, handleId)
	return pfm.CommandSetKeyframeProperty.Initialize(self, actorUuid, propertyPath, nil, baseIndex, handleId)
end
function Command:DoExecute(data)
	return pfm.Command.DoExecute(self, data)
end
function Command:DoUndo(data)
	return pfm.Command.DoUndo(self, data)
end
function Command:Execute(...)
	local res = pfm.CommandSetKeyframeProperty.Execute(self, ...)
	if res == false then
		return false
	end
	self:RebuildDirtyGraphCurveSegments()
	return true
end
function Command:Undo(...)
	local res = pfm.CommandSetKeyframeProperty.Undo(self, ...)
	if res == false then
		return false
	end
	self:RebuildDirtyGraphCurveSegments()
	return true
end
pfm.register_command("keyframe_property_composition", Command)

local function register_command(className, cmdName, oldKeyName, newKeyName, valueType, callback)
	local Command = util.register_class("pfm." .. className, pfm.CommandSetKeyframeProperty)
	function Command:Initialize(actorUuid, propertyPath, timestamp, oldVal, newVal, baseIndex, handleId)
		local res =
			pfm.CommandSetKeyframeProperty.Initialize(self, actorUuid, propertyPath, timestamp, baseIndex, handleId)

		if res ~= pfm.Command.RESULT_SUCCESS then
			return res
		end

		local data = self:GetData()
		if oldVal ~= nil then
			data:SetValue(oldKeyName, valueType, oldVal)
		end
		data:SetValue(newKeyName, valueType, newVal)
		return pfm.Command.RESULT_SUCCESS
	end
	function Command:ApplyProperty(data, action, editorChannel, keyIdx, timestamp, valueBaseIndex)
		local keyName
		if action == pfm.Command.ACTION_DO then
			keyName = newKeyName
		elseif action == pfm.Command.ACTION_UNDO then
			keyName = oldKeyName
		end
		local val = data:GetValue(keyName, udm.TYPE_FLOAT)
		if val == nil then
			return
		end

		local graphCurve = editorChannel:GetGraphCurve()
		local keyData = graphCurve:GetKey(valueBaseIndex)
		callback(keyData, keyIdx, val, self:GetHandleId())
	end
	pfm.register_command(cmdName, Command)
end
register_command(
	"CommandSetKeyframeEasingMode",
	"set_keyframe_easing_mode",
	"oldEasingMode",
	"newEasingMode",
	udm.TYPE_UINT8,
	function(keyData, keyIdx, val, handleId)
		keyData:SetEasingMode(keyIdx, val)
		keyData:SetKeyframeDirty(keyIdx)
	end
)
register_command(
	"CommandSetKeyframeInterpolationMode",
	"set_keyframe_interpolation_mode",
	"oldInterpolationMode",
	"newInterpolationMode",
	udm.TYPE_UINT8,
	function(keyData, keyIdx, val, handleId)
		keyData:SetInterpolationMode(keyIdx, val)
		keyData:SetKeyframeDirty(keyIdx)
	end
)
register_command(
	"CommandSetKeyframeHandleTime",
	"set_keyframe_handle_time",
	"oldTime",
	"newTime",
	udm.TYPE_FLOAT,
	function(keyData, keyIdx, val, handleId)
		keyData:SetHandleTimeOffset(keyIdx, handleId, val)
		keyData:SetKeyframeDirty(keyIdx)
	end
)
register_command(
	"CommandSetKeyframeHandleDelta",
	"set_keyframe_handle_delta",
	"oldDelta",
	"newDelta",
	udm.TYPE_FLOAT,
	function(keyData, keyIdx, val, handleId)
		keyData:SetHandleDelta(keyIdx, handleId, val)
		keyData:SetKeyframeDirty(keyIdx)
	end
)
register_command(
	"CommandSetKeyframeHandleType",
	"set_keyframe_handle_type",
	"oldType",
	"newType",
	udm.TYPE_UINT8,
	function(keyData, keyIdx, val, handleId)
		keyData:SetHandleType(keyIdx, handleId, val)
		keyData:SetKeyframeDirty(keyIdx)
	end
)
