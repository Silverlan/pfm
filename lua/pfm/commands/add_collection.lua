--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandAddCollection", pfm.Command)
function Command:Initialize(parentCollection, name)
	pfm.Command.Initialize(self)
	local data = self:GetData()
	data:SetValue("parentCollection", udm.TYPE_STRING, pfm.get_unique_id(parentCollection))
	data:SetValue("name", udm.TYPE_STRING, name)
	data:SetValue("uuid", udm.TYPE_STRING, tostring(util.generate_uuid_v4())) -- We need to make sure the uuid is consistent every time
	return pfm.Command.RESULT_SUCCESS
end
function Command:GetFilmClip(collection)
	local parent = collection:GetParent()
	while parent ~= nil and util.get_type_name(parent) ~= "FilmClip" do
		parent = parent:GetParent()
	end
	if parent ~= nil and util.get_type_name(parent) ~= "FilmClip" then
		parent = nil
	end
	return parent
end
function Command:DoExecute(data)
	local parentCollectionUuid = data:GetValue("parentCollection", udm.TYPE_STRING)
	local parentCollection = pfm.dereference(parentCollectionUuid)
	if parentCollection == nil then
		self:LogFailure("Parent collection '" .. parentCollectionUuid .. "' not found!")
		return false
	end
	local filmClip = self:GetFilmClip(parentCollection)
	if filmClip == nil then
		self:LogFailure("Failed to determine film clip for collection '" .. parentCollectionUuid .. "'!")
		return false
	end
	return filmClip:AddGroup(
		parentCollection,
		data:GetValue("name", udm.TYPE_STRING),
		data:GetValue("uuid", udm.TYPE_STRING)
	)
end
function Command:DoUndo(data)
	local collectionUuid = data:GetValue("uuid", udm.TYPE_STRING)
	local collection = pfm.dereference(collectionUuid)
	if collection == nil then
		self:LogFailure("Collection '" .. collectionUuid .. "' not found!")
		return false
	end
	local filmClip = self:GetFilmClip(collection)
	if filmClip == nil then
		self:LogFailure("Failed to determine film clip for collection '" .. collectionUuid .. "'!")
		return false
	end
	filmClip:RemoveGroup(collection)
	return true
end
pfm.register_command("add_collection", Command)
