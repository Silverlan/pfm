-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("set_keyframe_data.lua")

local Command = util.register_class("pfm.CommandSetKeyframeValue", pfm.CommandSetKeyframeData)
function Command:Initialize(
	actorUuid,
	propertyPath,
	timestamp,
	valueType,
	oldValue,
	newValue,
	baseIndex,
	affixedAnimationData
)
	assert(valueType == udm.TYPE_FLOAT)
	return pfm.CommandSetKeyframeData.Initialize(
		self,
		actorUuid,
		propertyPath,
		timestamp,
		timestamp,
		valueType,
		oldValue,
		newValue,
		baseIndex,
		affixedAnimationData
	)
end
pfm.register_command("set_keyframe_value", Command)
