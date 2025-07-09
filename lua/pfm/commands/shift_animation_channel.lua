-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("base_transform_animation_channel.lua")

local Command = util.register_class("pfm.CommandShiftAnimationChannel", pfm.BaseCommandTransformAnimationChannel)
function Command:Initialize(actorUuid, propertyPath, startTime, endTime, shiftAmount)
	local result =
		pfm.BaseCommandTransformAnimationChannel.Initialize(self, actorUuid, propertyPath, startTime, endTime)
	if result ~= pfm.Command.RESULT_SUCCESS then
		return result
	end
	self:GetData():SetValue("shiftAmount", udm.TYPE_FLOAT, shiftAmount)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoApplyTransform(undo, data, actor, propertyPath, anim, channel, startTime, endTime)
	if undo == false then
		local shiftAmount = data:GetValue("shiftAmount", udm.TYPE_FLOAT)
		channel:ShiftTimeInRange(startTime, endTime, shiftAmount)
	end
end
pfm.register_command("shift_animation_channel", Command)
