-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function pfm.udm.EditorChannelData:GetKeyframeTimeBoundaries(startTime, endTime, baseIndex)
	startTime = startTime or math.huge
	endTime = endTime or -math.huge
	local editorGraphCurve = self:GetGraphCurve()
	local numKeys = editorGraphCurve:GetKeyCount()
	local startTimeBoundary = startTime
	local endTimeBoundary = endTime
	local function find_boundaries(i)
		local pathKeys = editorGraphCurve:GetKey(i)

		local keyIndexStart = self:FindLowerKeyIndex(startTime, i) or 0
		local t = pathKeys:GetTime(keyIndexStart)
		if t ~= nil then
			startTimeBoundary = math.min(startTimeBoundary, t)
		end

		local keyIndexEnd = self:FindLowerKeyIndex(endTime, i) or 0
		t = pathKeys:GetTime(keyIndexEnd)
		if t ~= nil then
			if math.abs(t - endTime) > pfm.udm.EditorChannelData.TIME_EPSILON then
				-- endTime lies beyond keyframe, so we use the next keyframe instead
				keyIndexEnd = keyIndexEnd + 1
				t = pathKeys:GetTime(keyIndexEnd)
			end
			if t ~= nil then
				endTimeBoundary = math.max(endTimeBoundary, t)
			end
		end
	end
	if baseIndex ~= nil then
		find_boundaries(baseIndex)
	else
		for i = 0, numKeys - 1 do
			find_boundaries(i)
		end
	end
	if startTimeBoundary == math.huge or endTimeBoundary == math.huge then
		return
	end
	return startTimeBoundary, endTimeBoundary
end

function pfm.udm.EditorChannelData:ClearAnimationData()
	local editorGraphCurve = self:GetGraphCurve()
	editorGraphCurve:ClearAnimationData()
end

function pfm.udm.EditorChannelData:RebuildGraphCurveSegment(keyIndex, typeComponentIndex, minTime, maxTime)
	local keyIndexStart = keyIndex
	local keyIndexEnd = keyIndex + 1

	local editorGraphCurve = self:GetGraphCurve()

	local editorKeys = editorGraphCurve:GetKeys()[typeComponentIndex + 1]

	local numValues = editorKeys:GetValueCount()
	keyIndexStart = math.clamp(keyIndexStart, 0, math.max(numValues - 1, 0))
	keyIndexEnd = math.clamp(keyIndexEnd, keyIndexStart, math.max(numValues - 1, 0))

	-- TODO: Use minTime, maxTime
	local startTime = editorKeys:GetTime(keyIndexStart)
	local endTime = editorKeys:GetTime(keyIndexEnd)

	local startTimeBoundary, endTimeBoundary = self:GetKeyframeTimeBoundaries(startTime, endTime)
	editorGraphCurve:InitializeCurveSegmentAnimationData(startTimeBoundary, endTimeBoundary)
end

-- Quaternions are represented as euler angles in the interface and have to be
-- converted accordingly
local function channel_value_to_editor_value(val, channelValueType)
	if channelValueType == udm.TYPE_QUATERNION then
		return val:ToEulerAngles()
	elseif channelValueType == udm.TYPE_BOOLEAN then
		return val and 1.0 or 0.0
	end
	return val
end
local function channel_value_type_to_editor_value_type(channelValueType)
	if channelValueType == udm.TYPE_QUATERNION then
		return udm.TYPE_EULER_ANGLES
	elseif channelValueType == udm.TYPE_BOOLEAN then
		return udm.TYPE_FLOAT
	end
	return channelValueType
end
local function editor_value_to_channel_value(val, channelValueType)
	if channelValueType == udm.TYPE_QUATERNION then
		return val:ToQuaternion()
	elseif channelValueType == udm.TYPE_BOOLEAN then
		return (val >= 0.5) and true or false
	end
	return val
end

local function get_interpolation_mode(pathKeys, keyIndex, valueType)
	if valueType == udm.TYPE_BOOLEAN then
		return pfm.udm.INTERPOLATION_CONSTANT
	end
	return pathKeys:GetInterpolationMode(keyIndex)
end

local function get_default_value(valueType)
	return udm.get_default_value(valueType)
end

local function set_value_component_value(value, valueType, typeComponentIndex, vc)
	if udm.is_numeric_type(valueType) then
		return vc
	end
	value:Set(typeComponentIndex, vc)
	return value
end

