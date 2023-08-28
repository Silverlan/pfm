--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("create_keyframe.lua")

local Command = util.register_class("pfm.CommandDeleteKeyframes", pfm.CommandCreateKeyframe)
function Command:Initialize(actorUuid, propertyPath, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	if
		Command.does_keyframe_exist(self:GetAnimationManager(), actorUuid, propertyPath, timestamp, baseIndex) == false
	then
		-- Keyframe already exists
		self:LogFailure("Keyframe does not exist!")
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex or 0)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	return self:RemoveKeyframe(data)
end
function Command:DoUndo(data)
	return self:CreateKeyframe(data)
end
pfm.register_command("delete_keyframes", Command)
