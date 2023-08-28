--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("set_keyframe_property.lua")

local Command = util.register_class("pfm.CommandSetKeyframeTime", pfm.CommandSetKeyframeProperty)
function Command:Initialize(actorUuid, propertyPath, timestamp, oldTime, newTime, baseIndex)
	local res = pfm.CommandSetKeyframeProperty.Initialize(self, actorUuid, propertyPath, timestamp, baseIndex)

	if res ~= pfm.Command.RESULT_SUCCESS then
		return res
	end

	local data = self:GetData()
	data:SetValue("oldTime", udm.TYPE_FLOAT, oldTime)
	data:SetValue("newTime", udm.TYPE_FLOAT, newTime)
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
	local keyName
	if action == pfm.Command.ACTION_DO then
		keyName = "newTime"
	elseif action == pfm.Command.ACTION_UNDO then
		keyName = "oldTime"
	end

	local time = data:GetValue(keyName, udm.TYPE_FLOAT)
	local res = editorChannel:SetKeyTime(keyIdx, time, valueBaseIndex)
	if res == false then
		self:LogFailure("Failed to apply keyframe time!")
		return
	end
	self:RebuildDirtyGraphCurveSegments()
end
pfm.register_command("set_keyframe_time", Command)