local function calc_graph_curve_data_point_value(interpMethod, easingMode, pathKeys, keyIndex0, keyIndex1, time)
	-- assert(keyIndex1 == keyIndex0 + 1)

	local cp0Time = pathKeys:GetTime(keyIndex0)
	local cp0Val = pathKeys:GetValue(keyIndex0)

	local cp1Time = pathKeys:GetTime(keyIndex1)
	local cp1Val = pathKeys:GetValue(keyIndex1)

	local cp0OutTime = pathKeys:GetOutTime(keyIndex0)
	local cp0OutVal = pathKeys:GetOutDelta(keyIndex0)
	cp0OutTime = math.min(cp0Time + cp0OutTime, cp1Time - 0.0001)
	cp0OutVal = cp0Val + cp0OutVal

	local cp1InTime = pathKeys:GetInTime(keyIndex1)
	local cp1InVal = pathKeys:GetInDelta(keyIndex1)

	cp1InTime = math.max(cp1Time + cp1InTime, cp0Time + 0.0001)
	cp1InVal = cp1Val + cp1InVal

	local begin = cp0Val
	local change = cp1Val - cp0Val

	if interpMethod == pfm.udm.INTERPOLATION_CONSTANT then
		if time - cp1Time >= -pfm.udm.EditorChannelData.TIME_EPSILON then
			return cp1Val
		end
		return cp0Val
	end

	local tdiff = (cp1Time - cp0Time)
	local normalizedTime
	if tdiff < 0.0001 then
		normalizedTime = 0.0
	else
		normalizedTime = (time - cp0Time) / tdiff
	end
	if interpMethod == pfm.udm.INTERPOLATION_BEZIER then
		return math.calc_bezier_point(
			time,
			cp0Time,
			cp0Val,
			cp0OutTime,
			cp0OutVal,
			cp1InTime,
			cp1InVal,
			cp1Time,
			cp1Val
		)
	elseif interpMethod ~= pfm.udm.INTERPOLATION_LINEAR then
		local easingMethod = pfm.util.get_easing_method(interpMethod, easingMode)
		local duration = 1
		return easingMethod(normalizedTime, begin, change, duration)
	end

	-- Default: Linear interpolation
	return math.lerp(cp0Val, cp1Val, normalizedTime)
end

local function calc_component_value_at_timestamp(editorChannel, t, typeComponentIndex, valueType)
	local editorGraphCurve = editorChannel:GetGraphCurve()
	local pathKeys = editorGraphCurve:GetKey(typeComponentIndex)
	if pathKeys == nil or pathKeys:GetTimeCount() == 0 then
		return
	end

	local keyIndex0 = editorChannel:FindLowerKeyIndex(t, typeComponentIndex)
	if keyIndex0 == nil then
		return pathKeys:GetValue(0)
	end

	local interpMethod = get_interpolation_mode(pathKeys, keyIndex0, valueType)
	local easingMode = pathKeys:GetEasingMode(typeComponentIndex)

	if keyIndex0 == pathKeys:GetTimeCount() - 1 then
		return pathKeys:GetValue(pathKeys:GetTimeCount() - 1)
	end
	local keyIndex1 = keyIndex0 + 1
	return calc_graph_curve_data_point_value(interpMethod, easingMode, pathKeys, keyIndex0, keyIndex1, t)
end

local function calc_value_at_timestamp(editorChannel, t, valueType)
	local v = channel_value_to_editor_value(get_default_value(valueType), valueType)
	local n = udm.get_numeric_component_count(channel_value_type_to_editor_value_type(valueType))
	for i = 0, n - 1 do
		local vc = calc_component_value_at_timestamp(editorChannel, t, i, valueType)
		if vc ~= nil then
			v = set_value_component_value(v, valueType, i, vc)
		end
	end
	return v
end

