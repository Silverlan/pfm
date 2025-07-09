-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandSetClipStart", pfm.Command)
function Command:Initialize(clip, oldStart, newStart)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("clip", udm.TYPE_STRING, pfm.get_unique_id(clip))
	data:SetValue("oldStart", udm.TYPE_FLOAT, oldStart)
	data:SetValue("newStart", udm.TYPE_FLOAT, newStart)
	return true
end
function Command:ApplyOffset(data, keyName)
	local clipUuid = data:GetValue("clip", udm.TYPE_STRING)
	local clip = pfm.dereference(clipUuid)
	if clip == nil then
		self:LogFailure("Clip '" .. clipUuid .. "' not found!")
		return false
	end
	clip:GetTimeFrame():SetStart(data:GetValue(keyName, udm.TYPE_FLOAT))
	local track = clip:GetParent()
	track:UpdateFilmClipTimeFrames()
	return true
end
function Command:DoExecute(data)
	return self:ApplyOffset(data, "newStart")
end
function Command:DoUndo(data)
	return self:ApplyOffset(data, "oldStart")
end
pfm.register_command("set_clip_start", Command)
