--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandDeleteCollection", pfm.Command)
function Command:Initialize(filmClip, collection)
	pfm.Command.Initialize(self)
	collection = pfm.dereference(collection)
	local parentCollection = pfm.dereference(collection):GetParent()
	local data = self:GetData()
	local actors = self:FindActors(collection)
	self:AddSubCommand("delete_actors", filmClip, actors)
	data:SetValue("filmClip", pfm.get_unique_id(filmClip))
	data:SetValue("collection", pfm.get_unique_id(collection))
	data:SetValue("parentCollection", pfm.get_unique_id(parentCollection))
	data:SetValue("name", collection:GetName())
	data:SetValue("uuid", tostring(collection:GetUniqueId()))
	return pfm.Command.RESULT_SUCCESS
end
function Command:FindActors(collection)
	local actorIds = {}
	local function find_actors(group)
		for _, actor in ipairs(group:GetActors()) do
			table.insert(actorIds, tostring(actor:GetUniqueId()))
		end
		for _, childGroup in ipairs(group:GetGroups()) do
			find_actors(childGroup)
		end
	end
	find_actors(collection)
	return actorIds
end
function Command:GetFilmClip(data)
	return pfm.dereference(data:GetValue("filmClip", udm.TYPE_STRING))
end
function Command:DoExecute(data)
	local collectionUuid = data:GetValue("collection", udm.TYPE_STRING)
	local collection = pfm.dereference(collectionUuid)
	if collection == nil then
		self:LogFailure("Invalid collection '" .. collectionUuid .. "'!")
		return false
	end

	local filmClip = self:GetFilmClip(data)
	if filmClip == nil then
		self:LogFailure("Failed to determine film clip for collection '" .. collectionUuid .. "'!")
		return false
	end

	filmClip:RemoveGroup(collection)
	return true
end
function Command:DoUndo(data)
	local collectionUuid = data:GetValue("collection", udm.TYPE_STRING)
	local collection = pfm.dereference(collectionUuid)
	if collection ~= nil then
		self:LogFailure("Collection '" .. collectionUuid .. "' already exists!")
		return false
	end

	local parentCollectionUuid = data:GetValue("parentCollection", udm.TYPE_STRING)
	local parentCollection = pfm.dereference(parentCollectionUuid)
	if parentCollection == nil then
		self:LogFailure("Parent collection '" .. parentCollection .. "' not found!")
		return false
	end

	local filmClip = self:GetFilmClip(data)
	if filmClip == nil then
		self:LogFailure("Failed to determine film clip for collection '" .. collectionUuid .. "'!")
		return false
	end

	return filmClip:AddGroup(
		parentCollection,
		data:GetValue("name", udm.TYPE_STRING),
		data:GetValue("uuid", udm.TYPE_STRING)
	)
end
pfm.register_command("delete_collection", Command)
