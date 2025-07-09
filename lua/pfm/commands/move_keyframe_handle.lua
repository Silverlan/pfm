-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("set_keyframe_handle_property.lua")

local Command = util.register_class("pfm.CommandMoveKeyframeHandle", pfm.CommandSetKeyframeHandleProperty)
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
	pfm.CommandSetKeyframeHandleProperty.Initialize(self, actorUuid, propertyPath, timestamp, baseIndex, handle)

	local data = self:GetData()
	data:SetValue("oldDeltaTime", udm.TYPE_FLOAT, oldDeltaTime)
	data:SetValue("deltaTime", udm.TYPE_FLOAT, deltaTime)
	data:SetValue("oldDeltaValue", udm.TYPE_FLOAT, oldDeltaValue)
	data:SetValue("deltaValue", udm.TYPE_FLOAT, deltaValue)
	return true
end
function Command:ApplyValue(isUndo, editorKeys, keyIdx, handle)
	local deltaTimeKey, deltaValueKey
	if isUndo then
		deltaTimeKey = "oldDeltaTime"
		deltaValueKey = "oldDeltaValue"
	else
		deltaTimeKey = "deltaTime"
		deltaValueKey = "deltaValue"
	end
	local data = self:GetData()
	local deltaTime = data:GetValue(deltaTimeKey, udm.TYPE_FLOAT)
	local deltaValue = data:GetValue(deltaValueKey, udm.TYPE_FLOAT)

	local affectedKeys = editorKeys:SetHandleData(keyIdx, handle, deltaTime, deltaValue)
	return true
end
pfm.register_command("move_keyframe_handle", Command)
