--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("restore_animation_data.lua")

local Command = util.register_class("pfm.CommandMoveKeyframes", pfm.CommandStoreAnimationData)
function Command:Initialize(actorUuid, propertyPath, valueBaseIndex, animData)
	pfm.CommandStoreAnimationData.Initialize(self, actorUuid, propertyPath, valueBaseIndex, animData)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	return true
end
function Command:DoUndo(data)
	return true
end
function Command:Execute(...)
	local res = pfm.Command.Execute(self, ...)
	if res == false then
		return false
	end
	self:RestoreAnimationData(self:GetData())
	return true
end
function Command:Undo(...)
	local res = pfm.Command.Undo(self, ...)
	if res == false then
		return false
	end
	self:RestoreAnimationData(self:GetData())
	return true
end
pfm.register_command("move_keyframes", Command)
