--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("set_keyframe_property.lua")

local Command = util.register_class("pfm.CommandSetKeyframeTime", pfm.CommandSetKeyframeProperty)
function Command:Initialize(actorUuid, propertyPath, timestamp, oldTime, newTime, baseIndex)
	local res = pfm.CommandSetKeyframeProperty.Initialize(self, actorUuid, propertyPath, timestamp, baseIndex)

	if res ~= pfm.Command.RESULT_SUCCESS then
		return res
	end

	-- Test
	local actor = pfm.dereference(actorUuid)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return
	end

	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	local numKeyframes = keyData:GetKeyframeCount()
	local data = self:GetData()
	if numKeyframes > 0 and channel:GetValueCount() > 0 then
		local firstKeyframeIndex = 0
		local firstAnimDataTime = channel:GetTime(0)
		local firstKeyframeTime = keyData:GetTime(firstKeyframeIndex)
		local firstKeyframeValue = keyData:GetValue(firstKeyframeIndex)

		local animDataBufferPre = pfm.util.AnimationDataBuffer(data:Add("preAnimationData"))
		local res, startIdx =
			animDataBufferPre:StoreAnimationData(animManager, actor, propertyPath, firstAnimDataTime, firstKeyframeTime)
		if res then
			animDataBufferPre:GetData():SetValue("timeOffset", udm.TYPE_FLOAT, -firstKeyframeTime)
			animDataBufferPre:GetData():SetValue("dataOffset", udm.TYPE_FLOAT, -firstKeyframeValue)
		end

		local lastKeyframeIndex = numKeyframes - 1
		local lastAnimDataTime = channel:GetTime(channel:GetValueCount() - 1)
		local lastKeyframeTime = keyData:GetTime(lastKeyframeIndex)
		local lastKeyframeValue = keyData:GetValue(lastKeyframeIndex)

		local animDataBufferPost = pfm.util.AnimationDataBuffer(data:Add("postAnimationData"))
		local res, startIdx =
			animDataBufferPost:StoreAnimationData(animManager, actor, propertyPath, lastKeyframeTime, lastAnimDataTime)
		if res then
			animDataBufferPost:GetData():SetValue("timeOffset", udm.TYPE_FLOAT, -lastKeyframeTime)
			animDataBufferPost:GetData():SetValue("dataOffset", udm.TYPE_FLOAT, -lastKeyframeValue)
		end
	end

	data:SetValue("oldTime", udm.TYPE_FLOAT, oldTime)
	data:SetValue("newTime", udm.TYPE_FLOAT, newTime)
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetLocalTime(channelClip, action)
	local keyName
	if action == pfm.Command.ACTION_DO then
		keyName = "oldTime"
	elseif action == pfm.Command.ACTION_UNDO then
		keyName = "newTime"
	end

	local data = self:GetData()
	local time = data:GetValue(keyName, udm.TYPE_FLOAT)
	return channelClip:LocalizeOffsetAbs(time)
end
function Command:ApplyProperty(data, action, editorChannel, keyIdx, timestamp, valueBaseIndex)
	local keyName
	if action == pfm.Command.ACTION_DO then
		keyName = "newTime"
	elseif action == pfm.Command.ACTION_UNDO then
		keyName = "oldTime"
	end

	local time = data:GetValue(keyName, udm.TYPE_FLOAT)
	local res = editorChannel:SetKeyTime(keyIdx, time, valueBaseIndex)
	if res == false then
		self:LogFailure("Failed to apply keyframe time!")
		return
	end

	-- TEST
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local udmPreAnimationData = data:Get("preAnimationData")
	--[[if udmPreAnimationData ~= nil then
		local animManager = self:GetAnimationManager()
		local animDataBufferPre = pfm.util.AnimationDataBuffer(udmPreAnimationData)
		local endOffset = nil --0.0 --editorChannel:GetGraphCurve():GetKey(valueBaseIndex):GetTime(0)+ udmPreAnimationData:GetValue("endOffset", udm.TYPE_FLOAT)

		-- Offset = -endOffset +newOffset
		print("udmPreAnimationData:")
		print(udmPreAnimationData:ToAscii())
		--local x = animDataBufferPre:RestoreAnimationData(animManager, actor, propertyPath, endOffset)
	end]]

	local udmPreAnimationData = data:Get("preAnimationData")
	if udmPreAnimationData ~= nil then
		local animManager = self:GetAnimationManager()
		local animDataBufferPre = pfm.util.AnimationDataBuffer(udmPreAnimationData)
		local keyData = editorChannel:GetGraphCurve():GetKey(valueBaseIndex)
		local kfTime = keyData:GetTime(0)
		local kfValue = keyData:GetValue(0)
		local timeOffset = kfTime + udmPreAnimationData:GetValue("timeOffset", udm.TYPE_FLOAT)
		local dataOffset = kfValue + udmPreAnimationData:GetValue("dataOffset", udm.TYPE_FLOAT)
		local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
		channel:ClearRange(-math.huge, kfTime, false)
		local x = animDataBufferPre:RestoreAnimationData(animManager, actor, propertyPath, timeOffset, dataOffset)
	end

	local udmPostAnimationData = data:Get("postAnimationData")
	if udmPostAnimationData ~= nil then
		local animManager = self:GetAnimationManager()
		local animDataBufferPost = pfm.util.AnimationDataBuffer(udmPostAnimationData)
		local keyData = editorChannel:GetGraphCurve():GetKey(valueBaseIndex)
		local kfTime = keyData:GetTime(keyData:GetKeyframeCount() - 1)
		local kfValue = keyData:GetValue(keyData:GetKeyframeCount() - 1)
		local timeOffset = kfTime + udmPostAnimationData:GetValue("timeOffset", udm.TYPE_FLOAT)
		local dataOffset = kfValue + udmPostAnimationData:GetValue("dataOffset", udm.TYPE_FLOAT)
		local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
		channel:ClearRange(kfTime, math.huge, false)
		local x = animDataBufferPost:RestoreAnimationData(animManager, actor, propertyPath, timeOffset, dataOffset)
	end

	--[[
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	local numKeyframes = keyData:GetKeyframeCount()
	local data = self:GetData()
	if numKeyframes > 0 and channel:GetValueCount() > 0 then
		local firstKeyframeIndex = 0
		local firstAnimDataTime = channel:GetTime(0)

		local animDataBufferPre = pfm.util.AnimationDataBuffer(data:Add("preAnimationData"))
		animDataBufferPre:StoreAnimationData(
			animManager,
			actor,
			propertyPath,
			firstAnimDataTime,
			keyData:GetTime(firstKeyframeIndex)
		)
		animDataBufferPre:GetData():SetValue("endOffset", udm.TYPE_FLOAT, firstAnimDataTime)

		local lastKeyframeIndex = numKeyframes - 1
		local lastAnimDataTime = channel:GetTime(channel:GetValueCount() - 1)

		local animDataBufferPost = pfm.util.AnimationDataBuffer(data:Add("postAnimationData"))
		animDataBufferPost:StoreAnimationData(
			animManager,
			actor,
			propertyPath,
			keyData:GetTime(lastKeyframeIndex),
			lastAnimDataTime
		)
		animDataBufferPost:GetData():SetValue("startOffset", udm.TYPE_FLOAT, lastAnimDataTime)
	end
]]
	--

	self:RebuildDirtyGraphCurveSegments()
end
pfm.register_command("set_keyframe_time", Command)
