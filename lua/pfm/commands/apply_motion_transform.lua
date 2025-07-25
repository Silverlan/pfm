-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("util/keyframe.lua")

local Command = util.register_class("pfm.CommandApplyMotionTransform", pfm.Command)
Command.MARKER_START_OUTER = 1
Command.MARKER_START_INNER = 2
Command.MARKER_END_INNER = 3
Command.MARKER_END_OUTER = 4
Command.MARKER_COUNT = 4
local segments = {
	{
		startMarker = Command.MARKER_START_OUTER,
		endMarker = Command.MARKER_START_INNER,
	},
	{
		startMarker = Command.MARKER_START_INNER,
		endMarker = Command.MARKER_END_INNER,
	},
	{
		startMarker = Command.MARKER_END_INNER,
		endMarker = Command.MARKER_END_OUTER,
	},
}
Command.store_keyframe_data = function(data, graphCurve)
	local numKeys = graphCurve:GetKeyCount()
	local kfKeyData = data:AddArray("keyframes", numKeys, udm.TYPE_ELEMENT)
	for baseIndex = 0, numKeys - 1 do
		local keyData = graphCurve:GetKey(baseIndex)
		local kfKeyframes = kfKeyData:Get(baseIndex)
		pfm.util.store_keyframe_data(kfKeyframes, keyData)
	end
end
Command.restore_keyframe_data = function(data, graphCurve)
	local kfKeyData = data:Get("keyframes")
	if kfKeyData == nil then
		return
	end
	local numKeys = graphCurve:GetKeyCount()
	for i = 0, numKeys - 1 do
		local keyData = graphCurve:GetKey(i)
		local kfKeyframes = kfKeyData:Get(i)
		pfm.util.restore_keyframe_data(kfKeyframes, keyData)
	end
