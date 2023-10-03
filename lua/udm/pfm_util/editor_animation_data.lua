--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("pfm.udm.EditorAnimationData.KeyframeInfo")
function pfm.udm.EditorAnimationData.KeyframeInfo:__init(kfIndex)
	self.m_dirty = false
	self:SetIndex(kfIndex)
end
function pfm.udm.EditorAnimationData.KeyframeInfo:__tostring()
	return "KeyframeInfo[" .. tostring(self:GetIndex()) .. "]"
end
function pfm.udm.EditorAnimationData.KeyframeInfo:SetIndex(idx)
	self.m_keyframeIndex = idx
end
function pfm.udm.EditorAnimationData.KeyframeInfo:GetIndex()
	return self.m_keyframeIndex
end
function pfm.udm.EditorAnimationData.KeyframeInfo:IsDirty()
	return self.m_dirty
end
function pfm.udm.EditorAnimationData.KeyframeInfo:SetDirty(dirty)
	if dirty == nil then
		dirty = true
	end
	self.m_dirty = dirty
end

function pfm.udm.EditorAnimationData:GetAnimationClip()
	return self:GetParent()
end

function pfm.udm.EditorAnimationData:FindChannel(targetPath, addIfNotExists)
	for _, channel in ipairs(self:GetChannels()) do
		if channel:GetTargetPath() == targetPath then
			return channel, false
		end
	end
	if addIfNotExists then
		local channel = self:AddChannel()
		channel:SetTargetPath(targetPath)

		local animationClip = self:GetAnimationClip()
		local track = animationClip:GetAnimationTrack()
		local filmClip = track:GetFilmClip()
		filmClip:CallChangeListeners("OnEditorChannelAdded", track, animationClip, self, targetPath)

		return channel, true
	end
end

