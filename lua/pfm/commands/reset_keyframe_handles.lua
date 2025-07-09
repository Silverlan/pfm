-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("create_keyframe.lua")

local Command = util.register_class("pfm.CommandResetKeyframeHandles", pfm.CommandCreateKeyframe)
function Command:Initialize(actorUuid, propertyPath, valueType, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	if baseIndex ~= nil then
		data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex)
	end
	return true
end
function Command:DoExecute(data)
	local actor, animClip, baseIndices, editorChannel, val, propertyPath = self:GetChannelData()
	if actor == nil then
		return false
	end
	local graphCurve = editorChannel:GetGraphCurve()
	local timestamp = self:GetLocalTime(animClip)

	local hOut = pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	local hIn = pfm.udm.EditorGraphCurveKeyData.HANDLE_IN
	for _, valueBaseIndex in ipairs(baseIndices) do
		local keyframeIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)
		if keyframeIdx ~= nil then
			local prevKeyframeIdx = keyframeIdx - 1
			local nextKeyframeIdx = keyframeIdx + 1

			local keyData = graphCurve:GetKey(valueBaseIndex)
			local timeCur = keyData:GetTime(keyframeIdx)
			local timePrev = keyData:GetTime(prevKeyframeIdx)
			local timeNext = keyData:GetTime(nextKeyframeIdx)

			local function apply(d, handle, otherKeyframeIdx)
				local d3 = d / 3.0
				local hOther = (handle == hIn) and hOut or hIn
				local th0 = keyData:GetHandleTimeOffset(otherKeyframeIdx, hOther)
				local dh0 = keyData:GetHandleDelta(otherKeyframeIdx, hOther)
				local div = math.abs(th0)
				local ratio = 1.0
				if div > 0.001 then
					ratio = d3 / div
				end
				local v = Vector2((handle == hIn) and d3 or -d3, dh0 * ratio)
				keyData:SetHandleTimeOffset(otherKeyframeIdx, hOther, v.x)
				keyData:SetHandleDelta(otherKeyframeIdx, hOther, v.y)

				keyData:SetHandleTimeOffset(keyframeIdx, handle, (handle == hIn) and -d3 or d3)
				keyData:SetHandleDelta(keyframeIdx, handle, 0.0)
			end

			if timeCur ~= nil then
				if timePrev ~= nil then
					local d = timeCur - timePrev
					apply(d, hIn, prevKeyframeIdx)
				end
				if timeNext ~= nil then
					local d = timeNext - timeCur
					apply(d, hOut, nextKeyframeIdx)
				end
			end
		end
	end
	return true
end
function Command:DoUndo(data)
	-- No undo, this command is only meant to be used when creating a new keyframe, in which case no
	-- undo is necessary
end
pfm.register_command("reset_keyframe_handles", Command)
