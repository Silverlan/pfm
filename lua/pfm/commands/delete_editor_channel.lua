--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandDeleteEditorChannel", pfm.CommandAddEditorChannel)
function Command:Initialize(actorUuid, propertyPath, valueType)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		return pfm.Command.RESULT_NO_OP
	end
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	if editorChannel == nil then
		return pfm.Command.RESULT_NO_OP
	end

	local graphCurve = editorChannel:GetGraphCurve()
	for i = 0, graphCurve:GetKeyCount() - 1 do
		local keyData = graphCurve:GetKey(i)
		for j = 0, keyData:GetTimeCount() - 1 do
			local t = keyData:GetTime(j)
			self:AddSubCommand("delete_keyframe", actorUuid, propertyPath, t, i)
		end
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(...)
	return pfm.CommandAddEditorChannel.DoExecute(self, ...)
end
function Command:DoUndo(...)
	return pfm.CommandAddEditorChannel.DoUndo(self, ...)
end
pfm.register_command("delete_editor_channel", Command)
