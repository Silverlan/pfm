--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_GROUP = udm.register_element("PFMGroup")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_GROUP,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_GROUP,"actors",udm.Array(udm.ELEMENT_TYPE_ANY)) -- Can contain actors or groups
udm.register_element_property(udm.ELEMENT_TYPE_PFM_GROUP,"visible",udm.Bool(false),{
	getter = "IsVisible"
})

function udm.PFMGroup:Initialize()
	udm.BaseElement.Initialize(self)
end

function udm.PFMGroup:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:FindParentElement()
	if(parent == nil or parent.IsAbsoluteVisible == nil) then return true end
	return parent:IsAbsoluteVisible()
end

function udm.PFMGroup:AddActor(actor)
	for _,actorOther in ipairs(self:GetActors():GetTable()) do
		if(util.is_same_object(actor,actorOther)) then return end
	end
	self:GetActors():PushBack(actor)
end

function udm.PFMGroup:AddGroup(group)
	self:AddActor(group)
end

function udm.PFMGroup:GetActorList(list)
	list = list or {}
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == udm.ELEMENT_TYPE_PFM_GROUP) then actor:GetActorList(list)
		else table.insert(list,actor) end
	end
	return list
end

function udm.PFMGroup:FindActor(name)
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == udm.ELEMENT_TYPE_PFM_GROUP) then
			local el = actor:FindActor(name)
			if(el ~= nil) then return el end
		elseif(actor:GetName() == name) then return actor end
	end
end
