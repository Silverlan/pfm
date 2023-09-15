--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandAddEditorChannel", pfm.Command)
function Command:Initialize(actorUuid, propertyPath)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if channel ~= nil then
		local editorData = animClip:GetEditorData()
		local editorChannel = editorData:FindChannel(propertyPath)
		if editorChannel ~= nil then
			return pfm.Command.RESULT_NO_OP
		end
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
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

	local anim, channel, animClip, newChannel = self:GetAnimationManager()
		:FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		self:LogFailure("Missing animation channel!")
		return
	end

	local editorData = animClip:GetEditorData()
	editorData:FindChannel(propertyPath, true)
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

	local anim, channel, animClip, newChannel = self:GetAnimationManager()
		:FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		self:LogFailure("Missing animation channel!")
		return
	end

	local editorData = animClip:GetEditorData()
	local channel = editorData:FindChannel(propertyPath)
	if channel == nil then
		self:LogFailure("Missing editor channel!")
		return
	end
	editorData:RemoveChannel(channel)
end
pfm.register_command("add_editor_channel", Command)
