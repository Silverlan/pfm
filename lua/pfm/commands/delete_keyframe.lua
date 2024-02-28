--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("create_keyframe.lua")

local Command = util.register_class("pfm.CommandDeleteKeyframe", pfm.CommandCreateKeyframe)
function Command:Initialize(actorUuid, propertyPath, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	actorUuid = pfm.get_unique_id(actorUuid)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local kfExists, editorChannel, keyIdx =
		Command.does_keyframe_exist(self:GetAnimationManager(), actorUuid, propertyPath, timestamp, baseIndex)
	if kfExists == false then
		-- Keyframe doesn't exist
		self:LogFailure("Keyframe does not exist!")
		return pfm.Command.RESULT_FAILURE
	end

	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)

	local curVal = keyData:GetValue(keyIdx)
	self:AddSubCommand("set_keyframe_value", actorUuid, propertyPath, timestamp, udm.TYPE_FLOAT, curVal, 0.0, baseIndex) -- Need this to restore the value

	local inHandleType = keyData:GetInHandleType(keyIdx)
	local inDelta = keyData:GetInDelta(keyIdx)
	local inTime = keyData:GetInTime(keyIdx)
	local outHandleType = keyData:GetOutHandleType(keyIdx)
	local outDelta = keyData:GetOutDelta(keyIdx)
	local outTime = keyData:GetOutTime(keyIdx)
	-- Commands for restoring handle types and delta values/times
	self:AddSubCommand(
		"move_keyframe_handle",
		actorUuid,
		propertyPath,
		timestamp,
		baseIndex,
		pfm.udm.EditorGraphCurveKeyData.HANDLE_IN,
		inTime,
		0.0,
		inDelta,
		0.0
	)

	self:AddSubCommand(
		"move_keyframe_handle",
		actorUuid,
		propertyPath,
		timestamp,
		baseIndex,
		pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT,
		outTime,
		0.0,
		outDelta,
		0.0
	)

	self:AddSubCommand(
		"set_keyframe_handle_type",
		actorUuid,
		propertyPath,
		timestamp,
		inHandleType,
		pfm.udm.KEYFRAME_HANDLE_TYPE_FREE,
		baseIndex,
		pfm.udm.EditorGraphCurveKeyData.HANDLE_IN
	)

	self:AddSubCommand(
		"set_keyframe_handle_type",
		actorUuid,
		propertyPath,
		timestamp,
		outHandleType,
		pfm.udm.KEYFRAME_HANDLE_TYPE_FREE,
		baseIndex,
		pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	)

	if keyIdx == 0 then
		local t0 = keyData:GetTime(keyIdx)
		local t1 = keyData:GetTime(keyIdx + 1)
		if t1 ~= nil then
			-- We're deleting the first keyframe, so we have to delete the animation data between the first two keyframes
			self:AddSubCommand(
				"delete_animation_channel_range",
				actorUuid,
				propertyPath,
				t0,
				t1 - panima.VALUE_EPSILON * 2.0
			)
		end
	else
		local numKeyframes = keyData:GetKeyframeCount()
		if keyIdx == numKeyframes - 1 then
			local t0 = keyData:GetTime(keyIdx - 1)
			local t1 = keyData:GetTime(keyIdx)
			if t0 ~= nil then
				-- We're deleting the last keyframe, so we have to delete the animation data between the last two keyframes
				self:AddSubCommand(
					"delete_animation_channel_range",
					actorUuid,
					propertyPath,
					t0 + panima.VALUE_EPSILON * 2.0,
					t1
				)
			end
		end
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(udm.TYPE_FLOAT))
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
pfm.register_command("delete_keyframe", Command)