pfm.udm.EditorGraphCurveKeyData.HANDLE_IN = 0
pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT = 1
local function get_other_handle(handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	end
	return pfm.udm.EditorGraphCurveKeyData.HANDLE_IN
end
function pfm.udm.EditorGraphCurveKeyData:ResizeDirtyKeyframes()
	local numKeyframes = self:GetKeyframeCount()
	local n = #self.m_keyframeInfos

	if numKeyframes > n then
		for i = n + 1, numKeyframes do
			self.m_keyframeInfos[i] = pfm.udm.EditorAnimationData.KeyframeInfo(i - 1)
		end
	else
		for i = numKeyframes + 1, n do
			self.m_keyframeInfos[i] = nil
		end
	end
end
function pfm.udm.EditorGraphCurveKeyData:UpdateKeyframeIndices(startIndex)
	for i = startIndex, #self.m_keyframeInfos do
		self.m_keyframeInfos[i]:SetIndex(i - 1)
	end
end
function pfm.udm.EditorGraphCurveKeyData:SwapKeyframeIndices(i0, i1)
	local info0 = self:GetKeyframeInfo(i0)
	local info1 = self:GetKeyframeInfo(i1)
	local idx1 = info0:GetIndex()
	local idx0 = info1:GetIndex()
	info0:SetIndex(idx0)
	info1:SetIndex(idx1)
	self.m_keyframeInfos[idx0 + 1] = info0
	self.m_keyframeInfos[idx1 + 1] = info1
end
function pfm.udm.EditorGraphCurveKeyData:GetKeyframeInfo(idx)
	return self.m_keyframeInfos[idx + 1]
end
function pfm.udm.EditorGraphCurveKeyData:GetKeyframeInfos()
	return self.m_keyframeInfos
end
function pfm.udm.EditorGraphCurveKeyData:SetKeyframeDirty(idx)
	self.m_keyframeInfos[idx + 1]:SetDirty()
end
function pfm.udm.EditorGraphCurveKeyData:OnArrayValueChanged(name, idx)
	if name == "times" then
		self.m_keyframeInfos[idx + 1]:SetDirty()
	end
end
function pfm.udm.EditorGraphCurveKeyData:OnArrayValueAdded(name, idx)
	if name == "times" then
		table.insert(self.m_keyframeInfos, idx + 1, pfm.udm.EditorAnimationData.KeyframeInfo())
		self:UpdateKeyframeIndices(idx + 1)
	end
end
function pfm.udm.EditorGraphCurveKeyData:OnArrayValueRangeAdded(name, startIndex, count)
	if name == "times" then
		for i = 1, count do
			table.insert(self.m_keyframeInfos, startIndex + 1, pfm.udm.EditorAnimationData.KeyframeInfo())
		end
		self:UpdateKeyframeIndices(startIndex + 1)
	end
end
function pfm.udm.EditorGraphCurveKeyData:OnArrayValueRangeRemoved(name, startIndex, count)
	if name == "times" then
		for i = 1, count do
			table.remove(self.m_keyframeInfos, startIndex + 1)
		end
		if self.m_keyframeInfos[startIndex + 1] ~= nil then
			self.m_keyframeInfos[startIndex + 1]:SetDirty()
			self:UpdateKeyframeIndices(startIndex + 1)
		end
	end
end
function pfm.udm.EditorGraphCurveKeyData:OnArrayValueRemoved(name, idx)
	if name == "times" then
		table.remove(self.m_keyframeInfos, idx + 1)
		if self.m_keyframeInfos[idx + 1] ~= nil then
			self.m_keyframeInfos[idx + 1]:SetDirty()
			self:UpdateKeyframeIndices(idx + 1)
		end
	end
end
function pfm.udm.EditorGraphCurveKeyData:GetTypeComponentIndex()
	local graphCurve = self:GetGraphCurve()
	for i, keyData in ipairs(graphCurve:GetKeys()) do
		if util.is_same_object(keyData, self) then
			return i - 1
		end
	end
	assert(false)
end
function pfm.udm.EditorGraphCurveKeyData:GetGraphCurve()
	return self:GetParent()
end
function pfm.udm.EditorGraphCurveKeyData:RebuildDirtyGraphCurveSegments(baseIndex)
	local dirtyKeyframes = self:GetDirtyKeyframes()

	local keyframeIndices = {}
	for i, kf in ipairs(dirtyKeyframes) do
		if kf:IsDirty() then
			local keyframeIdx = kf:GetIndex()
			-- Is keyframeIdx different from i ???
			if i > 1 and (dirtyKeyframes[i - 1]:IsDirty() == false) then
				-- We need to update both the previous and the next curve segment around each keyframe.
				-- RebuildGraphCurveSegment rebuilds the segment *after* the keyframe, so we need to add the previous keyframes to the list as well.
				table.insert(keyframeIndices, keyframeIdx - 1)
			end
			table.insert(keyframeIndices, keyframeIdx)
		end
	end
	self:ClearDirtyKeyframes()

	local graphCurve = self:GetGraphCurve()
	local editorChannelData = graphCurve:GetEditorChannelData()
	for _, keyframeIdx in ipairs(keyframeIndices) do
		print("Rebuilding curve for keyframe " .. keyframeIdx .. "...")
		editorChannelData:RebuildGraphCurveSegment(keyframeIdx, baseIndex)
	end
end
function pfm.udm.EditorGraphCurveKeyData:GetKeyframeCount()
	return self:GetTimeCount()
end
function pfm.udm.EditorGraphCurveKeyData:HasDirtyKeyframes()
	return #self.m_keyframeInfos > 0
end
function pfm.udm.EditorGraphCurveKeyData:GetDirtyKeyframes()
	return self.m_keyframeInfos
end
function pfm.udm.EditorGraphCurveKeyData:ClearDirtyKeyframes()
	for _, kf in ipairs(self.m_keyframeInfos) do
		kf:SetDirty(false)
	end
end
function pfm.udm.EditorGraphCurveKeyData:OnInitialize()
	self.m_keyframeInfos = {}
	self:ResizeDirtyKeyframes()
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleDelta(keyIndex, handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:GetInDelta(keyIndex)
	end
	return self:GetOutDelta(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleDelta(keyIndex, handle, delta)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:SetInDelta(keyIndex, delta)
	end
	return self:SetOutDelta(keyIndex, delta)
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleTimeOffset(keyIndex, handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:GetInTime(keyIndex)
	end
	return self:GetOutTime(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleTimeOffset(keyIndex, handle, offset)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:SetInTime(keyIndex, offset)
	end
	return self:SetOutTime(keyIndex, offset)
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleType(keyIndex, handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:GetInHandleType(keyIndex)
	end
	return self:GetOutHandleType(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleType(keyIndex, handle, type)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		self:SetInHandleType(keyIndex, type)
	else
		self:SetOutHandleType(keyIndex, type)
	end
	if type == pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR then
		self:UpdateVectorHandle(keyIndex, handle)
	elseif type == pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED then
		self:UpdateAlignedHandle(keyIndex, handle)
	end
end
function pfm.udm.EditorGraphCurveKeyData:UpdateKeyframeDependencies(
	keyIndex,
	updateIn,
	updateOut,
	affectedKeyframeHandles
)
	if updateIn == nil then
		updateIn = true
	end
	if updateOut == nil then
		updateOut = true
	end
	if updateIn then
		local neighborKeyIndex = keyIndex - 1
		if
			self:GetHandleType(neighborKeyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
			== pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR
		then
			self:UpdateVectorHandle(neighborKeyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
			if affectedKeyframeHandles ~= nil then
				table.insert(
					affectedKeyframeHandles,
					1,
					{ neighborKeyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT }
				)
			end
		end
	end
	if updateOut then
		local neighborKeyIndex = keyIndex + 1
		if
			self:GetHandleType(neighborKeyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
			== pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR
		then
			self:UpdateVectorHandle(neighborKeyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
			if affectedKeyframeHandles ~= nil then
				table.insert(
					affectedKeyframeHandles,
					1,
					{ neighborKeyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN }
				)
			end
		end
	end
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleData(keyIndex, handle, time, delta)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		time = math.min(time, -0.0001)
	else
		time = math.max(time, 0.0001)
	end

	local affectedKeyframeHandles = { { keyIndex, handle } }
	self:SetHandleTimeOffset(keyIndex, handle, time)
	self:SetHandleDelta(keyIndex, handle, delta)

	local handleType = self:GetHandleType(keyIndex, handle)
	if handleType == pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED then
		self:UpdateAlignedHandle(keyIndex, handle)
		table.insert(affectedKeyframeHandles, { keyIndex, get_other_handle(handle) })
	end

	self:UpdateKeyframeDependencies(
		keyIndex,
		handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN,
		handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT,
		affectedKeyframeHandles
	)

	local graphCurve = self:GetGraphCurve()
	local filmClip = graphCurve:GetFilmClip()
	filmClip:CallChangeListeners("OnKeyframeHandleDataChanged", self, keyIndex, handle, time, delta)

	return affectedKeyframeHandles
end
function pfm.udm.EditorGraphCurveKeyData:UpdateVectorHandle(keyIndex, handle)
	local otherOffset = (handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN) and -1 or 1
	local otherIndex = keyIndex + otherOffset
	if otherIndex < 0 or otherIndex >= self:GetTimeCount() then
		return false
	end

	local pos = Vector2(self:GetTime(keyIndex), self:GetValue(keyIndex))
	local posTgt = Vector2(
		self:GetTime(otherIndex) + self:GetHandleTimeOffset(otherIndex, get_other_handle(handle)),
		self:GetValue(otherIndex) + self:GetHandleDelta(otherIndex, get_other_handle(handle))
	)
	local dir = (posTgt - pos):GetNormal()
	local dist = pos:Distance(posTgt)
	if dist > 0.001 then
		dir = dir * (dist * (1.0 / 3.0))
	end
	self:SetHandleTimeOffset(keyIndex, handle, dir.x)
	self:SetHandleDelta(keyIndex, handle, dir.y)
end
function pfm.udm.EditorGraphCurveKeyData:UpdateAlignedHandle(keyIndex, handle)
	local time = self:GetHandleTimeOffset(keyIndex, handle)
	local delta = self:GetHandleDelta(keyIndex, handle)
	local otherHandle = get_other_handle(handle)
	-- TODO: Re-calculate length?
	self:SetHandleTimeOffset(keyIndex, otherHandle, -time)
	self:SetHandleDelta(keyIndex, otherHandle, -delta)
end
