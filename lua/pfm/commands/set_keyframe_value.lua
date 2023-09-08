--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("set_keyframe_data.lua")

local Command = util.register_class("pfm.CommandSetKeyframeValue", pfm.CommandSetKeyframeData)
function Command:Initialize(actorUuid, propertyPath, timestamp, oldValue, newValue, baseIndex, affixedAnimationData)
	return pfm.CommandSetKeyframeData.Initialize(
		self,
		actorUuid,
		propertyPath,
		timestamp,
		nil,
		oldValue,
		newValue,
		baseIndex,
		affixedAnimationData
	)
end
pfm.register_command("set_keyframe_value", Command)
