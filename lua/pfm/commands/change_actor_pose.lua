-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandChangeActorPose", pfm.Command)
function Command:Initialize(actor, oldPos, newPos, oldRot, newRot, oldScale, newScale)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, tostring(actor:GetUniqueId()))
	if oldPos ~= nil then
		data:SetValue("oldPos", udm.TYPE_VECTOR3, oldPos)
		data:SetValue("newPos", udm.TYPE_VECTOR3, newPos)
	end
	if oldRot ~= nil then
		data:SetValue("oldRot", udm.TYPE_VECTOR3, oldRot)
		data:SetValue("newRot", udm.TYPE_VECTOR3, newRot)
	end
	if oldScale ~= nil then
		data:SetValue("oldScale", udm.TYPE_VECTOR3, oldScale)
		data:SetValue("newScale", udm.TYPE_VECTOR3, newScale)
	end
	return pfm.Command.RESULT_SUCCESS
end
function Command:ApplyValue(data, keyPrefix)
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return false
	end
	local transform = actor:GetTransform()

	local changeFlags = pfm.udm.Actor.POSE_CHANGE_FLAG_NONE
	local newPos = data:GetValue(keyPrefix .. "Pos", udm.TYPE_VECTOR3)
	if newPos ~= nil then
		transform:SetOrigin(newPos)
		changeFlags = bit.bor(changeFlags, pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_POSITION)
	end

	local newRot = data:GetValue(keyPrefix .. "Rot", udm.TYPE_QUATERNION)
	if newRot ~= nil then
		transform:SetRotation(newRot)
		changeFlags = bit.bor(changeFlags, pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_ROTATION)
	end

	local newScale = data:GetValue(keyPrefix .. "Scale", udm.TYPE_VECTOR3)
	if newScale ~= nil then
		transform:SetScale(newScale)
		changeFlags = bit.bor(changeFlags, pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_SCALE)
	end
	actor:ChangePose(transform, changeFlags)
	return true
end
function Command:DoExecute(data)
	return self:ApplyValue(data, "new")
end
function Command:DoUndo(data)
	return self:ApplyValue(data, "old")
end
pfm.register_command("change_actor_pose", Command)
