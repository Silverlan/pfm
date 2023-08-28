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
	if animClip ~= nil then
		local editorData = animClip:GetEditorData()
		local editorChannel = editorData:FindChannel(propertyPath)
		if editorChannel ~= nil then
			local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, baseIndex)
			if keyIdx ~= nil then
				-- Keyframe already exists
				return true
			end
		end
	end
	return false
end
function Command:Initialize(actorUuid, propertyPath, valueType, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	self:AddSubCommand("add_animation_channel", actorUuid, propertyPath, valueType)
	self:AddSubCommand("add_editor_channel", actorUuid, propertyPath)

	if Command.does_keyframe_exist(self:GetAnimationManager(), actorUuid, propertyPath, timestamp, baseIndex) then
		-- Keyframe already exists
		self:LogFailure("Keyframe already exists!")
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex or 0)
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetChannelData()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
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
	return actor, animClip, valueBaseIndex, editorChannel
end
function Command:CreateKeyframe(data)
	local actor, animClip, valueBaseIndex, editorChannel = self:GetChannelData()
	if actor == nil then
		return false
	end
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(valueBaseIndex)

	local timestamp = self:GetLocalTime(animClip)
	if keyData ~= nil then
		local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, valueBaseIndex)
		if keyIdx ~= nil then
			-- Keyframe already exists
			self:LogFailure("Keyframe already exists!")
			return false
		end
	end
	editorChannel:AddKey(timestamp, valueBaseIndex)
	return true
end
function Command:RemoveKeyframe(data)
	local actor, animClip, valueBaseIndex, editorChannel = self:GetChannelData()
	if actor == nil then
		return false
	end

	local timestamp = self:GetLocalTime(animClip)
	editorChannel:RemoveKey(timestamp, valueBaseIndex)
	return true
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
