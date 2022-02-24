--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.Actor:FindEntity()
    for ent in ents.iterator({ents.IteratorFilterComponent(ents.COMPONENT_PFM_ACTOR)}) do
        local actorC = ent:GetComponent(ents.COMPONENT_PFM_ACTOR)
        if(util.is_same_object(actorC:GetActorData(),self)) then return ent end
    end
end

function pfm.udm.Actor:FindComponent(name)
    for _,component in ipairs(self:GetComponents()) do
        if(component:GetType() == name) then return component end
    end
end

function pfm.udm.Actor:HasComponent(name)
    if(type(name) == "string") then return self:FindComponent(name) ~= nil end
    for _,component in ipairs(self:GetComponents()) do
        if(util.is_same_object(name,component)) then return true end
    end
    return false
end

function pfm.udm.Actor:AddComponentType(componentType)
    local component = self:AddComponent()
    component:SetType(componentType)

    local componentName = component:GetType() .. "_component"
    local componentIndex = 1
    while(self:FindComponent(componentName .. componentIndex) ~= nil) do componentIndex = componentIndex +1 end
    component:SetName((componentIndex == 1) and componentName or (componentName .. componentIndex))
    return component
end

function pfm.udm.Actor:ChangeModel(mdlName)
    mdlName = asset.normalize_asset_name(mdlName,asset.TYPE_MODEL)
    local mdlC = self:FindComponent("model") or self:AddComponentType("model")
    -- TODO: Clear animation data for this actor?
    debug.start_profiling_task("pfm_load_model")
    local mdl = game.load_model(mdlName)
    debug.stop_profiling_task()
    mdlC:SetMemberValue("model",udm.TYPE_STRING,mdlName)
end

function pfm.udm.Actor:GetAbsolutePose(filter)
    local pose = self:GetTransform()
    local parent = self:GetParent()
    if(parent.TypeName ~= "Group") then return pose end
    return parent:GetAbsolutePose() *pose
end

function pfm.udm.Actor:IsAbsoluteVisible()
    if(self:IsVisible() == false) then return false end
    local parent = self:GetParent()
    if(parent.TypeName ~= "Group") then return true end
    return parent:IsAbsoluteVisible()
end
