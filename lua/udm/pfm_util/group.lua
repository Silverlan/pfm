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

function pfm.udm.Group:FindActorIndex(actor)
	for i,actorOther in ipairs(self:GetActors()) do
		if(util.is_same_object(actorOther,actor)) then
			return i -1
		end
	end
end

function pfm.udm.Group:FindActorByUniqueId(uniqueId)
	for _,actor in ipairs(self:GetActors()) do
		if(tostring(actor:GetUniqueId()) == uniqueId) then
			return actor,self
		end
	end
	for _,group in ipairs(self:GetGroups()) do
		local actor,actorGroup = group:FindActorByUniqueId(uniqueId)
		if(actor ~= nil) then return actor,actorGroup end
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

function pfm.udm.Group:MoveActorTo(actor,targetGroup)
	local idxSrc = self:FindActorIndex(actor)
	if(idxSrc == nil) then return false end
	local udmActor = actor:GetUdmData()
	local udmSrc = self:GetUdmData():Get("actors")
	local udmDst = targetGroup:GetUdmData():Get("actors")
	-- Copy the actor data to the target group
	udmDst:Resize(udmDst:GetSize() +1)
	udmDst:Get(udmDst:GetSize() -1):Merge(udmActor,udm.MERGE_FLAG_BIT_DEEP_COPY)

	-- Remove actor from source
	local typedSrc = self:GetTypedChildren()["actors"]
	local child = typedSrc[idxSrc +1]
	udmSrc:RemoveValue(idxSrc)
	table.remove(typedSrc,idxSrc +1)

	-- Update UDM data for typed children (due to index change)
	for i=idxSrc +1,#typedSrc do
		local child = typedSrc[i]
		child.m_udmData = udmSrc:Get(i -1)
	end

	-- Add actor to destination
	local typedDst = targetGroup:GetTypedChildren()["actors"]
	table.insert(typedDst,child)
	child.m_parent = targetGroup

	-- Old UDM data has been invalidated, so we have to re-assign
	-- UDM data recursively
	child:ReloadUdmData(udmDst:Get(udmDst:GetSize() -1))
	return true
end
