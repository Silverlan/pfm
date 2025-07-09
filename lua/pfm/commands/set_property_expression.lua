-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandSetPropertyExpression", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, newExpression, valueType)
	pfm.Command.Initialize(self)

	self:AddSubCommand("add_animation_channel", actorUuid, propertyPath, valueType)
	-- self:AddSubCommand("add_editor_channel", actorUuid, propertyPath)

	local actor = pfm.dereference(actorUuid)
	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	local oldExpression
	if channel ~= nil then
		oldExpression = animManager:GetValueExpression(actor, propertyPath)
	end
	if channel == nil or channel:GetValueCount() == 0 then
		-- Animation expression requires there to be an animation channel with at least one value.
		-- If there isn't one, we'll just create one with the current property value.
		local value = actor:GetMemberValue(propertyPath)
		if value ~= nil then
			self:AddSubCommand("set_animation_value", actorUuid, propertyPath, 0.0, valueType, nil, value)
		end
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, pfm.get_unique_id(actorUuid))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	if oldExpression ~= nil then
		data:SetValue("oldExpression", udm.TYPE_STRING, oldExpression)
	end
	if newExpression ~= nil then
		data:SetValue("newExpression", udm.TYPE_STRING, newExpression)
	end
	data:SetValue("valueType", udm.TYPE_STRING, udm.type_to_string(valueType))
	return true
end
function Command:ApplyExpression(data, keyName)
	local actor = pfm.dereference(data:GetValue("actor", udm.TYPE_STRING))
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local expr = data:GetValue(keyName, udm.TYPE_STRING)

	local animManager = self:GetAnimationManager()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		self:LogFailure("Missing animation channel for property '" .. propertyPath .. "'!")
		return false
	end

	if animClip ~= nil then
		local channel = animClip:GetChannel(propertyPath)
		if channel ~= nil then
			channel:ChangeExpression(expr)
		end
	end

	if expr == nil then
		channel:ClearValueExpression()
	else
		local res = channel:SetValueExpression(expr)
		if res ~= true then
			self:LogFailure("Unable to apply channel value expression '" .. expr .. "': " .. res)
			return false
		end
	end

	return true
end
function Command:DoExecute(data)
	return self:ApplyExpression(data, "newExpression")
end
function Command:DoUndo(data)
	return self:ApplyExpression(data, "oldExpression")
end
pfm.register_command("set_property_expression", Command)