local function calc_graph_curve_data_points(interpMethod, easingMode, pathKeys, keyIndex0, keyIndex1)
	assert(keyIndex1 == keyIndex0 + 1)
	local timestamps = {}
	local dataValues = {}
	local t0 = pathKeys:GetTime(keyIndex0)
	local v0 = pathKeys:GetValue(keyIndex0)
	local t1 = pathKeys:GetTime(keyIndex1)
	local v1 = pathKeys:GetValue(keyIndex1)

	table.insert(timestamps, t0)
	table.insert(timestamps, t1)

	if interpMethod == pfm.udm.INTERPOLATION_CONSTANT then
		table.insert(timestamps, t1 - 0.001)
	elseif interpMethod == pfm.udm.INTERPOLATION_LINEAR then
		-- Linear interpolation is the default method; Do nothing
	else
		-- Spline interpolation
		local begin
		local duration = 1
		local change

		local calcPointOnCurve
		if interpMethod == pfm.udm.INTERPOLATION_BEZIER then
			calcPointOnCurve = function(
				t,
				normalizedTime,
				dt,
				cp0Time,
				cp0Val,
				cp0OutTime,
				cp0OutVal,
				cp1InTime,
				cp1InVal,
				cp1Time,
				cp1Val
			)
				return math.calc_bezier_point(
					t,
					cp0Time,
					cp0Val,
					cp0OutTime,
					cp0OutVal,
					cp1InTime,
					cp1InVal,
					cp1Time,
					cp1Val
				)
			end
		else
			local easingMethod = pfm.util.get_easing_method(interpMethod, easingMode)
			calcPointOnCurve = function(
				t,
				normalizedTime,
				dt,
				cp0Time,
				cp0Val,
				cp0OutTime,
				cp0OutVal,
				cp1InTime,
				cp1InVal,
				cp1Time,
				cp1Val
			)
				return easingMethod(normalizedTime, begin, change, duration)
			end
		end

		local cp0Time = pathKeys:GetTime(keyIndex0)
		local cp0Val = pathKeys:GetValue(keyIndex0)

		local cp1Time = pathKeys:GetTime(keyIndex1)
		local cp1Val = pathKeys:GetValue(keyIndex1)

		local cp0OutTime = pathKeys:GetOutTime(keyIndex0)
		local cp0OutVal = pathKeys:GetOutDelta(keyIndex0)
		cp0OutTime = math.min(cp0Time + cp0OutTime, cp1Time - 0.0001)
		cp0OutVal = cp0Val + cp0OutVal

		local cp1InTime = pathKeys:GetInTime(keyIndex1)
		local cp1InVal = pathKeys:GetInDelta(keyIndex1)

		cp1InTime = math.max(cp1Time + cp1InTime, cp0Time + 0.0001)
		cp1InVal = cp1Val + cp1InVal

		begin = cp0Val
		change = cp1Val - cp0Val

		local function denormalize_time(normalizedTime)
			return cp0Time + (cp1Time - cp0Time) * normalizedTime
		end
		local function calc_point(normalizedTime, dt)
			if normalizedTime == 0.0 then
				return Vector2(normalizedTime, cp0Val)
			elseif normalizedTime == 1.0 then
				return Vector2(normalizedTime, cp1Val)
			end
			local t = denormalize_time(normalizedTime)
			return Vector2(
				normalizedTime,
				calcPointOnCurve(
					t,
					normalizedTime,
					dt,
					cp0Time,
					cp0Val,
					cp0OutTime,
					cp0OutVal,
					cp1InTime,
					cp1InVal,
					cp1Time,
					cp1Val
				)
			)
		end

		local maxStepCount = console.get_convar_int("pfm_animation_max_curve_sample_count") -- Number of samples will never exceed this value
		local dt = 1.0 / (maxStepCount - 1)
		local timeValues = { calc_point(0.0, dt) }
		local startPoint = calc_point(0.0, dt)
		local endPoint = calc_point(1.0, dt)
		local prevPoint = startPoint
		local n = (endPoint - startPoint):GetNormal()
		for i = 1, maxStepCount - 2 do
			local t = i * dt
			local point = calc_point(t, dt)
			local nToPoint = (point - prevPoint):GetNormal()
			local ang = math.deg(n:GetAngle(nToPoint))

			table.insert(timeValues, point)
			n = nToPoint

			prevPoint = point
		end

		for i, tv in ipairs(timeValues) do
			table.insert(timestamps, denormalize_time(tv.x))
		end
	end

	if #dataValues == 0 then
		for i = 1, #timestamps do
			dataValues[i] = calc_graph_curve_data_point_value(
				interpMethod,
				easingMode,
				pathKeys,
				keyIndex0,
				keyIndex1,
				timestamps[i]
			)
		end
	end

	-- Reduce points
	local points = {}
	for i = 1, #timestamps do
		table.insert(points, Vector2(timestamps[i], dataValues[i]))
	end
	local numOriginalPoints = #points
	points = math.reduce_curve_points(points, console.get_convar_float("pfm_animation_rdp_decimation_error"))
	pfm.log(
		"Number of points in curve segment has been reduced from " .. numOriginalPoints .. " to " .. #points,
		pfm.LOG_CATEGORY_PFM,
		pfm.LOG_SEVERITY_DEBUG
	)

	timestamps = {}
	dataValues = {}
	for _, p in ipairs(points) do
		table.insert(timestamps, p.x)
		table.insert(dataValues, p.x)
	end
	--

	return timestamps, dataValues
