-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
