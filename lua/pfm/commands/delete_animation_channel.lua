--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandDeleteAnimationChannel", pfm.CommandAddAnimationChannel)
function Command:Initialize(actorUuid, propertyPath, valueType)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		-- Channel doesn't exist, nothing to be done
		return pfm.Command.RESULT_NO_OP
	end

	-- Delete the animation data first so that it will be restored on undo
	self:AddSubCommand("delete_animation_channel_range", actorUuid, propertyPath, -math.huge, math.huge)

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(...)
	return pfm.CommandAddAnimationChannel.DoUndo(self, ...)
end
function Command:DoUndo(...)
	return pfm.CommandAddAnimationChannel.DoExecute(self, ...)
end
pfm.register_command("delete_animation_channel", Command)
