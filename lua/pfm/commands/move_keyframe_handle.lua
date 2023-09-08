--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandMoveKeyframeHandle", pfm.Command)
function Command:Initialize(
	actorUuid,
	propertyPath,
	timestamp,
	baseIndex,
	handle,
	oldDeltaTime,
	deltaTime,
	oldDeltaValue,
	deltaValue
)
	pfm.Command.Initialize(self)

	local actor = pfm.dereference(actorUuid)
	actorUuid = tostring(actor:GetUniqueId())

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex or 0)
	data:SetValue("handle", udm.TYPE_STRING, (handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) and "in" or "out")
	data:SetValue("oldDeltaTime", udm.TYPE_FLOAT, oldDeltaTime)
	data:SetValue("deltaTime", udm.TYPE_FLOAT, deltaTime)
	data:SetValue("oldDeltaValue", udm.TYPE_FLOAT, oldDeltaValue)
	data:SetValue("deltaValue", udm.TYPE_FLOAT, deltaValue)
	return true
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
	local graphCurve = editorChannel:GetGraphCurve()
	graphCurve:RebuildDirtyGraphCurveSegments()
end
function Command:ApplyValue(deltaTimeKey, deltaValueKey)
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local strHandle = data:GetValue("handle", udm.TYPE_STRING)
	local handle = (strHandle == "in") and pfm.udm.EditorGraphCurveKeyData.HANDLE_IN
		or pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	if handle == nil then
		self:LogFailure("Invalid handle type '" .. strHandle .. "'!")
		return false
	end

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return false
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return false
	end

	local timestamp = data:GetValue("timestamp", udm.TYPE_FLOAT)
	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)
	local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)

	local editorGraphCurve = editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(valueBaseIndex)

	local deltaTime = data:GetValue(deltaTimeKey, udm.TYPE_FLOAT)
	local deltaValue = data:GetValue(deltaValueKey, udm.TYPE_FLOAT)
	local affectedKeys = editorKeys:SetHandleData(keyIdx, handle, deltaTime, deltaValue)
	editorKeys:SetKeyframeDirty(keyIdx)
	return true
end
function Command:DoExecute(data)
	local res = self:ApplyValue("deltaTime", "deltaValue")
	self:RebuildDirtyGraphCurveSegments()
	return res
end
function Command:DoUndo(data)
	local res = self:ApplyValue("oldDeltaTime", "oldDeltaValue")
	self:RebuildDirtyGraphCurveSegments()
	return res
end
pfm.register_command("move_keyframe_handle", Command)
