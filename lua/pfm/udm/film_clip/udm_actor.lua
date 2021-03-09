--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/udm_scene_element.lua")
include("actor/components")

fudm.ELEMENT_TYPE_PFM_ACTOR = fudm.register_type("PFMActor",{fudm.PFMSceneElement},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ACTOR,"uniqueId",fudm.String(""))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ACTOR,"transform",fudm.Transform())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ACTOR,"components",fudm.Array(fudm.ELEMENT_TYPE_ANY))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ACTOR,"operators",fudm.Array(fudm.ELEMENT_TYPE_ANY))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ACTOR,"visible",fudm.Bool(true),{
	getter = "IsVisible"
})

function fudm.PFMActor:Initialize() self:SetUniqueId(util.generate_uuid_v4()) end

function fudm.PFMActor:OnLoaded()
	local uniqueId = self:GetUniqueId()
	if(#uniqueId == 0) then self:SetUniqueId(util.generate_uuid_v4()) end -- TODO: This shouldn't be necessary
end

function fudm.PFMActor:GetSceneChildren() return self:GetComponents():GetTable() end

function fudm.PFMActor:AddComponent(pfmComponent)
	self:GetComponentsAttr():PushBack(pfmComponent)
	self:AddChild(pfmComponent)
end

function fudm.PFMActor:FindComponent(name)
	for _,component in ipairs(self:GetComponents():GetTable()) do
		if(component:GetComponentName() == name) then return component end
	end
end

function fudm.PFMActor:HasComponent(name)
	if(type(name) == "string") then return self:FindComponent(name) ~= nil end
	for _,component in ipairs(self:GetComponents():GetTable()) do
		if(util.is_same_object(name,component)) then return true end
	end
	return false
end

function fudm.PFMActor:FindEntity()
	for ent in ents.iterator({ents.IteratorFilterComponent("pfm_actor")}) do
		local actorC = ent:GetComponent("pfm_actor")
		if(util.is_same_object(actorC:GetActorData(),self)) then return ent end
	end
end

function fudm.PFMActor:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:GetSceneParent()
	if(parent == nil or parent.IsAbsoluteVisible == nil) then return true end
	return parent:IsAbsoluteVisible()
end
