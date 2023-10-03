--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("set_keyframe_data.lua")

local Command = util.register_class("pfm.CommandSetKeyframeTime", pfm.CommandSetKeyframeData)
function Command:Initialize(actorUuid, propertyPath, oldTime, newTime, baseIndex)
	return pfm.CommandSetKeyframeData.Initialize(
		self,
		actorUuid,
		propertyPath,
		oldTime,
		newTime,
		nil,
		nil,
		nil,
		baseIndex
	)
end
pfm.register_command("set_keyframe_time", Command)