end

local function calc_equivalence_euler_angles(ang)
	ang = ang:Copy()
	ang.p = math.rad(ang.p)
	ang.y = math.rad(ang.y)
	ang.r = math.rad(ang.r)

	ang.p = math.pi - ang.p
	ang.y = ang.y + math.pi
	ang.r = ang.r + math.pi

	ang.p = math.deg(ang.p)
	ang.y = math.deg(ang.y)
	ang.r = math.deg(ang.r)
	ang:Normalize()
	return ang
end

local function find_closest_equivalence_euler_angles(ang, angRef)
	ang = ang:Copy()
	ang:Normalize()
	if angRef ~= nil then
		angRef = angRef:Copy()
		angRef:Normalize()
	end
	local candidates = { ang }
	table.insert(candidates, calc_equivalence_euler_angles(ang))

	if angRef == nil then
		-- Pick the candidate with the lowest roll and/or pitch (if multiple candidates have the same roll).
		-- This is subjective, but should result with the candidate that is probably the desired one.
		local bestCandidates = {}
		local bestCandidateVal
		for i, c in ipairs(candidates) do
			local r = math.abs(c.r)
			if bestCandidateVal == nil or r <= bestCandidateVal then
				bestCandidateVal = r
				table.insert(bestCandidates, c)
			end
		end

		local bestCandidate
		bestCandidateVal = nil
		for i, c in ipairs(bestCandidates) do
			local p = math.abs(c.p)
			if bestCandidateVal == nil or p < bestCandidateVal then
				bestCandidateVal = p
				bestCandidate = i
			end
		end
		return bestCandidates[bestCandidate]
	end

	-- Find the candidate with the shortest path to the reference angles

	if math.abs(math.rad(angRef.p) - math.pi / 2.0) < 0.001 and math.abs(math.rad(ang.p) - math.pi / 2.0) < 0.001 then
		-- A third equivalence is possible: https://math.stackexchange.com/a/4356879/161967
		-- TODO: This case is untested
		local equi = ang:Copy()
		local diff = angRef.y - equi.y
		equi.y = angRef.y
		equi.r = equi.r - diff
		equi:Normalize()

		table.insert(candidates, equi)
	end

	local bestCandidate
	local bestCandidateDiff
	for i, c in ipairs(candidates) do
		local d = math.abs(math.get_angle_difference(c.p, angRef.p))
			+ math.abs(math.get_angle_difference(c.y, angRef.y))
			+ math.abs(math.get_angle_difference(c.r, angRef.r))
		if bestCandidateDiff == nil or d < bestCandidateDiff then
			bestCandidateDiff = d
			bestCandidate = i
		end
	end
	return candidates[bestCandidate]
end

function pfm.udm.EditorChannelData:GetActor()
	return self:FindAnimationClip():GetActor()
end

function pfm.udm.EditorChannelData:FindAnimationClip()
	local animClip = self:GetAnimationClip()
	if animClip == nil then
		return
	end
	return animClip, animClip:GetPanimaAnimation()
end

function pfm.udm.EditorChannelData:FindAnimationChannel(path)
	local anim, animClip = self:FindAnimation(self:GetActor())
	if anim == nil then
		return
	end
	return anim, anim:FindChannel(path), animClip
end

function pfm.udm.EditorChannelData:GetFilmClip()
	return self:GetEditorAnimationData():GetFilmClip()
end

function pfm.udm.EditorGraphCurve:GetEditorChannelData()
	return self:GetParent()
end

function pfm.udm.EditorChannelData:GetEditorAnimationData()
	return self:GetParent()
end

function pfm.udm.EditorAnimationData:GetAnimationClip()
	return self:GetParent()
end

function pfm.udm.EditorAnimationData:GetFilmClip()
	return self:GetAnimationClip():GetFilmClip()
end

function pfm.udm.EditorGraphCurve:GetFilmClip()
	return self:GetEditorChannelData():GetFilmClip()
