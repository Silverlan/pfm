--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("animation_clip_graph_curve.lua")

function pfm.udm.AnimationClip:OnInitialize() end

function pfm.udm.AnimationClip:GetAnimationTrack()
	return self:GetParent()
end

function pfm.udm.AnimationClip:GetFilmClip()
	return self:GetAnimationTrack():GetFilmClip()
end

function pfm.udm.AnimationClip:FindChannel(path)
	for _, channel in ipairs(self:GetAnimation():GetChannels()) do
		if channel:GetTargetPath() == path then
			return channel
		end
	end
end

function pfm.udm.AnimationClip:GetChannel(path, type, addIfNotExists)
	local channel = self:FindChannel(path)
	if channel ~= nil then
		return channel, false
	end
	if addIfNotExists ~= true then
		return
	end
	channel = self:AddChannel(type)
	channel:SetTargetPath(path)
	return channel, true
end

function pfm.udm.AnimationClip:RemoveChannel(path)
	local channel = self:FindChannel(path)
	if channel == nil then
		return
	end
	self:GetAnimation():RemoveChannel(channel)
end

function pfm.udm.AnimationClip:AddChannel(type)
	local anim = self:GetAnimation()
	local channel = anim:AddChannel()
	channel:SetValuesValueType(type)
	self.m_panimaAnim = nil
	return channel
end

function pfm.udm.AnimationClip:SetPanimaAnimationDirty()
	self.m_panimaAnim = nil
end

function pfm.udm.AnimationClip:UpdateAnimationChannel(channel)
	local track = self:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners("OnAnimationChannelChanged", channel, self)
end

function pfm.udm.AnimationClip:GetPanimaAnimation()
	if self.m_panimaAnim == nil then
		self.m_panimaAnim = panima.Animation.load(self:GetAnimation():GetUdmData())
		self.m_panimaAnim:UpdateDuration()
	end
	return self.m_panimaAnim
end

function pfm.udm.AnimationClip:LocalizeOffset(offset)
	return self:GetTimeFrame():LocalizeOffset(offset)
end
function pfm.udm.AnimationClip:LocalizeTimeOffset(offset)
	return self:GetTimeFrame():LocalizeTimeOffset(offset)
end
function pfm.udm.AnimationClip:GlobalizeOffset(offset)
	return self:GetTimeFrame():GlobalizeOffset(offset)
end
function pfm.udm.AnimationClip:GlobalizeTimeOffset(offset)
	return self:GetTimeFrame():GlobalizeTimeOffset(offset)
end
function pfm.udm.AnimationClip:LocalizeOffsetAbs(offset)
	return self:GetTimeFrame():LocalizeOffsetAbs(offset)
end
function pfm.udm.AnimationClip:GlobalizeOffsetAbs(offset)
	return self:GetTimeFrame():GlobalizeOffsetAbs(offset)
end

function pfm.udm.AnimationClip:ToDataTime(offset)
	return self:LocalizeOffsetAbs(offset)
end
function pfm.udm.AnimationClip:ToClipTime(offset)
	return self:GlobalizeOffsetAbs(offset)
end

-- See http://lua-users.org/files/wiki_insecure/users/chill/table.binsearch-0.3.lua
local default_fcompval = function(value)
	return value
end
local fcompf = function(a, b)
	return a < b
end
local fcompr = function(a, b)
	return a > b
end
local feq = function(a, b)
	return a == b
end
local function binsearch(o, fget, len, value, fcompval, feqval, reversed)
	-- Initialise functions
	local fcompval = fcompval or default_fcompval
	local fcomp = reversed and fcompr or fcompf
	local feqval = feqval or feq
	--  Initialise numbers
	local iStart, iEnd, iMid = 1, len, 0
	-- Binary Search
	while iStart <= iEnd do
		-- calculate middle
		iMid = math.floor((iStart + iEnd) / 2)
		-- get compare value
		local value2 = fcompval(fget(o, iMid - 1))
		-- get all values that match
		if feqval(value, iMid - 1) then
			return iMid - 1
		-- keep searching
		elseif fcomp(value, value2) then
			iEnd = iMid - 1
		else
			iStart = iMid + 1
		end
	end
end
local function findInsertIndex(o, fget, len, value, epsilon)
	epsilon = epsilon or 0.0001
	if len == 1 then
		if value >= fget(o, 0) - epsilon then
			return 1
		end
		return 0
	end
	local i = binsearch(o, fget, len, value, nil, function(v0, v1Idx)
		local a = fget(o, v1Idx)
		local b = fget(o, v1Idx + 1)
		if b == nil then
			return false
		end
		return v0 >= a - epsilon and v0 < b + epsilon
	end)
	if i ~= nil then
		i = i + 1
	elseif len > 0 and value < fget(o, 0) + epsilon then
		i = 0
	else
		i = len
	end
	return i
