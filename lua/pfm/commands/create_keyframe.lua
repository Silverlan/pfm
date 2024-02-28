--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandCreateKeyframe", pfm.Command)
function Command.does_keyframe_exist(animManager, actorUuid, propertyPath, timestamp, baseIndex)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		return false
	end

	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	local editorChannel
	if animClip ~= nil then
		local editorData = animClip:GetEditorData()
		editorChannel = editorData:FindChannel(propertyPath)
		if editorChannel ~= nil then
			local keyIdx = editorChannel:FindKeyIndexByTime(animClip:LocalizeOffsetAbs(timestamp), baseIndex)
			if keyIdx ~= nil then
				-- Keyframe already exists
				return true, editorChannel, keyIdx
			end
		end
	end
	return false, editorChannel
end
function Command:Initialize(actorUuid, propertyPath, valueType, timestamp, baseIndex, value)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local res, subCmd = self:AddSubCommand("add_editor_channel", actor, propertyPath, valueType)
	if res == pfm.Command.RESULT_SUCCESS then
		subCmd:AddSubCommand("add_animation_channel", actor, propertyPath, pfm.to_animation_channel_type(valueType))
	end

	local baseIndices = self:GetBaseIndices(baseIndex, valueType)
	local allExist = true
	for _, baseIndex in ipairs(baseIndices) do
		local kfExists, editorChannel, keyIdx =
			Command.does_keyframe_exist(self:GetAnimationManager(), actorUuid, propertyPath, timestamp, baseIndex)
		if not kfExists then
			allExist = false
			break
		end
	end

	if allExist then
		-- Keyframes already exists
		self:LogFailure("Keyframe already exists!")
		return pfm.Command.RESULT_FAILURE
	end

	--[[ Commented because we animation data will automatically be removed anyway when the keyframe curve segments are updated.
	if editorChannel ~= nil then
		local graphCurve = editorChannel:GetGraphCurve()
		local keyData = graphCurve:GetKey(baseIndex)
		if keyData ~= nil then
			local t0 = keyData:GetTime(0)
			if t0 ~= nil and timestamp < t0 - pfm.udm.EditorChannelData.TIME_EPSILON then
				-- New keyframe will be the first keyframe in the graph, we'll have to delete the animation data between
				-- the first two keyframes
				self:AddSubCommand("delete_animation_channel_range", actorUuid, propertyPath, timestamp, t0)
			else
				local t1 = keyData:GetTime(keyData:GetKeyframeCount() - 1)
				if t1 ~= nil and timestamp > t1 + pfm.udm.EditorChannelData.TIME_EPSILON then
					-- New keyframe will be the last keyframe in the graph, we'll have to delete the animation data between
					-- the last two keyframes
					self:AddSubCommand("delete_animation_channel_range", actorUuid, propertyPath, t1, timestamp)
				end
			end
		end
	end]]

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	if baseIndex ~= nil then
		data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex)
	end
	if value ~= nil then
		data:SetValue("value", valueType, value)
	end
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetBaseIndices(baseIndex, valueType)
	local baseIndices = {}
	if baseIndex ~= nil then
		table.insert(baseIndices, baseIndex)
	else
		local n = udm.get_numeric_component_count(valueType)
		for i = 0, n - 1 do
			table.insert(baseIndices, i)
		end
	end
	return baseIndices
