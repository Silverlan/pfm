-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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

	if
		propertyPath == "ec/pfm_actor/position"
		or propertyPath == "ec/pfm_actor/rotation"
		or propertyPath == "ec/pfm_actor/scale"
	then
		-- If we're animating any of the actor's transform properties, we need to make sure the actor is not static
		local isStatic = actor:GetMemberValue("ec/pfm_actor/static")
		if isStatic == true then
			self:AddSubCommand("set_actor_property", actor, "ec/pfm_actor/static", true, false, udm.TYPE_BOOLEAN)
		end
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
		if channel == nil then
			self:LogFailure(
				"Failed to add animation channel for property '"
					.. propertyPath
					.. "' for actor '"
					.. actorUuid
					.. "' with value type '"
					.. strType
					.. "'!"
			)
		end
		return
	end
	tool.get_filmmaker():UpdateActorAnimationState(actor, true)
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
	tool.get_filmmaker():UpdateActorAnimationState(actor, false)
end
pfm.register_command("add_animation_channel", Command)
