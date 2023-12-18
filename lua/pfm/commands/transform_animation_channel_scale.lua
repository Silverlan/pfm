--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("transform_animation_channel.lua")

local Command = util.register_class("pfm.CommandTransformAnimationChannelScale", pfm.CommandTransformAnimationChannel)
function Command:Initialize(actorUuid, propertyPath, startTime, endTime, scale)
	local result = pfm.CommandTransformAnimationChannel.Initialize(self, actorUuid, propertyPath, startTime, endTime)
	if result ~= pfm.Command.RESULT_SUCCESS then
		return result
	end
	self:GetData():SetValue("scale", udm.TYPE_FLOAT, scale)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoApplyTransform(undo, data, actor, propertyPath, anim, channel, startTime, endTime)
	if undo == false then
		local scale = data:GetValue("scale", udm.TYPE_FLOAT)
		channel:ScaleTimeInRange(startTime, endTime, scale)
	end
end
pfm.register_command("scale_animation_channel", Command)