end
local function findTimeIndex(o, fget, len, value)
	if len == 0 then
		return
	end
	if len == 1 then
		if math.abs(value - fget(o, 0)) > pfm.udm.EditorChannelData.TIME_EPSILON then
			return
		end
		return 0
	end
	local i = binsearch(o, fget, len, value, nil, function(v0, v1Idx)
		local a = fget(o, v1Idx)
		local b = fget(o, v1Idx + 1)
		if b == nil then
			return false
		end
		return v0 >= a and v0 < b
	end)
	if i ~= nil then
		if math.abs(value - fget(o, i)) < pfm.udm.EditorChannelData.TIME_EPSILON then
			return i
		end
		local vnext = fget(o, i + 1)
		if vnext == nil then
			return
		end
		if math.abs(value - vnext) < pfm.udm.EditorChannelData.TIME_EPSILON then
			return i + 1
		end
		return
	end
	if math.abs(value - fget(o, 0)) < pfm.udm.EditorChannelData.TIME_EPSILON then
		return 0
	end
	if math.abs(value - fget(o, len - 1)) < pfm.udm.EditorChannelData.TIME_EPSILON then
		return len - 1
	end
end

-- TODO: The editor should ensure that the delta value between keys / bookmarks is always larger than 0.0005 to avoid collisions
pfm.udm.EditorChannelData.TIME_EPSILON = panima.TIME_EPSILON
function pfm.udm.EditorChannelData:FindKeyIndexByTime(t, baseIndex)
	baseIndex = baseIndex or 0

	local graphCurve = self:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if keyData == nil then
		return
	end
	return findTimeIndex(keyData, keyData.GetTime, keyData:GetTimeCount(), t)
end
function pfm.udm.EditorChannelData:FindUpperKeyIndex(t, baseIndex)
	local graphCurve = self:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if keyData == nil then
		return
	end

	local idx = self:FindLowerKeyIndex(t, baseIndex)
	if idx ~= nil then
		idx = idx + 1
	else
		idx = 0
	end
	if idx >= keyData:GetTimeCount() then
		return
	end
	return idx
end
function pfm.udm.EditorChannelData:FindLowerKeyIndex(t, baseIndex)
	baseIndex = baseIndex or 0

	local graphCurve = self:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if keyData == nil then
		return
	end
	local idx =
		findInsertIndex(keyData, keyData.GetTime, keyData:GetTimeCount(), t, pfm.udm.EditorChannelData.TIME_EPSILON)
	if idx ~= nil then
		if idx == 0 then
			return nil
		end
		idx = idx - 1
	end
	return idx
end
function pfm.udm.EditorChannelData:SetKeyframeValue(keyIndex, value, valueBaseIndex)
	local graphCurve = self:GetGraphCurve()
	local keyData = graphCurve:GetKey(valueBaseIndex)
	if keyData == nil then
		return false
	end
	local oldValue = keyData:GetValue(keyIndex)
	keyData:SetValue(keyIndex, value)

	local animationClip = self:GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners(
		"OnEditorChannelKeyframeValueChanged",
		track,
		animationClip,
		self,
		keyData,
		keyIndex,
		valueBaseIndex,
		oldValue,
		value
	)
	return true
end

local function swap_property(keyData, i0, i1, get, set)
	local tmp = get(keyData, i0)
	set(keyData, i0, get(keyData, i1))
	set(keyData, i1, tmp)
end
local function swap(keyData, i0, i1)
	-- Also update 'AddKey' and 'RemoveKey' functions below when adding new key properties
	swap_property(keyData, i0, i1, keyData.GetTime, keyData.SetTime)
	swap_property(keyData, i0, i1, keyData.GetValue, keyData.SetValue)
	swap_property(keyData, i0, i1, keyData.GetEasingMode, keyData.SetEasingMode)
	swap_property(keyData, i0, i1, keyData.GetInterpolationMode, keyData.SetInterpolationMode)

	swap_property(keyData, i0, i1, keyData.GetInTime, keyData.SetInTime)
	swap_property(keyData, i0, i1, keyData.GetInDelta, keyData.SetInDelta)
	swap_property(keyData, i0, i1, keyData.GetInHandleType, keyData.SetInHandleType)

	swap_property(keyData, i0, i1, keyData.GetOutTime, keyData.SetOutTime)
	swap_property(keyData, i0, i1, keyData.GetOutDelta, keyData.SetOutDelta)
	swap_property(keyData, i0, i1, keyData.GetOutHandleType, keyData.SetOutHandleType)

	keyData:SwapKeyframeIndices(i0, i1)
