--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function gui.PFMTimelineGraphBase:OnEditorChannelAdded(actor, channel, targetPath)
	self:ReloadGraphCurve(targetPath)
end
function gui.PFMTimelineGraphBase:OnEditorChannelKeyframeRemoved(actor, targetPath, valueBaseIndex)
	local curve = self:FindGraphCurve(actor, targetPath, valueBaseIndex)
	if util.is_valid(curve) == false then
		return
	end
	curve:UpdateKeyframes()
end
function gui.PFMTimelineGraphBase:OnEditorChannelKeyframeAdded(actor, targetPath, valueBaseIndex)
	local curve = self:FindGraphCurve(actor, targetPath, valueBaseIndex)
	if util.is_valid(curve) == false then
		return
	end
	curve:UpdateKeyframes()
end
function gui.PFMTimelineGraphBase:OnAnimationChannelChanged(filmClip, channel, animClip)
	self:ReloadGraphCurve(channel:GetTargetPath())
end
function gui.PFMTimelineGraphBase:OnKeyframeHandleDataChanged(filmClip, keyData, keyIndex, handle, time, delta)
	local valueBaseIndex = keyData:GetTypeComponentIndex()
	local graphCurve = keyData:GetGraphCurve()
	local editorChannelData = graphCurve:GetEditorChannelData()
	local animClip = editorChannelData:GetAnimationClip()
	local curve = self:FindGraphCurve(animClip:GetActor(), editorChannelData:GetTargetPath(), valueBaseIndex)
	if util.is_valid(curve) == false then
		return
	end
	local dp = curve:FindDataPointByKeyframeInfo(keyData:GetKeyframeInfo(keyIndex))
	if util.is_valid(dp) then
		dp:UpdateHandles()
	end
end
function gui.PFMTimelineGraphBase:OnGraphCurveAnimationDataChanged(
	filmClip,
	graphCurve,
	animClip,
	channel,
	valueBaseIndex
)
	self:ReloadGraphCurve(channel:GetTargetPath())
end
function gui.PFMTimelineGraphBase:OnEditorChannelKeyframeTimeChanged(
	animationClip,
	editorChannel,
	editorKeyData,
	editorKeyIndex,
	valueBaseIndex,
	oldTime,
	newTime
)
	local actor = animationClip:GetActor()
	local path = editorChannel:GetTargetPath()

	local curve = self:FindGraphCurve(actor, path, valueBaseIndex)
	if util.is_valid(curve) == false then
		return
	end
	local dp = curve:FindDataPointByKeyframeInfo(editorKeyData:GetKeyframeInfo(editorKeyIndex))
	if util.is_valid(dp) then
		curve:UpdateDataPoint(dp)
	end
end
function gui.PFMTimelineGraphBase:OnEditorChannelKeyframeValueChanged(
	animationClip,
	editorChannel,
	editorKeyData,
	editorKeyIndex,
	valueBaseIndex,
	oldValue,
	newValue
)
	local actor = animationClip:GetActor()
	local panimaAnim = animationClip:GetPanimaAnimation()
	local path = editorChannel:GetTargetPath()
	local panimaChannel = panimaAnim:FindChannel(path)
	local udmType = panimaChannel:GetValueType()
	local udmChannel = animationClip:GetChannel(path, udmType)
	local idx = panimaChannel:FindIndex(editorKeyData:GetTime(editorKeyIndex))
	local typeComponentIndex = valueBaseIndex

	local curve = self:FindGraphCurve(actor, path, valueBaseIndex)
	if util.is_valid(curve) == false then
		return
	end
	local dp = curve:FindDataPointByKeyframeInfo(editorKeyData:GetKeyframeInfo(editorKeyIndex))
	if util.is_valid(dp) then
		curve:UpdateDataPoint(dp)
	end

	self:UpdateChannelValue({
		actor = actor,
		animation = panimaAnim,
		channel = panimaChannel,
		udmChannel = udmChannel,
		index = idx,
		oldIndex = idx,
		keyIndex = editorKeyIndex,
		typeComponentIndex = typeComponentIndex,
	}, editorChannel)
end
function gui.PFMTimelineGraphBase:ClearKeyframeListeners()
	util.remove(self.m_filmClipCallbacks)
end
function gui.PFMTimelineGraphBase:InitializeKeyframeListeners(filmClip)
	self.m_filmClipCallbacks = {}
	local function add_change_listener(identifier, fc)
		table.insert(self.m_filmClipCallbacks, filmClip:AddChangeListener(identifier, fc))
	end
	add_change_listener("OnEditorChannelAdded", function(filmClip, track, animationClip, channel, targetPath)
		self:OnEditorChannelAdded(animationClip:GetActor(), channel, targetPath)
	end)
	add_change_listener(
		"OnEditorChannelKeyframeAdded",
		function(filmClip, track, animationClip, editorChannel, keyData, keyframeIndex, valueBaseIndex)
			self:OnEditorChannelKeyframeAdded(animationClip:GetActor(), editorChannel:GetTargetPath(), valueBaseIndex)
		end
	)
	add_change_listener(
		"OnEditorChannelKeyframeRemoved",
		function(filmClip, track, animationClip, editorChannel, keyData, keyframeIndex, valueBaseIndex)
			self:OnEditorChannelKeyframeRemoved(animationClip:GetActor(), editorChannel:GetTargetPath(), valueBaseIndex)
		end
	)
	add_change_listener(
		"OnEditorChannelKeyframeValueChanged",
		function(filmClip, track, animationClip, editorChannel, keyData, keyIndex, valueBaseIndex, oldValue, newValue)
			self:OnEditorChannelKeyframeValueChanged(
				animationClip,
				editorChannel,
				keyData,
				keyIndex,
				valueBaseIndex,
				oldValue,
				newValue
			)
		end
	)
	add_change_listener(
		"OnEditorChannelKeyframeTimeChanged",
		function(filmClip, track, animationClip, editorChannel, keyData, keyIndex, valueBaseIndex, oldTime, newTime)
			self:OnEditorChannelKeyframeTimeChanged(
				animationClip,
				editorChannel,
				keyData,
				keyIndex,
				valueBaseIndex,
				oldTime,
				newTime
			)
		end
	)
	add_change_listener(
		"OnGraphCurveAnimationDataChanged",
		function(filmClip, graphCurve, animClip, channel, valueBaseIndex)
			self:OnGraphCurveAnimationDataChanged(filmClip, graphCurve, animClip, channel, valueBaseIndex)
		end
	)
	add_change_listener("OnAnimationChannelChanged", function(filmClip, channel, animClip)
		self:OnAnimationChannelChanged(filmClip, channel, animClip)
	end)
	add_change_listener(
		"OnKeyframeHandleDataChanged",
		function(filmClip, animClip, keyData, keyIndex, handle, time, delta)
			self:OnKeyframeHandleDataChanged(filmClip, animClip, keyData, keyIndex, handle, time, delta)
		end
	)
end
