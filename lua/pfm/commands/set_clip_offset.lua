-- SPDX-FileCopyrightText: (c) 2025 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandSetClipOffset", pfm.Command)
function Command:Initialize(clip, oldOffset, newOffset)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("clip", udm.TYPE_STRING, pfm.get_unique_id(clip))
	data:SetValue("oldOffset", udm.TYPE_FLOAT, oldOffset)
	data:SetValue("newOffset", udm.TYPE_FLOAT, newOffset)
	return true
end
function Command:ApplyOffset(data, keyName)
	local clipUuid = data:GetValue("clip", udm.TYPE_STRING)
	local clip = pfm.dereference(clipUuid)
	if clip == nil then
		self:LogFailure("Clip '" .. clipUuid .. "' not found!")
		return false
	end
	clip:GetTimeFrame():SetOffset(data:GetValue(keyName, udm.TYPE_FLOAT))
	local track = clip:GetParent()
	track:UpdateFilmClipTimeFrames()
	return true
end
function Command:DoExecute(data)
	return self:ApplyOffset(data, "newOffset")
end
function Command:DoUndo(data)
	return self:ApplyOffset(data, "oldOffset")
end
pfm.register_command("set_clip_offset", Command)