end
function Command:Initialize(actorUuid, propertyPath, origTimes, newTimes)
	pfm.Command.Initialize(self)

	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local anim, channel, animClip = self:GetAnimationManager()
		:FindAnimationChannel(tostring(actor:GetUniqueId()), propertyPath, false)
	if channel == nil then
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = (editorChannel ~= nil) and editorChannel:GetGraphCurve() or nil
	if graphCurve ~= nil then
		Command.store_keyframe_data(data, graphCurve)
	end

	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)

	data:SetArrayValues("originalTimes", udm.TYPE_FLOAT, channel:GetTimes())
	data:SetArrayValues("originalValues", channel:GetValueType(), channel:GetValues())

	data:SetValue("origStartTime", udm.TYPE_FLOAT, origTimes[Command.MARKER_START_OUTER])
	data:SetValue("origInnerStartTime", udm.TYPE_FLOAT, origTimes[Command.MARKER_START_INNER])
	data:SetValue("origInnerEndTime", udm.TYPE_FLOAT, origTimes[Command.MARKER_END_INNER])
	data:SetValue("origEndTime", udm.TYPE_FLOAT, origTimes[Command.MARKER_END_OUTER])

	data:SetValue("startTime", udm.TYPE_FLOAT, newTimes[Command.MARKER_START_OUTER])
	data:SetValue("innerStartTime", udm.TYPE_FLOAT, newTimes[Command.MARKER_START_INNER])
	data:SetValue("innerEndTime", udm.TYPE_FLOAT, newTimes[Command.MARKER_END_INNER])
	data:SetValue("endTime", udm.TYPE_FLOAT, newTimes[Command.MARKER_END_OUTER])
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		return
	end

	local origBounds = {
		data:GetValue("origStartTime", udm.TYPE_FLOAT),
		data:GetValue("origInnerStartTime", udm.TYPE_FLOAT),
		data:GetValue("origInnerEndTime", udm.TYPE_FLOAT),
		data:GetValue("origEndTime", udm.TYPE_FLOAT),
	}
	local newBounds = {
		data:GetValue("startTime", udm.TYPE_FLOAT),
		data:GetValue("innerStartTime", udm.TYPE_FLOAT),
		data:GetValue("innerEndTime", udm.TYPE_FLOAT),
		data:GetValue("endTime", udm.TYPE_FLOAT),
	}

	local function ensure_min_dist(times, idx0, idx1)
		local diff = times[idx1] - times[idx0]
		if diff < panima.TIME_EPSILON * 1.5 then
			times[idx1] = times[idx0] + panima.TIME_EPSILON * 1.5
		end
	end
	for i = 1, #origBounds - 1 do
		ensure_min_dist(origBounds, i, i + 1)
		ensure_min_dist(newBounds, i, i + 1)
	end

	-- Make sure there are samples at the boundaries
	for _, t in ipairs(origBounds) do
		channel:InsertSample(t)
	end

	local ENABLE_DEBUG_OUTPUT = false
	if ENABLE_DEBUG_OUTPUT then
		channel:Validate()
	end

	local function calcNewTime(t)
		if t < origBounds[Command.MARKER_START_OUTER] then
			local shiftOffset = origBounds[Command.MARKER_START_OUTER] - newBounds[Command.MARKER_START_OUTER]
			return t - shiftOffset
		end
		if t > origBounds[Command.MARKER_END_OUTER] then
			local shiftOffset = origBounds[Command.MARKER_END_OUTER] - newBounds[Command.MARKER_END_OUTER]
			return t - shiftOffset
		end
		for _, seg in ipairs(segments) do
			if
				t >= origBounds[seg.startMarker] - panima.TIME_EPSILON * 1.5
				and t <= origBounds[seg.endMarker] + panima.TIME_EPSILON * 1.5
			then
				t = t - origBounds[seg.startMarker]
				t = t / (origBounds[seg.endMarker] - origBounds[seg.startMarker])
				t = t * (newBounds[seg.endMarker] - newBounds[seg.startMarker])
				t = t + newBounds[seg.startMarker]
				break
			end
		end
		return t
	end

	-- Handle keyframes
	local graphCurve = self:RestoreKeyframes(data, animClip, propertyPath)
	if graphCurve ~= nil then
		local numKeys = graphCurve:GetKeyCount()
		for baseIndex = 0, numKeys - 1 do
			local keyData = graphCurve:GetKey(baseIndex)
			local numKeyframes = keyData:GetTimeCount()
			for i = 0, numKeyframes - 1 do
				local time = keyData:GetTime(i)
				local inTime = keyData:GetInTime(i)
				local outTime = keyData:GetOutTime(i)
				local newTime = calcNewTime(time)
				local newInTime = calcNewTime(time + inTime) - newTime
				local newOutTime = calcNewTime(time + outTime) - newTime

				keyData:SetTime(i, newTime)
				keyData:SetInTime(i, newInTime)
				keyData:SetOutTime(i, newOutTime)
			end
		end
	end

	-- Calculate new time values
	local times = channel:GetTimesInRange(origBounds[Command.MARKER_START_OUTER], origBounds[Command.MARKER_END_OUTER])
	local newTimes = {}
	for i, t in ipairs(times) do
		table.insert(newTimes, calcNewTime(t))
	end

	-- Shift at edges
	local preShift = function()
		local shiftAmount = newBounds[Command.MARKER_START_OUTER] - origBounds[Command.MARKER_START_OUTER]
		local endTime = origBounds[Command.MARKER_START_OUTER] - panima.TIME_EPSILON * 2.5
		if ENABLE_DEBUG_OUTPUT then
			print("Shifting prefix values in range [" .. math.huge .. "," .. endTime .. "] by " .. shiftAmount)
		end
		-- We use epsilon *2.5 because ShiftTimeInRange searches for the timestamps in a range of [-epsilon,epsilon],
		-- but we don't want to shift the timestamp if it lies exactly at the target time
		channel:ShiftTimeInRange(-math.huge, endTime, shiftAmount, false)
		if ENABLE_DEBUG_OUTPUT then
			channel:Validate()
		end
	end

	local postShift = function()
		local shiftAmount = newBounds[Command.MARKER_END_OUTER] - origBounds[Command.MARKER_END_OUTER]
		local startTime = origBounds[Command.MARKER_END_OUTER] + panima.TIME_EPSILON * 2.5
		if ENABLE_DEBUG_OUTPUT then
			print("Shifting postfix values in range [" .. startTime .. "," .. math.huge .. "] by " .. shiftAmount)
		end
		channel:ShiftTimeInRange(startTime, math.huge, shiftAmount, false)
		if ENABLE_DEBUG_OUTPUT then
			channel:Validate()
		end
	end

	if ENABLE_DEBUG_OUTPUT then
		print("-----------------")
		print("Motion Transform")
		print("Original channel times:")
		console.print_table(channel:GetTimes())
	end

	-- If the new start time intersects with the pre-marker range, we have to shift before
	-- updating the time values in the range, otherwise we have to do it after
	if newBounds[Command.MARKER_START_OUTER] < origBounds[Command.MARKER_START_OUTER] then
		preShift()
	end
	-- Likewise for the end time
	if newBounds[Command.MARKER_END_OUTER] > origBounds[Command.MARKER_END_OUTER] then
		postShift()
	end

	local timeIndices = {}
	for _, t in ipairs(times) do
		local idx = channel:FindIndex(t)
		if idx == nil then
			self:LogFailure("No index found for timestamp" .. t .. " in animation channel " .. tostring(channel) .. "!")
			return false
		end
		table.insert(timeIndices, idx)
	end

	-- Apply new time values
	if ENABLE_DEBUG_OUTPUT then
		channel:Validate()
		print("Original Motion Times:")
		console.print_table(origBounds)
	end

	if ENABLE_DEBUG_OUTPUT then
		print("New Motion Times:")
		console.print_table(newBounds)
	end

	if ENABLE_DEBUG_OUTPUT then
		print("Time Indices:")
		console.print_table(timeIndices)
	end

	if ENABLE_DEBUG_OUTPUT then
		print("Channel times before applying new timestamps:")
		console.print_table(channel:GetTimes())
	end
	for i, idx in ipairs(timeIndices) do
		channel:SetTime(idx, newTimes[i], false, false)
	end
	if ENABLE_DEBUG_OUTPUT then
		print("Channel times after applying new timestamps:")
		console.print_table(channel:GetTimes())
	end
	table.sort(timeIndices)
	for i = #timeIndices, 1, -1 do
		local idx = timeIndices[i]
		local t = channel:GetTime(idx)
		if t ~= nil then
			channel:ResolveDuplicates(t)
		end
	end
	if ENABLE_DEBUG_OUTPUT then
		print("After resolving duplicate timestamps:")
		console.print_table(channel:GetTimes())
		channel:Validate()
	end

	if newBounds[Command.MARKER_START_OUTER] > origBounds[Command.MARKER_START_OUTER] then
		preShift()
	end
	if newBounds[Command.MARKER_END_OUTER] < origBounds[Command.MARKER_END_OUTER] then
		postShift()
	end

	local animClipChannel = animClip:FindChannel(propertyPath)
	if animClipChannel ~= nil then
		animClip:UpdateAnimationChannel(animClipChannel)
	end
end
function Command:RestoreKeyframes(data, animClip, propertyPath)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = editorChannel:GetGraphCurve()
	if graphCurve == nil then
		return
	end
	Command.restore_keyframe_data(data, graphCurve)
	return graphCurve
end
function Command:DoUndo(data)
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		return
	end

	self:RestoreKeyframes(data, animClip, propertyPath)

	-- Restore original animation data
	local originalTimes = data:GetArrayValues("originalTimes", udm.TYPE_FLOAT)
	local originalValues = data:GetArrayValues("originalValues", channel:GetValueType())
	channel:ClearAnimationData()
	channel:SetValues(originalTimes, originalValues)

	local animClipChannel = animClip:FindChannel(propertyPath)
	if animClipChannel ~= nil then
		animClip:UpdateAnimationChannel(animClipChannel)
	end
end
pfm.register_command("apply_motion_transform", Command)
