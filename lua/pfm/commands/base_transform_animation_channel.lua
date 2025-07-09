-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.BaseCommandTransformAnimationChannel", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, startTime, endTime)
	pfm.Command.Initialize(self)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return pfm.Command.RESULT_FAILURE
	end

	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	if startTime ~= nil then
		data:SetValue("startTime", udm.TYPE_FLOAT, startTime)
		data:SetValue("endTime", udm.TYPE_FLOAT, endTime)
	end
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetChannel()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	return channel
end
function Command:CopyChannel()
	local channel = self:GetChannel()
	if channel == nil then
		return
	end
	return panima.Channel(channel)
end
function Command:ApplyTransform(undo)
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if channel == nil then
		return false
	end

	local startTime = data:GetValue("startTime", udm.TYPE_FLOAT)
	local endTime = data:GetValue("endTime", udm.TYPE_FLOAT)
	self:DoApplyTransform(undo, data, actor, propertyPath, anim, channel, startTime, endTime)

	local animClipChannel = animClip:FindChannel(propertyPath)
	if animClipChannel ~= nil then
		animClip:UpdateAnimationChannel(animClipChannel)
	end
	return true
end
function Command:DoApplyTransform(undo, data, actor, propertyPath, anim, channel, startTime, endTime) end
function Command:DoExecute(data)
	self:ApplyTransform(false)
end
function Command:DoUndo(data)
	self:ApplyTransform(true)
end