end

function pfm.udm.EditorGraphCurve:InitializeKeys(baseIndex)
	for i = self:GetKeyCount(), baseIndex do
		self:AddKey(i)
	end
end

function pfm.udm.EditorGraphCurve:RebuildDirtyGraphCurveSegments()
	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animationClip = editorAnimData:GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	local animClip = editorAnimData:GetAnimationClip()
	local channel = animClip:FindChannel(editorChannelData:GetTargetPath())
	for i, keyData in ipairs(self:GetKeys()) do
		if keyData:HasDirtyKeyframes() then
			keyData:RebuildDirtyGraphCurveSegments(i - 1)

			filmClip:CallChangeListeners("OnGraphCurveAnimationDataChanged", self, animClip, channel, i - 1)
		elseif keyData:GetKeyframeCount() == 0 then
			keyData:ClearAnimationData()
		end
	end
end

function pfm.udm.EditorGraphCurve:CallAnimationDataChangedListener(keyIdx)
	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animationClip = editorAnimData:GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	local animClip = editorAnimData:GetAnimationClip()
	local channel = animClip:FindChannel(editorChannelData:GetTargetPath())
	filmClip:CallChangeListeners("OnGraphCurveAnimationDataChanged", self, animClip, channel, keyIdx)
end

function pfm.udm.EditorGraphCurve:SetCurveChannelValueCount(startIndex, endIndex, numValues, removeBoundaryPoints)
	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animClip = editorAnimData:GetAnimationClip()
	local panimaAnimation = animClip:GetPanimaAnimation()
	local panimaChannel = panimaAnimation:FindChannel(editorChannelData:GetTargetPath())

	local startTime = panimaChannel:GetTime(startIndex)
	local endTime = panimaChannel:GetTime(endIndex)
	if startIndex == false or endTime == false then
		return false
	end

	local startVal = panimaChannel:GetValue(startIndex)
	local endVal = panimaChannel:GetValue(endIndex)

	if removeBoundaryPoints then
		startIndex = startIndex - 1
		endIndex = endIndex + 1
	end

	local numCurValues = endIndex - startIndex - 1
	local times
	if type(numValues) == "table" then
		times = numValues
		numValues = #times
	end
	if numCurValues > numValues then
		local nRemove = numCurValues - numValues
		panimaChannel:RemoveValueRange(startIndex + 1, nRemove)
		endIndex = endIndex - nRemove
	elseif numCurValues < numValues then
		local nAdd = numValues - numCurValues
		panimaChannel:AddValueRange(startIndex + 1, nAdd)
		endIndex = endIndex + nAdd
	end

	local dt = endTime - startTime
	local numValuesIncludingEndpoints = numValues + 2
	local dtPerValue = dt / (numValuesIncludingEndpoints - 1)
	local curTime = startTime + dtPerValue
	local curIndex = startIndex + 1
	pfm.log("Changing curve channel value count to " .. numValues .. "...", pfm.LOG_CATEGORY_PFM)
	for i = 0, numValues - 1 do
		panimaChannel:SetTime(curIndex, (times ~= nil and times[i + 1]) or curTime)
		local f = (i + 1) / (numValuesIncludingEndpoints - 1)
		panimaChannel:SetValue(curIndex, udm.lerp(startVal, endVal, f, panimaChannel:GetValueType()))

		curTime = curTime + dtPerValue
		curIndex = curIndex + 1
	end

	return true, endIndex
end

function pfm.udm.EditorGraphCurve:SetCurveRangeChannelValueCount(startTime, endTime, numValues)
	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animClip = editorAnimData:GetAnimationClip()
	local panimaAnimation = animClip:GetPanimaAnimation()
	local panimaChannel = panimaAnimation:FindChannel(editorChannelData:GetTargetPath())

	local startIndex
	local i0, i1, f = panimaChannel:FindInterpolationIndices(startTime)
	if i0 == nil then
		startIndex = 0
	else
		if f <= pfm.udm.EditorChannelData.TIME_EPSILON then
			startIndex = i0
		else
			startIndex = i1
		end
	end

	local endIndex
	i0, i1, f = panimaChannel:FindInterpolationIndices(endTime)
	if i0 == nil then
		endIndex = panimaChannel:GetValueCount() - 1
	else
		endIndex = i0
	end

	return self:SetCurveChannelValueCount(startIndex, endIndex, numValues, true)
end

