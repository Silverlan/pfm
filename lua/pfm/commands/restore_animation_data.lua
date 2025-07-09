-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandStoreAnimationData", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, valueBaseIndex, animData)
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
	if animData ~= nil then
		data:Merge(animData, udm.MERGE_FLAG_BIT_DEEP_COPY)
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
	local udmPreAnimationData = data:Get("preAnimationData")
	local udmPostAnimationData = data:Get("postAnimationData")
	local animDataInfo = {
		{
			data = udmPreAnimationData,
			prefix = true,
		},
		{
			data = udmPostAnimationData,
			prefix = false,
		},
	}

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)

	for _, udmAnimDataInfo in ipairs(animDataInfo) do
		local udmAnimData = udmAnimDataInfo.data
		if udmAnimData ~= nil then
			local animManager = self:GetAnimationManager()
			local animDataBuffer = pfm.util.AnimationDataBuffer(udmAnimData)
			local keyData = editorChannel:GetGraphCurve():GetKey(valueBaseIndex)
			local idx
			if udmAnimDataInfo.prefix then
				idx = 0
			else
				idx = keyData:GetKeyframeCount() - 1
			end
			local kfTime = keyData:GetTime(idx)
			local kfValue = keyData:GetValue(idx)
			local timeOffset = kfTime + (udmAnimData:GetValue("timeOffset", udm.TYPE_FLOAT) or 0.0)
			local dataOffset = kfValue + (udmAnimData:GetValue("dataOffset", udm.TYPE_FLOAT) or 0.0)
			local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
			local function clear_range(startTime, endTime)
				local valueType = channel:GetValueType()
				local n = udm.get_numeric_component_count(valueType)
				if n > 1 then
					local clearValue = kfValue
					local curTimes, curValues = channel:GetDataInRange(startTime, endTime)
					for i, t in ipairs(curTimes) do
						local v = curValues[i]
						v = udm.set_numeric_component(v, valueBaseIndex, valueType, clearValue)
						channel:InsertValue(t, v)
					end
				else
					channel:ClearRange(startTime, endTime, false)
				end
			end
			if udmAnimDataInfo.prefix then
				local endTime = kfTime - pfm.udm.EditorChannelData.TIME_EPSILON * 2
				clear_range(-math.huge, endTime)
			else
				local startTime = kfTime + pfm.udm.EditorChannelData.TIME_EPSILON * 2
				clear_range(startTime, math.huge)
			end
			animDataBuffer:RestoreAnimationData(
				animManager,
				actor,
				propertyPath,
				timeOffset + pfm.udm.EditorChannelData.TIME_EPSILON,
				dataOffset
			)
		end
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