end
function Command:GetChannelData()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local strValueType = data:GetValue("propertyType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strValueType)
	if valueType == nil then
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return
	end

	local val = data:GetValue("value", valueType)

	local baseIndices = self:GetBaseIndices(valueBaseIndex, valueType)
	return actor, animClip, baseIndices, editorChannel, val, propertyPath
end
-- See https://stackoverflow.com/a/8405756/1879228
local function sliceBezier(points, t)
	local x1 = points[1].x
	local y1 = points[1].y
	local x2 = points[2].x
	local y2 = points[2].y
	local x3 = points[3].x
	local y3 = points[3].y
	local x4 = points[4].x
	local y4 = points[4].y

	local x12 = (x2 - x1) * t + x1
	local y12 = (y2 - y1) * t + y1

	local x23 = (x3 - x2) * t + x2
	local y23 = (y3 - y2) * t + y2

	local x34 = (x4 - x3) * t + x3
	local y34 = (y4 - y3) * t + y3

	local x123 = (x23 - x12) * t + x12
	local y123 = (y23 - y12) * t + y12

	local x234 = (x34 - x23) * t + x23
	local y234 = (y34 - y23) * t + y23

	local x1234 = (x234 - x123) * t + x123
	local y1234 = (y234 - y123) * t + y123

	return {
		Vector2(x1, y1),
		Vector2(x12, y12),
		Vector2(x123, y123),
		Vector2(x1234, y1234),
		Vector2(x234, y234),
		Vector2(x34, y34),
		Vector2(x4, y4),
	}
end
function Command:ApplyHandleValues(
	actor,
	propertyPath,
	editorChannel,
	baseIndex,
	timestamp,
	componentValue,
	prevKeyframeIdx,
	nextKeyframeIdx
)
	local function set_handle_property(prop, value, valueBaseIndex, handle, t)
		t = t or timestamp
		pfm.create_command(
			"set_keyframe_handle_" .. prop,
			tostring(actor:GetUniqueId()),
			propertyPath,
			t,
			nil,
			value,
			valueBaseIndex,
			handle
		):Execute()
	end
	local graphCurve = editorChannel:GetGraphCurve()

	local keyData = graphCurve:GetKey(baseIndex)
	local hOut = pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	local hIn = pfm.udm.EditorGraphCurveKeyData.HANDLE_IN

	if componentValue ~= nil then
		local timeCur = timestamp
		local valCur = componentValue

		local timePrev = keyData:GetTime(prevKeyframeIdx)
		local timeNext = keyData:GetTime(nextKeyframeIdx)
		local valPrev = keyData:GetValue(prevKeyframeIdx)
		local valNext = keyData:GetValue(nextKeyframeIdx)

		if timePrev ~= nil and timeNext ~= nil then
			local handleTimePrev = timePrev + keyData:GetHandleTimeOffset(prevKeyframeIdx, hOut)
			local handleTimeNext = timeNext + keyData:GetHandleTimeOffset(nextKeyframeIdx, hIn)
			local handleDeltaPrev = valPrev + keyData:GetHandleDelta(prevKeyframeIdx, hOut)
			local handleDeltaNext = valNext + keyData:GetHandleDelta(nextKeyframeIdx, hIn)

			local input = {
				Vector2(timePrev, valPrev),
				Vector2(handleTimePrev, handleDeltaPrev),
				Vector2(handleTimeNext, handleDeltaNext),
				Vector2(timeNext, valNext),
			}
			local sliced0 = sliceBezier(input, (timeCur - timePrev) / (timeNext - timePrev))
			local sliced1 = sliceBezier(
				{ input[4], input[3], input[2], input[1] },
				1.0 - ((timeCur - timePrev) / (timeNext - timePrev))
			)
			set_handle_property("time", sliced0[2].x - timePrev, baseIndex, hOut, timePrev)
			set_handle_property("delta", sliced0[2].y - valPrev, baseIndex, hOut, timePrev)
			set_handle_property("time", sliced0[3].x - timeCur, baseIndex, hIn)
			set_handle_property("delta", sliced0[3].y - valCur, baseIndex, hIn)

			set_handle_property("time", sliced1[2].x - timeNext, baseIndex, hIn, timeNext)
			set_handle_property("delta", sliced1[2].y - valNext, baseIndex, hIn, timeNext)
			set_handle_property("time", sliced1[2].x - timeCur, baseIndex, hOut)
			set_handle_property("delta", sliced1[2].y - valCur, baseIndex, hOut)
			return
		end
	end
	set_handle_property("time", -1.5, baseIndex, hIn)
	set_handle_property("delta", 0.0, baseIndex, hIn)
	set_handle_property("time", 1.5, baseIndex, hOut)
	set_handle_property("delta", 0.0, baseIndex, hOut)
end
function Command:CreateKeyframe(data)
	local actor, animClip, baseIndices, editorChannel, val, propertyPath = self:GetChannelData()
	if actor == nil then
		return false
	end

	local graphCurve = editorChannel:GetGraphCurve()
	local timestamp = self:GetLocalTime(animClip)

	for _, valueBaseIndex in ipairs(baseIndices) do
		local keyData = graphCurve:GetKey(valueBaseIndex)
		if keyData ~= nil then
			local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)
			if keyIdx ~= nil then
				-- Keyframe already exists
				self:LogFailure("Keyframe already exists!")
				return false
			end
		end
		local keyData, keyIdx = editorChannel:AddKey(timestamp, valueBaseIndex)
		if val ~= nil then
			editorChannel:SetKeyframeValue(keyIdx, val, valueBaseIndex)
		end
		if keyIdx ~= nil then
			local cval
			if val ~= nil then
				cval = udm.get_numeric_component(val, valueBaseIndex)
			end
			self:ApplyHandleValues(
				actor,
				propertyPath,
				editorChannel,
				valueBaseIndex,
				timestamp,
				cval,
				keyIdx - 1,
				keyIdx + 1
			)
		end
	end
	-- Commented, because this command should be wrapped in a keyframe_property_composition, which already rebuilds dirty graph curve segments
	-- self:RebuildDirtyGraphCurveSegments()
	return true
end
function Command:RemoveKeyframe(data)
	local actor, animClip, baseIndices, editorChannel = self:GetChannelData()
	if actor == nil then
		return false
	end

	local timestamp = self:GetLocalTime(animClip)
	for _, valueBaseIndex in ipairs(baseIndices) do
		editorChannel:RemoveKey(timestamp, valueBaseIndex)
		--[[pfm.create_command(
			"delete_bookmark",
			self:GetActiveFilmClip(),
			pfm.Project.KEYFRAME_BOOKMARK_SET_NAME,
			timestamp
		)
			:Execute()]]
	end
	-- Commented, because this command should be wrapped in a keyframe_property_composition, which already rebuilds dirty graph curve segments
	-- self:RebuildDirtyGraphCurveSegments()
	return true
end
function Command:GetAnimationClip()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end
	return animClip
end
function Command:RebuildDirtyGraphCurveSegments()
	local animClip = self:GetAnimationClip()
	if animClip == nil then
		return
	end
	local data = self:GetData()
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = editorChannel:GetGraphCurve()
	graphCurve:RebuildDirtyGraphCurveSegments()
end
function Command:GetLocalTime(channelClip)
	local data = self:GetData()
	local time = data:GetValue("timestamp", udm.TYPE_FLOAT)
	return channelClip:LocalizeOffsetAbs(time)
end
function Command:DoExecute(data)
	return self:CreateKeyframe(data)
end
function Command:DoUndo(data)
	return self:RemoveKeyframe(data)
end
pfm.register_command("create_keyframe", Command)
