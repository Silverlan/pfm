-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandSetClipDuration", pfm.Command)
function Command:Initialize(clip, oldDuration, newDuration)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("clip", udm.TYPE_STRING, pfm.get_unique_id(clip))
	data:SetValue("oldDuration", udm.TYPE_FLOAT, oldDuration)
	data:SetValue("newDuration", udm.TYPE_FLOAT, newDuration)
	return true
end
function Command:ApplyDuration(data, keyName)
	local clipUuid = data:GetValue("clip", udm.TYPE_STRING)
	local clip = pfm.dereference(clipUuid)
	if clip == nil then
		self:LogFailure("Clip '" .. clipUuid .. "' not found!")
		return false
	end
	clip:GetTimeFrame():SetDuration(data:GetValue(keyName, udm.TYPE_FLOAT))
	local track = clip:GetParent()
	track:UpdateFilmClipTimeFrames()
	return true
end
function Command:DoExecute(data)
	return self:ApplyDuration(data, "newDuration")
end
function Command:DoUndo(data)
	return self:ApplyDuration(data, "oldDuration")
end
pfm.register_command("set_clip_duration", Command)
