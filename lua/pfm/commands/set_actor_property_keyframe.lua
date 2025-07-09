-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandCreateKeyframeX", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, timestamp, baseIndex)
	pfm.Command.Initialize(self)
	self:AddSubCommand("add_animation_channel", actorUuid, propertyPath, memberType)
	--[[
		local actor = pfm.dereference(actorUuid)
	if actor == nil then
		return
	end
	local anim, channel, animClip = self:FindAnimationChannel(actor, propertyPath, false)
	if animClip == nil then
		return
	end
	local editorData = animClip:GetEditorData()
	local editorChannel = editorData:FindChannel(propertyPath)
	local graphCurve = editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	if keyData == nil then
		return
	end

	local keyIdx = editorChannel:FindKeyIndexByTime(timestamp, baseIndex)
	if keyIdx == nil then
		return
	end

	local data = self:GetData()
	local kf = data:Add("keyframe")
	kf:SetValue("inType", udm.TYPE_UINT32, keyData:GetHandleType(keyIdx, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN))
	kf:SetValue("inDelta", udm.TYPE_FLOAT, keyData:GetInDelta(keyIdx))
	kf:SetValue("inTime", udm.TYPE_FLOAT, keyData:GetInTime(keyIdx))
	kf:SetValue("inType", udm.TYPE_UINT32, keyData:GetHandleType(keyIdx, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT))
	kf:SetValue("outDelta", udm.TYPE_FLOAT, keyData:GetOutDelta(keyIdx))
	kf:SetValue("outTime", udm.TYPE_FLOAT, keyData:GetOutTime(keyIdx))
	kf:SetValue("time", udm.TYPE_FLOAT, keyData:GetTime(keyIdx))
	kf:SetValue("value", udm.TYPE_FLOAT, keyData:GetValue(keyIdx))
]]
	--[[
function pfm.udm.EditorGraphCurveKeyData:GetHandleDelta(keyIndex, handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:GetInDelta(keyIndex)
	end
	return self:GetOutDelta(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleDelta(keyIndex, handle, dela)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:SetInDelta(keyIndex, dela)
	end
	return self:SetOutDelta(keyIndex, dela)
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleTimeOffset(keyIndex, handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:GetInTime(keyIndex)
	end
	return self:GetOutTime(keyIndex)
end
function pfm.udm.EditorGraphCurveKeyData:SetHandleTimeOffset(keyIndex, handle, offset)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:SetInTime(keyIndex, offset)
	end
	return self:SetOutTime(keyIndex, offset)
end
function pfm.udm.EditorGraphCurveKeyData:GetHandleType(keyIndex, handle)
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		return self:GetInHandleType(keyIndex)
	end
	return self:GetOutHandleType(keyIndex)
end
]]
	return true
end
function Command:DoExecute()
	--[[local data = self:GetData()
	local kf = data:Get("keyframe")
	if kf == nil then
		return
	end]]
end
function Command:DoUndo()
	--[[local data = self:GetData()
	local kf = data:Get("keyframe")
	if kf == nil then
		return
	end]]
	--function pfm.udm.EditorChannelData:RemoveKey(t, baseIndex)
end
--pfm.register_command("create_keyframe", Command)

local Command = util.register_class("pfm.CommandSetActorPropertyKeyframe", pfm.Command)
function Command:Initialize(actorUuid, propertyPath, memberValue, memberType)
	pfm.Command.Initialize(self)

	--[[local data = self:GetData()
	data:SetValue("actor", udm.TYPE_STRING, actorUuid)
	data:SetValue("propertyPath", udm.TYPE_STRING, propertyPath)
	data:SetValue("propertyValue", memberType, propertyPath)]]

	-- TODO: Add command AddAnimationChannel

	-- TODO: Sub-commands?

	-- TODO: Get current timestamp

	-- TODO: Get current keyframe

	-- TODO: Save animation data between this keyframe and the previous and next keyframes

	--[[entActor:GetComponent(ents.COMPONENT_PFM_ACTOR),
	controlData.path,
	memberValue,
	memberType]]
end
function Command:DoExecute()
	local pm = self:GetProjectManager()
	--pm:SetTimeOffset(self:GetData():GetValue("newTimeOffset", udm.TYPE_FLOAT))
end
function Command:DoUndo()
	local pm = self:GetProjectManager()
	--pm:SetTimeOffset(self:GetData():GetValue("oldTimeOffset", udm.TYPE_FLOAT))
end

--[[pfm.undoredo.push("pfm_undoredo_property", function()
	local entActor = ents.find_by_uuid(uniqueId)
	if entActor == nil then
		return
	end
	tool.get_filmmaker():SetActorGenericProperty()
end, function()
	local entActor = ents.find_by_uuid(uniqueId)
	if entActor == nil then
		return
	end
	tool.get_filmmaker()
		:SetActorGenericProperty(
			entActor:GetComponent(ents.COMPONENT_PFM_ACTOR),
			controlData.path,
			oldValue,
			memberType
		)
end)]]
pfm.register_command("set_actor_property_keyframe", Command)
