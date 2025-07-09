-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("restore_animation_data.lua")

local Command = util.register_class("pfm.CommandMoveKeyframes", pfm.CommandStoreAnimationData)
function Command:Initialize(actorUuid, propertyPath, valueBaseIndex, animData)
	pfm.CommandStoreAnimationData.Initialize(self, actorUuid, propertyPath, valueBaseIndex, animData)
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetAnimationClip()
	local data = self:GetData()
	local actorUuid = data:GetValue("actor", udm.TYPE_STRING)
	local actor = pfm.dereference(actorUuid)
	if actor == nil then
		self:LogFailure("Actor '" .. actorUuid .. "' not found!")
		return
	end

	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)

	local anim, channel, animClip = self:GetAnimationManager():FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		self:LogFailure("Missing animation channel!")
		return
	end
	return animClip
end
function Command:RebuildDirtyGraphCurveSegments()
	local animClip = self:GetAnimationClip()
	if animClip == nil then
		return
	end
	local data = self:GetData()
	local propertyPath = data:GetValue("propertyPath", udm.TYPE_STRING)
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = editorChannel:GetGraphCurve()
	graphCurve:RebuildDirtyGraphCurveSegments()
end
function Command:DoExecute(data)
	return true
end
function Command:DoUndo(data)
	return true
end
function Command:Execute(...)
	local res = pfm.Command.Execute(self, ...)
	if res == false then
		return false
	end
	self:RebuildDirtyGraphCurveSegments()
	self:RestoreAnimationData(self:GetData())
	return true
end
function Command:Undo(...)
	local res = pfm.Command.Undo(self, ...)
	if res == false then
		return false
	end
	self:RebuildDirtyGraphCurveSegments()
	self:RestoreAnimationData(self:GetData())
	return true
end
pfm.register_command("move_keyframes", Command)
