--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandApplyCurveFitting", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, keyframeData, valueType, baseIndex)
	pfm.Command.Initialize(self)

	actorUuid = pfm.get_unique_id(actorUuid)
	local function set_handle_type(t, handleId)
		self:AddSubCommand(
			"set_keyframe_handle_type",
			actorUuid,
			propertyPath,
			t,
			nil,
			pfm.udm.KEYFRAME_HANDLE_TYPE_FREE,
			baseIndex,
			handleId
		)
	end
	local function set_handle_property(property, t, value, handleId)
		self:AddSubCommand(
			"set_keyframe_handle_" .. property,
			actorUuid,
			propertyPath,
			t,
			nil,
			value,
			baseIndex,
			handleId
		)
	end

	for _, bc in ipairs(keyframeData) do
		local p0 = bc[1]
		local h0 = bc[2]
		local h1 = bc[3]
		local p1 = bc[4]

		local t0 = p0.x
		local v0 = p0.y

		self:AddSubCommand("create_keyframe", actorUuid, propertyPath, valueType, t0, baseIndex)
		self:AddSubCommand("set_keyframe_value", actorUuid, propertyPath, t0, nil, v0, baseIndex)

		local t1 = p1.x
		local v1 = p1.y
		self:AddSubCommand("create_keyframe", actorUuid, propertyPath, valueType, t1, baseIndex)
		self:AddSubCommand("set_keyframe_value", actorUuid, propertyPath, t1, nil, v1, baseIndex)

		set_handle_type(t0, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
		set_handle_type(t1, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)

		set_handle_property("time", t0, h0.x - t0, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
		set_handle_property("delta", t0, h0.y - v0, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)

		set_handle_property("time", t1, h1.x - t1, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
		set_handle_property("delta", t1, h1.y - v1, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
	end

	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	return true
end
function Command:DoUndo(data)
	return true
end
pfm.register_command("apply_curve_fitting", Command)
