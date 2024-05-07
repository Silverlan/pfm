--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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

	local origTimes = {
		data:GetValue("origStartTime", udm.TYPE_FLOAT),
		data:GetValue("origInnerStartTime", udm.TYPE_FLOAT),
		data:GetValue("origInnerEndTime", udm.TYPE_FLOAT),
		data:GetValue("origEndTime", udm.TYPE_FLOAT),
	}
	local newTimes = {
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
	for i = 1, #origTimes - 1 do
		ensure_min_dist(origTimes, i, i + 1)
		ensure_min_dist(newTimes, i, i + 1)
	end

	-- Make sure there are samples at the boundaries
	for _, t in ipairs(origTimes) do
		channel:InsertSample(t)
	end

	local ENABLE_DEBUG_OUTPUT = false
	if ENABLE_DEBUG_OUTPUT then
		channel:Validate()
	end

	-- Calculate new time values
	local times = channel:GetTimesInRange(origTimes[Command.MARKER_START_OUTER], origTimes[Command.MARKER_END_OUTER])
	for _, t in ipairs(times) do
		for _, seg in ipairs(segments) do
			if
				t >= origTimes[seg.startMarker] - panima.TIME_EPSILON * 1.5
				and t <= origTimes[seg.endMarker] + panima.TIME_EPSILON * 1.5
			then
				t = t - origTimes[seg.startMarker]
				t = t / (origTimes[seg.endMarker] - origTimes[seg.startMarker])
				t = t * (newTimes[seg.endMarker] - newTimes[seg.startMarker])
				t = t + newTimes[seg.startMarker]
				break
			end
		end
	end

	-- Shift at edges
	local preShift = function()
		local shiftAmount = newTimes[Command.MARKER_START_OUTER] - origTimes[Command.MARKER_START_OUTER]
		local endTime = origTimes[Command.MARKER_START_OUTER] - panima.TIME_EPSILON * 2.5
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
		local shiftAmount = newTimes[Command.MARKER_END_OUTER] - origTimes[Command.MARKER_END_OUTER]
		local startTime = origTimes[Command.MARKER_END_OUTER] + panima.TIME_EPSILON * 2.5
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
	if newTimes[Command.MARKER_START_OUTER] < origTimes[Command.MARKER_START_OUTER] then
		preShift()
	end
	-- Likewise for the end time
	if newTimes[Command.MARKER_END_OUTER] > origTimes[Command.MARKER_END_OUTER] then
		postShift()
	end

	local timeIndices = {}
	for _, t in ipairs(origTimes) do
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
		console.print_table(origTimes)
	end

	if ENABLE_DEBUG_OUTPUT then
		print("New Motion Times:")
		console.print_table(newTimes)
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
		channel:ResolveDuplicates(channel:GetTime(idx))
	end
	if ENABLE_DEBUG_OUTPUT then
		print("After resolving duplicate timestamps:")
		console.print_table(channel:GetTimes())
		channel:Validate()
	end

	if newTimes[Command.MARKER_START_OUTER] > origTimes[Command.MARKER_START_OUTER] then
		preShift()
	end
	if newTimes[Command.MARKER_END_OUTER] < origTimes[Command.MARKER_END_OUTER] then
		postShift()
	end

	local animClipChannel = animClip:FindChannel(propertyPath)
	if animClipChannel ~= nil then
		animClip:UpdateAnimationChannel(animClipChannel)
	end
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
