--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Group:GetActorList(list)
	list = list or {}
	for _,actor in ipairs(self:GetActors()) do
		table.insert(list,actor)
	end
	for _,group in ipairs(self:GetGroups()) do
		group:GetActorList(list)
	end
	return list
end

function pfm.udm.Group:FindActorByUniqueId(uniqueId)
	for _,actor in ipairs(self:GetActors()) do
		if(tostring(actor:GetUniqueId()) == uniqueId) then
			return actor,self
		end
	end
	for _,group in ipairs(self:GetGroups()) do
		local actor = group:FindActorByUniqueId(uniqueId)
		if(actor ~= nil) then return actor,group end
	end
end

function pfm.udm.Group:GetAbsolutePose(filter)
	local pose = self:GetTransform()
	local parent = self:GetParent()
	if(parent.TypeName ~= "Group") then return pose end
	return parent:GetAbsolutePose() *pose
end

function pfm.udm.Group:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:GetParent()
	if(parent.TypeName ~= "Group") then return true end
	return parent:IsAbsoluteVisible()
end
