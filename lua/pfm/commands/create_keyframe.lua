--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandCreateKeyframe", pfm.Command)
function Command.does_keyframe_exist(animManager, actorUuid, propertyPath, timestamp, baseIndex)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		return false
	end

	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	local editorChannel
	if animClip ~= nil then
		local editorData = animClip:GetEditorData()
		editorChannel = editorData:FindChannel(propertyPath)
		if editorChannel ~= nil then
			local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, baseIndex)
			if keyIdx ~= nil then
				-- Keyframe already exists
				return true, editorChannel, keyIdx
			end
		end
	end
	return false, editorChannel
end
function Command:Initialize(actorUuid, propertyPath, valueType, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local res, subCmd = self:AddSubCommand("add_editor_channel", actor, propertyPath, valueType)
	if res == pfm.Command.RESULT_SUCCESS then
		subCmd:AddSubCommand("add_animation_channel", actor, propertyPath, pfm.to_animation_channel_type(valueType))
	end

	local baseIndices = self:GetBaseIndices(baseIndex, valueType)
	local allExist = true
	for _, baseIndex in ipairs(baseIndices) do
		local kfExists, editorChannel, keyIdx =
			Command.does_keyframe_exist(self:GetAnimationManager(), actorUuid, propertyPath, timestamp, baseIndex)
		if not kfExists then
			allExist = false
			break
		end
	end

	if allExist then
		-- Keyframes already exists
		self:LogFailure("Keyframe already exists!")
		return pfm.Command.RESULT_FAILURE
	end

	--[[ Commented because we animation data will automatically be removed anyway when the keyframe curve segments are updated.
	if editorChannel ~= nil then
		local graphCurve = editorChannel:GetGraphCurve()
		local keyData = graphCurve:GetKey(baseIndex)
		if keyData ~= nil then
			local t0 = keyData:GetTime(0)
			if t0 ~= nil and timestamp < t0 - pfm.udm.EditorChannelData.TIME_EPSILON then
				-- New keyframe will be the first keyframe in the graph, we'll have to delete the animation data between
				-- the first two keyframes
				self:AddSubCommand("delete_animation_channel_range", actorUuid, propertyPath, timestamp, t0)
			else
				local t1 = keyData:GetTime(keyData:GetKeyframeCount() - 1)
				if t1 ~= nil and timestamp > t1 + pfm.udm.EditorChannelData.TIME_EPSILON then
					-- New keyframe will be the last keyframe in the graph, we'll have to delete the animation data between
					-- the last two keyframes
					self:AddSubCommand("delete_animation_channel_range", actorUuid, propertyPath, t1, timestamp)
				end
			end
		end
	end]]

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	if baseIndex ~= nil then
		data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex)
	end
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetBaseIndices(baseIndex, valueType)
	local baseIndices = {}
	if baseIndex ~= nil then
		table.insert(baseIndices, baseIndex)
	else
		local n = udm.get_numeric_component_count(valueType)
		for i = 0, n - 1 do
			table.insert(baseIndices, i)
		end
	end
	return baseIndices
end
function Command:GetChannelData()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local strValueType = data:GetValue("propertyType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strValueType)
	if valueType == nil then
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel!")
		return
	end
	local baseIndices = self:GetBaseIndices(valueBaseIndex, valueType)
	return actor, animClip, baseIndices, editorChannel
end
function Command:CreateKeyframe(data)
	local actor, animClip, baseIndices, editorChannel = self:GetChannelData()
	if actor == nil then
		return false
	end
	local graphCurve = editorChannel:GetGraphCurve()
	local timestamp = self:GetLocalTime(animClip)

	for _, valueBaseIndex in ipairs(baseIndices) do
		local keyData = graphCurve:GetKey(valueBaseIndex)
		if keyData ~= nil then
			local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)
			if keyIdx ~= nil then
				-- Keyframe already exists
				self:LogFailure("Keyframe already exists!")
				return false
			end
		end
		editorChannel:AddKey(timestamp, valueBaseIndex)
	end
	-- Commented, because this command should be wrapped in a keyframe_property_composition, which already rebuilds dirty graph curve segments
	-- self:RebuildDirtyGraphCurveSegments()
	return true
end
function Command:RemoveKeyframe(data)
	local actor, animClip, baseIndices, editorChannel = self:GetChannelData()
	if actor == nil then
		return false
	end

	local timestamp = self:GetLocalTime(animClip)
	for _, valueBaseIndex in ipairs(baseIndices) do
		editorChannel:RemoveKey(timestamp, valueBaseIndex)
	end
	-- Commented, because this command should be wrapped in a keyframe_property_composition, which already rebuilds dirty graph curve segments
	-- self:RebuildDirtyGraphCurveSegments()
	return true
end
function Command:GetAnimationClip()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end
	return animClip
end
function Command:RebuildDirtyGraphCurveSegments()
	local animClip = self:GetAnimationClip()
	if animClip == nil then
		return
	end
	local data = self:GetData()
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = editorChannel:GetGraphCurve()
	graphCurve:RebuildDirtyGraphCurveSegments()
end
function Command:GetLocalTime(channelClip)
	local data = self:GetData()
	local time = data:GetValue("timestamp", udm.TYPE_FLOAT)
	return channelClip:LocalizeOffsetAbs(time)
end
function Command:DoExecute(data)
	return self:CreateKeyframe(data)
end
function Command:DoUndo(data)
	return self:RemoveKeyframe(data)
end
pfm.register_command("create_keyframe", Command)
