--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_PFM_GROUP = fudm.register_type("PFMGroup",{fudm.PFMSceneElement},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GROUP,"transform",fudm.Transform())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GROUP,"actors",fudm.Array(fudm.ELEMENT_TYPE_ANY)) -- Can contain actors or groups
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_GROUP,"visible",fudm.Bool(false),{
	getter = "IsVisible"
})

function fudm.PFMGroup:Initialize()
	fudm.BaseElement.Initialize(self)
end

function fudm.PFMGroup:GetSceneChildren() return self:GetActors():GetTable() end

function fudm.PFMGroup:IsScene()
	local parent = self:GetSceneParent()
	return parent ~= nil and util.is_same_object(self,parent:GetScene())
end

function fudm.PFMGroup:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:GetSceneParent()
	if(parent == nil or parent.IsAbsoluteVisible == nil) then return true end
	return parent:IsAbsoluteVisible()
end

function fudm.PFMGroup:AddActor(actor)
	for _,actorOther in ipairs(self:GetActors():GetTable()) do
		if(util.is_same_object(actor,actorOther)) then return end
	end
	self:GetActors():PushBack(actor)
end

function fudm.PFMGroup:AddGroup(group)
	self:AddActor(group)
end

function fudm.PFMGroup:GetActorList(list)
	list = list or {}
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == fudm.ELEMENT_TYPE_PFM_GROUP) then actor:GetActorList(list)
		else table.insert(list,actor) end
	end
	return list
end

function fudm.PFMGroup:FindActor(name)
	for _,actor in ipairs(self:GetActors():GetTable()) do
		if(actor:GetType() == fudm.ELEMENT_TYPE_PFM_GROUP) then
			local el = actor:FindActor(name)
			if(el ~= nil) then return el end
		elseif(actor:GetName() == name) then return actor end
	end
end
