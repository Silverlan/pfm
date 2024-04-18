--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_transform_animation_channel.lua")

local Command = util.register_class("pfm.CommandTransformAnimationChannel", pfm.BaseCommandTransformAnimationChannel)
function Command:Initialize(actorUuid, propertyPath, basePose)
	local result = pfm.BaseCommandTransformAnimationChannel.Initialize(self, actorUuid, propertyPath)
	if result ~= pfm.Command.RESULT_SUCCESS then
		return result
	end
	self:GetData():SetValue("transform", udm.TYPE_SCALED_TRANSFORM, math.ScaledTransform(basePose))
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoApplyTransform(undo, data, actor, propertyPath, anim, channel)
	local transform = data:GetValue("transform", udm.TYPE_SCALED_TRANSFORM)
	if undo == false then
		channel:TransformGlobal(transform)
	else
		channel:TransformGlobal(transform:GetInverse())
	end
end
pfm.register_command("transform_animation_channel", Command)