end
function pfm.udm.EditorChannelData:SetKeyTime(keyIndex, newTime, baseIndex)
	baseIndex = baseIndex or 0

	local graphCurve = self:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)

	local bms = self:GetBookmarkSet()
	local bm = bms:FindBookmark(keyData:GetTime(keyIndex))
	if bm ~= nil then
		bm:SetTime(newTime)
	end

	local numTimes = keyData:GetTimeCount()
	local iTarget = findInsertIndex(keyData, keyData.GetTime, numTimes, newTime) - 1
	if
		iTarget == keyIndex
		or (keyIndex == 0 and iTarget < 0)
		or (keyIndex == numTimes - 1 and iTarget > (numTimes - 1))
	then
		-- Changing the time will not change the value order in the array, so we can just apply it directly
		local oldTime = keyData:GetTime(keyIndex)
		keyData:SetTime(keyIndex, newTime)

		local animationClip = self:GetAnimationClip()
		local track = animationClip:GetAnimationTrack()
		local filmClip = track:GetFilmClip()
		filmClip:CallChangeListeners(
			"OnEditorChannelKeyframeTimeChanged",
			track,
			animationClip,
			self,
			keyData,
			keyIndex,
			baseIndex,
			oldTime,
			newTime
		)
		return
	end

	-- Key will have to be shuffled around
	if iTarget < keyIndex then
		iTarget = iTarget + 1
		for j = keyIndex, iTarget + 1, -1 do
			swap(keyData, j, j - 1)
		end
	else
		for j = keyIndex, iTarget - 1 do
			swap(keyData, j, j + 1)
		end
	end
	local oldTime = keyData:GetTime(iTarget)
	keyData:SetTime(iTarget, newTime)

	local animationClip = self:GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners(
		"OnEditorChannelKeyframeTimeChanged",
		track,
		animationClip,
		self,
		keyData,
		iTarget,
		baseIndex,
		oldTime,
		newTime
	)

	return (iTarget ~= keyIndex) and iTarget or nil
end

function pfm.udm.EditorChannelData:GetEditorAnimationData()
	return self:GetParent()
end
function pfm.udm.EditorChannelData:GetAnimationClip()
	return self:GetEditorAnimationData():GetParent()
end

function pfm.udm.EditorChannelData:GetFilmClip()
	return self:GetAnimationClip():GetFilmClip()
end

function pfm.udm.EditorChannelData:AddKey(t, baseIndex)
	baseIndex = baseIndex or 0
	local graphCurve = self:GetGraphCurve()
	graphCurve:InitializeKeys(baseIndex)
	local keyData = graphCurve:GetKey(baseIndex)

	local i = self:FindKeyIndexByTime(t, baseIndex)
	if i ~= nil then
		return keyData, i
	end -- Only one key must exist for a specific timestamp

	local num = keyData:GetTimeCount()
	i = findInsertIndex(keyData, keyData.GetTime, num, t)

	-- Also update 'swap' function above and 'RemoveKey' function below when adding new key properties
	keyData:InsertTimeRange(i, 1)
	keyData:SetTime(i, t)
	keyData:InsertValueRange(i, 1)
	keyData:SetValue(i, 0.0)
	keyData:InsertEasingModeRange(i, 1)
	keyData:SetEasingMode(i, pfm.udm.EASING_MODE_AUTO)
	keyData:InsertInterpolationModeRange(i, 1)
	keyData:SetInterpolationMode(i, pfm.udm.INTERPOLATION_BEZIER)

	keyData:InsertInTimeRange(i, 1)
	keyData:SetInTime(i, 0.0)
	keyData:InsertInDeltaRange(i, 1)
	keyData:SetInDelta(i, 0.0)
	keyData:InsertInHandleTypeRange(i, 1)
	keyData:SetInHandleType(i, pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED)

	keyData:InsertOutTimeRange(i, 1)
	keyData:SetOutTime(i, 0.0)
	keyData:InsertOutDeltaRange(i, 1)
	keyData:SetOutDelta(i, 0.0)
	keyData:InsertOutHandleTypeRange(i, 1)
	keyData:SetOutHandleType(i, pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED)

	self:GetBookmarkSet():AddBookmarkAtTimestamp(t)

	local animationClip = self:GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners("OnEditorChannelKeyframeAdded", track, animationClip, self, keyData, i, baseIndex)
	return keyData, i
end

function pfm.udm.EditorChannelData:RemoveKey(t, baseIndex)
	baseIndex = baseIndex or 0

	self:GetBookmarkSet():RemoveBookmarkAtTimestamp(t)

	local i = self:FindKeyIndexByTime(t, baseIndex)
	if i == nil then
		return
	end
	local graphCurve = self:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	keyData:RemoveTimeRange(i, 1)
	keyData:RemoveValueRange(i, 1)
	keyData:RemoveEasingModeRange(i, 1)
	keyData:RemoveInterpolationModeRange(i, 1)

	keyData:RemoveInTimeRange(i, 1)
	keyData:RemoveInDeltaRange(i, 1)
	keyData:RemoveInHandleTypeRange(i, 1)

	keyData:RemoveOutTimeRange(i, 1)
	keyData:RemoveOutDeltaRange(i, 1)
	keyData:RemoveOutHandleTypeRange(i, 1)

	local animationClip = self:GetAnimationClip()
	local track = animationClip:GetAnimationTrack()
	local filmClip = track:GetFilmClip()
	filmClip:CallChangeListeners("OnEditorChannelKeyframeRemoved", track, animationClip, self, keyData, i, baseIndex)
	return i
end
