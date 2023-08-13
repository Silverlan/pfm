--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandCreateKeyframe", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, valueType, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	self:AddSubCommand("add_animation_channel", actorUuid, propertyPath, valueType)
	self:AddSubCommand("add_editor_channel", actorUuid, propertyPath)

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if animClip ~= nil then
		local editorData = animClip:GetEditorData()
		local editorChannel = editorData:FindChannel(propertyPath)
		if editorChannel ~= nil then
			local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, baseIndex)
			if keyIdx ~= nil then
				-- Keyframe already exists
				self:LogFailure("Keyframe already exists!")
				return pfm.Command.RESULT_FAILURE
			end
		end
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	data:SetValue("timestamp", udm.TYPE_FLOAT, timestamp)
	data:SetValue("valueBaseIndex", udm.TYPE_UINT8, baseIndex)
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local strType = data:GetValue("propertyType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strType)
	if valueType == nil then
		self:LogFailure("Invalid value type '" .. strType .. "'!")
		return
	end

	local timestamp = data:GetValue("timestamp", udm.TYPE_FLOAT)
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
	local graphCurve = editorChannel:GetGraphCurve()
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
function Command:DoUndo()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local timestamp = data:GetValue("timestamp", udm.TYPE_FLOAT)
	local valueBaseIndex = data:GetValue("valueBaseIndex", udm.TYPE_UINT8)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end

	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		self:LogFailure("Missing editor channel for property '" .. propertyPath .. "'!")
		return
	end

	editorChannel:RemoveKey(timestamp, valueBaseIndex)
end
pfm.register_command("create_keyframe", Command)