function pfm.udm.EditorGraphCurve:CalcUiCurveValues(typeComponentIndex, translateTime, valueTranslator)
	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animClip = editorAnimData:GetAnimationClip()
	local channel = animClip:FindChannel(editorChannelData:GetTargetPath())
	if channel == nil then
		return
	end

	local panimaAnimation = animClip:GetPanimaAnimation()
	local panimaChannel = panimaAnimation:FindChannel(editorChannelData:GetTargetPath())
	local valueType = panimaChannel:GetValueType()

	local times = channel:GetTimes()
	local values = channel:GetValues()

	local curveValues = {}

	-- Quaternions are not very user friendly, so when working with quaternions, we'll want to display them as euler angles in the interface instead.
	-- However, since euler angles are not unique and converting a quaternion to euler angles can have multiple results, we have to do some additional considerations
	-- to prevent unnatural rotation paths.
	local prevVal
	local minKeyframeTime
	local maxKeyframeTime
	if valueType == udm.TYPE_QUATERNION and #times > 0 and editorChannelData ~= nil then
		prevVal = calc_value_at_timestamp(editorChannelData, animClip:GlobalizeTimeOffset(times[1]), valueType)
		if prevVal ~= nil then
			prevVal = find_closest_equivalence_euler_angles(prevVal)
		else
			prevVal = channel_value_to_editor_value(get_default_value(valueType), valueType)
		end

		local editorGraphCurve = editorChannelData:GetGraphCurve()
		local n = udm.get_numeric_component_count(channel_value_type_to_editor_value_type(valueType))
		for i = 0, n - 1 do
			local pathKeys = editorGraphCurve:GetKey(i)
			if pathKeys ~= nil and pathKeys:GetTimeCount() > 0 then
				local t0 = pathKeys:GetTime(0)
				local t1 = pathKeys:GetTime(pathKeys:GetTimeCount() - 1)

				if minKeyframeTime == nil then
					minKeyframeTime = t0
				else
					minKeyframeTime = math.min(minKeyframeTime, t0)
				end

				if maxKeyframeTime == nil then
					maxKeyframeTime = t1
				else
					maxKeyframeTime = math.max(maxKeyframeTime, t1)
				end
			end
		end
	end

	minKeyframeTime = (minKeyframeTime ~= nil) and translateTime(minKeyframeTime) or nil
	maxKeyframeTime = (maxKeyframeTime ~= nil) and translateTime(maxKeyframeTime) or nil
	for i = 1, #times do
		local t = translateTime(times[i])
		local v = values[i]
		v = (valueTranslator ~= nil) and valueTranslator(v) or v
		v = channel_value_to_editor_value(v, valueType)
		if valueType == udm.TYPE_QUATERNION then
			-- If we're dealing with quaternion values:
			-- If the timestamp lies within two keyframes, we can calculate the correct euler angles directly.
			-- If the timestamp does *not* lie within two keyframes, we have to take the quaternion value and convert it to euler angles instead. This is not ideal,
			-- as the same quaternion orientation can be represented by multiple different euler angle configurations. In this case some assumptions have to be made
			-- about which euler angle configuration is the desired one. There is no objective solution and this may result in unexpected curve paths in some cases.
			if
				minKeyframeTime ~= nil
				and maxKeyframeTime ~= nil
				and t + pfm.udm.EditorChannelData.TIME_EPSILON >= minKeyframeTime
				and t - pfm.udm.EditorChannelData.TIME_EPSILON <= maxKeyframeTime
			then
				v = calc_value_at_timestamp(editorChannelData, t, valueType)
			else
				v = find_closest_equivalence_euler_angles(v, prevVal)
			end
			prevVal = v
		end
		v = udm.get_numeric_component(v, typeComponentIndex)
		table.insert(curveValues, { t, v })
	end
	return curveValues
end

function pfm.udm.EditorGraphCurve:ClearAnimationData()
	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animClip = editorAnimData:GetAnimationClip()
	local channel = animClip:FindChannel(editorChannelData:GetTargetPath())
	if channel == nil then
		return
	end
	channel:GetPanimaChannel():ClearAnimationData()
end

