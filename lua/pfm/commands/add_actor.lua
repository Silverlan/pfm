-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Command = util.register_class("pfm.CommandAddActors", pfm.Command)
function Command:Initialize(filmClip, actors)
	pfm.Command.Initialize(self)
	local data = self:GetData()

	local pm = self:GetProjectManager()
	pm:WriteActorsToUdmElement(filmClip, actors, data, "actors")
	data:SetValue("filmClip", udm.TYPE_STRING, pfm.get_unique_id(filmClip))
	return pfm.Command.RESULT_SUCCESS
end
function Command:DoExecute(data)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end

	local pm = self:GetProjectManager()
	pm:RestoreActorsFromUdmElement(filmClip, data, true, "actors")
	return true
end
function Command:DoUndo(data)
	local filmClipUuid = data:GetValue("filmClip", udm.TYPE_STRING)
	local filmClip = pfm.dereference(filmClipUuid)
	if filmClip == nil then
		self:LogFailure("FilmClip '" .. filmClipUuid .. "' not found!")
		return false
	end

	local udmActors = data:Get("actors"):Get("data")
	local numActors = udmActors:GetSize()
	local actors = {}
	for i = 1, numActors do
		local udmActor = udmActors:Get(i - 1)
		local uniqueId = udmActor:Get("data"):GetValue("uniqueId", udm.TYPE_STRING)
		local actor = pfm.dereference(uniqueId)
		if actor ~= nil then
			table.insert(actors, actor)
		end
	end
	filmClip:RemoveActors(actors)
end
pfm.register_command("add_actor", Command)
