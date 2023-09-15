--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandAddAnimationChannel", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, valueType)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if channel ~= nil then
		-- Channel already existed, nothing to be done
		return pfm.Command.RESULT_NO_OP
	end
	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyType", udm.TYPE_STRING, udm.type_to_string(valueType))
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

	local anim, channel, animClip, newChannel = self:GetAnimationManager()
		:FindAnimationChannel(actor, propertyPath, true, valueType)
	if newChannel == false then
		self:LogFailure(
			"Failed to add animation channel for property '"
				.. propertyPath
				.. "' for actor '"
				.. actorUuid
				.. "' with value type '"
				.. strType
				.. "'!"
		)
		return
	end
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
	local strType = data:GetValue("propertyType", udm.TYPE_STRING)
	local valueType = udm.string_to_type(strType)
	if valueType == nil then
		self:LogFailure("Invalid value type '" .. strType .. "'!")
		return
	end

	if self:GetAnimationManager():RemoveChannel(actor, propertyPath) == false then
		self:LogFailure("Failed to remove channel '" .. actorUuid .. "' of property '" .. propertyPath .. "'!")
		return
	end
end
pfm.register_command("add_animation_channel", Command)