function pfm.udm.EditorGraphCurve:InitializeCurveSegmentAnimationData(startTime, endTime)
	debug.start_profiling_task("pfm_animation_curve_update")

	local localStartTime = startTime
	local localEndTime = endTime

	local editorChannelData = self:GetEditorChannelData()
	local editorAnimData = editorChannelData:GetEditorAnimationData()
	local animClip = editorAnimData:GetAnimationClip()
	local channel = animClip:FindChannel(editorChannelData:GetTargetPath())
	if channel == nil then
		debug.stop_profiling_task()
		return
	end

	local panimaAnimation = animClip:GetPanimaAnimation()
	local panimaChannel = panimaAnimation:FindChannel(editorChannelData:GetTargetPath())

	pfm.log(
		"Initializing graph curve data in range [" .. startTime .. "," .. endTime .. "]...",
		pfm.LOG_CATEGORY_PFM,
		pfm.LOG_SEVERITY_DEBUG
	)
	local valueIndex0 = panimaChannel:FindIndex(localStartTime, pfm.udm.EditorChannelData.TIME_EPSILON)
	local valueIndex1 = panimaChannel:FindIndex(localEndTime, pfm.udm.EditorChannelData.TIME_EPSILON)
	local valueType = panimaChannel:GetValueType()
	local isQuatType = (valueType == udm.TYPE_QUATERNION) -- Some special considerations are required for quaternions
	if valueIndex0 == nil then
		-- Value doesn't matter and will get overwritten further below
		valueIndex0 = panimaChannel:AddValue(
			localStartTime,
			panimaChannel:GetInterpolatedValue(localStartTime, false) or get_default_value(valueType)
		)
	end
	if valueIndex1 == nil then
		-- Value doesn't matter and will get overwritten further below
		valueIndex1 = panimaChannel:AddValue(
			localEndTime,
			panimaChannel:GetInterpolatedValue(localEndTime, false) or get_default_value(valueType)
		)
	end

	--[[if valueIndex0 == nil or valueIndex1 == nil then
		local key = (valueIndex0 == nil) and keyIndex0 or keyIndex1
		pfm.log(
			"Animation graph key "
				.. key
				.. " at timestamp "
				.. editorKeys:GetTime(key)
				.. " has no associated animation data value!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		-- return
	end]]

	-- Ensure that animation values at keyframe timestamps match the keyframe values
	--channel:SetValue(valueIndex0,keyframeValueToChannelValue(keyIndex0,valueIndex0))
	--channel:SetValue(valueIndex1,keyframeValueToChannelValue(keyIndex1,valueIndex1))
	--

	-- We have to delete all of the animation values for this curve segment, which may also
	-- affect other paths if this is a composite type (e.g. vec3).
	-- Each path may have its own set of timestamps for which we need to update the data, so
	-- we'll collect all of them.
	local numPaths = self:GetKeyCount()
	local timestampData = {}
	local keyframesInTimeframePerKey = {}
	for i = 0, numPaths - 1 do
		local pathKeys = self:GetKey(i)
		local idx = editorChannelData:FindLowerKeyIndex(localStartTime, i)
		local hasLowerIndex = (idx ~= nil)
		if idx == nil and pathKeys:GetTimeCount() > 0 then
			idx = 0
		end
		-- Collect timestamps for all keyframe sets that intersect our time range
		if idx ~= nil then
			local t0 = pathKeys:GetTime(idx)
			assert(t0 ~= nil)
			local t1 = pathKeys:GetTime(idx + 1)
			if t1 ~= nil then
				while t1 ~= nil do
					if t0 + pfm.udm.EditorChannelData.TIME_EPSILON >= localEndTime then
						break
					end
					if t1 > localStartTime and (t1 - localStartTime) > pfm.udm.EditorChannelData.TIME_EPSILON then
						-- Segment is in range
						keyframesInTimeframePerKey[i] = keyframesInTimeframePerKey[i] or {}
						table.insert(keyframesInTimeframePerKey[i], idx)

						local interpMethod = get_interpolation_mode(pathKeys, idx, valueType)
						local easingMode = pathKeys:GetEasingMode(idx)
						local segTimestamps, segDataValues =
							calc_graph_curve_data_points(interpMethod, easingMode, pathKeys, idx, idx + 1)
						for _, t in ipairs(segTimestamps) do
							if t - pfm.udm.EditorChannelData.TIME_EPSILON >= t1 then
								break
							end
							if
								t + pfm.udm.EditorChannelData.TIME_EPSILON >= localStartTime
								and t - pfm.udm.EditorChannelData.TIME_EPSILON <= localEndTime
							then
								table.insert(timestampData, t)
							end
						end
					end
					idx = idx + 1
					t0 = t1
					t1 = pathKeys:GetTime(idx + 1)
				end
			else
				keyframesInTimeframePerKey[i] = keyframesInTimeframePerKey[i] or {}
				table.insert(keyframesInTimeframePerKey[i], idx)
				table.insert(timestampData, t0)
			end
		end

		local firstKeyframeTime = pathKeys:GetTime(0)
		local lastKeyframeTime = pathKeys:GetTime(pathKeys:GetTimeCount() - 1)

		-- Our time range may exceed the range of the keyframes for this component,
		-- in which case we have to consider the raw animation values before the first keyframe
		-- and/or after the last keyframe
		if localStartTime ~= nil and firstKeyframeTime ~= nil then
			local timesPre = panimaChannel:GetDataInRange(localStartTime, firstKeyframeTime)
			for _, t in ipairs(timesPre) do
				table.insert(timestampData, t)
			end
		end

		if lastKeyframeTime ~= nil and localEndTime ~= nil then
			local timesPost = panimaChannel:GetDataInRange(lastKeyframeTime, localEndTime)
			for _, t in ipairs(timesPost) do
				table.insert(timestampData, t)
			end
		end
	end

	-- Make sure our start and endpoints are included
	table.insert(timestampData, localStartTime)
	table.insert(timestampData, localEndTime)

	table.sort(timestampData)

	-- Merge duplicate timestamps
	local i = 1
	while i < #timestampData do
		local t0 = timestampData[i]
		local t1 = timestampData[i + 1]
		if math.abs(t1 - t0) <= pfm.udm.EditorChannelData.TIME_EPSILON then
			table.remove(timestampData, i + 1)
		else
			i = i + 1
		end
	end

	-- Go through each timestamp and calculate actual time and data values
	local insertTimes = {}
	local insertValues = {}
	for i, td in ipairs(timestampData) do
		table.insert(insertTimes, td)
		local v = channel_value_to_editor_value(get_default_value(valueType), valueType)
		for typeComponentIndex, keyframeIndices in pairs(keyframesInTimeframePerKey) do
			local pathKeys = self:GetKey(typeComponentIndex)
			local foundCurveInRange = false
			for _, keyIndex in ipairs(keyframeIndices) do
				local keyIndexNext
				if math.abs(td - pathKeys:GetTime(keyIndex)) <= pfm.udm.EditorChannelData.TIME_EPSILON then
					keyIndexNext = keyIndex
				else
					keyIndexNext = keyIndex + 1
				end
				local tEnd = pathKeys:GetTime(keyIndexNext)
				if tEnd ~= nil then
					if
						td >= pathKeys:GetTime(keyIndex) - pfm.udm.EditorChannelData.TIME_EPSILON
						and td <= pathKeys:GetTime(keyIndexNext) + pfm.udm.EditorChannelData.TIME_EPSILON
					then
						local interpMethod = get_interpolation_mode(pathKeys, keyIndex, valueType)
						local easingMode = pathKeys:GetEasingMode(keyIndex)
						local dpVal = calc_graph_curve_data_point_value(
							interpMethod,
							easingMode,
							pathKeys,
							keyIndex,
							keyIndexNext,
							td
						)
						if math.is_nan(dpVal) or math.is_inf(dpVal) then
							error(
								'Invalid channel value "'
									.. tostring(dpVal)
									.. '" at timestamp '
									.. tostring(td)
									.. " with interpolation method "
									.. interpMethod
									.. " and easing mode "
									.. easingMode
									.. "!"
							)
						end

						v = set_value_component_value(v, valueType, typeComponentIndex, dpVal)

						foundCurveInRange = true
						break
					end
					--else
					--	foundCurveInRange = false
					--	break
				end
			end
			if foundCurveInRange == false then
				-- No curve found, point has to be out of bounds of the curve, so we'll
				-- use the raw animation value instead
				local vBase = udm.get_numeric_component(
					panimaChannel:GetInterpolatedValue(td, false),
					typeComponentIndex,
					valueType
				)
				v = set_value_component_value(v, valueType, typeComponentIndex, vBase)
			end
		end
		table.insert(insertValues, editor_value_to_channel_value(v, valueType))
	end
	assert(#insertTimes == #insertValues)

	channel:GetPanimaChannel():InsertValues(insertTimes, insertValues) -- This will clear all previous data in this range
	debug.stop_profiling_task()
end
