--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandDeleteActors", pfm.Command)
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

	local udmActors = data:Get("actors"):Get("data")
	local numActors = udmActors:GetSize()
	local actors = {}
	for i = 1, numActors do
		local udmActor = udmActors:Get(i - 1)
		if udmActor:GetValue("type", udm.TYPE_STRING) == "actor" then
			local uniqueId = udmActor:Get("data"):GetValue("uniqueId", udm.TYPE_STRING)
			local actor = pfm.dereference(uniqueId)
			if actor ~= nil then
				table.insert(actors, actor)
			end
		end
	end
	filmClip:RemoveActors(actors)
end
function Command:DoUndo(data)
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
pfm.register_command("delete_actors", Command)
