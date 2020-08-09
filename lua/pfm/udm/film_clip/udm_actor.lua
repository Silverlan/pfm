--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/udm_scene_element.lua")
include("actor/components")

udm.ELEMENT_TYPE_PFM_ACTOR = udm.register_type("PFMActor",{udm.PFMSceneElement},true)
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"components",udm.Array(udm.ELEMENT_TYPE_ANY))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"operators",udm.Array(udm.ELEMENT_TYPE_ANY))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ACTOR,"visible",udm.Bool(true),{
	getter = "IsVisible"
})

function udm.PFMActor:GetSceneChildren() return self:GetComponents():GetTable() end

function udm.PFMActor:AddComponent(pfmComponent)
	self:GetComponentsAttr():PushBack(pfmComponent)
	self:AddChild(pfmComponent)
end

function udm.PFMActor:FindComponent(name)
	for _,component in ipairs(self:GetComponents():GetTable()) do
		if(component:GetComponentName() == name) then return component end
	end
end

function udm.PFMActor:HasComponent(name)
	if(type(name) == "string") then return self:FindComponent(name) ~= nil end
	for _,component in ipairs(self:GetComponents():GetTable()) do
		if(util.is_same_object(name,component)) then return true end
	end
	return false
end

function udm.PFMActor:FindEntity()
	for ent in ents.iterator({ents.IteratorFilterComponent("pfm_actor")}) do
		local actorC = ent:GetComponent("pfm_actor")
		if(util.is_same_object(actorC:GetActorData(),self)) then return ent end
	end
end

function udm.PFMActor:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:GetSceneParent()
	if(parent == nil or parent.IsAbsoluteVisible == nil) then return true end
	return parent:IsAbsoluteVisible()
end
