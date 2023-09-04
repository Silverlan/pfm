--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandStoreAnimationData", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, valueBaseIndex)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return
	end

	local data = self:GetData()
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(valueBaseIndex)
	local numKeyframes = keyData:GetKeyframeCount()
	if numKeyframes > 0 and channel:GetValueCount() > 0 then
		local firstKeyframeIndex = 0
		local firstAnimDataTime = channel:GetTime(0)
		local firstKeyframeTime = keyData:GetTime(firstKeyframeIndex) - panima.TIME_EPSILON
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
		local lastKeyframeTime = keyData:GetTime(lastKeyframeIndex) + panima.TIME_EPSILON
		local lastKeyframeValue = keyData:GetValue(lastKeyframeIndex)

		local animDataBufferPost = pfm.util.AnimationDataBuffer(data:Add("postAnimationData"))
		local res, startIdx =
			animDataBufferPost:StoreAnimationData(animManager, actor, propertyPath, lastKeyframeTime, lastAnimDataTime)
		if res then
			animDataBufferPost:GetData():SetValue("timeOffset", udm.TYPE_FLOAT, -lastKeyframeTime)
			animDataBufferPost:GetData():SetValue("dataOffset", udm.TYPE_FLOAT, -lastKeyframeValue)
		end
	end

	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, valueBaseIndex)

	return pfm.Command.RESULT_SUCCESS
end
function Command:RestoreAnimationData()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)

	local udmPreAnimationData = data:Get("preAnimationData")
	local count = 0
	if udmPreAnimationData ~= nil then
		local animManager = self:GetAnimationManager()
		local animDataBufferPre = pfm.util.AnimationDataBuffer(udmPreAnimationData)
		local keyData = editorChannel:GetGraphCurve():GetKey(valueBaseIndex)
		local kfTime = keyData:GetTime(0) - panima.TIME_EPSILON
		local kfValue = keyData:GetValue(0)
		local timeOffset = kfTime + udmPreAnimationData:GetValue("timeOffset", udm.TYPE_FLOAT)
		local dataOffset = kfValue + udmPreAnimationData:GetValue("dataOffset", udm.TYPE_FLOAT)
		local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
		channel:ClearRange(-math.huge, kfTime, false)
		local x = animDataBufferPre:RestoreAnimationData(animManager, actor, propertyPath, timeOffset, dataOffset)
		-- TODO: Verify that keyframe value has not been overwritten (should be excluded because of panima.TIME_EPSILON)
		count = count + 1
	end

	local udmPostAnimationData = data:Get("postAnimationData")
	if udmPostAnimationData ~= nil then
		local animManager = self:GetAnimationManager()
		local animDataBufferPost = pfm.util.AnimationDataBuffer(udmPostAnimationData)
		local keyData = editorChannel:GetGraphCurve():GetKey(valueBaseIndex)
		local kfTime = keyData:GetTime(keyData:GetKeyframeCount() - 1) + panima.TIME_EPSILON
		local kfValue = keyData:GetValue(keyData:GetKeyframeCount() - 1)
		local timeOffset = kfTime + udmPostAnimationData:GetValue("timeOffset", udm.TYPE_FLOAT)
		local dataOffset = kfValue + udmPostAnimationData:GetValue("dataOffset", udm.TYPE_FLOAT)
		local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
		channel:ClearRange(kfTime, math.huge, false)
		local x = animDataBufferPost:RestoreAnimationData(animManager, actor, propertyPath, timeOffset, dataOffset)
		-- TODO: Verify that keyframe value has not been overwritten (should be excluded because of panima.TIME_EPSILON)
		count = count + 1
	end
end
function Command:DoExecute(data)
	self:RestoreAnimationData()
	return true
end
function Command:DoUndo(data)
	self:RestoreAnimationData()
	return true
end
pfm.register_command("restore_animation_data", Command)
