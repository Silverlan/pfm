--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/udm/udm_scene_element.lua")

fudm.ELEMENT_TYPE_PFM_BONE = fudm.register_type("PFMBone",{fudm.PFMSceneElement},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_BONE,"transform",fudm.Transform())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_BONE,"childBones",fudm.Array(fudm.ELEMENT_TYPE_PFM_BONE))

function fudm.PFMBone:GetSceneChildren() return self:GetChildBones():GetTable() end

function fudm.PFMBone:GetModelComponent()
	local parent = self:FindParentElement(function(el) return el:GetType() == fudm.ELEMENT_TYPE_PFM_BONE or el:GetType() == fudm.ELEMENT_TYPE_PFM_MODEL end)
	if(parent == nil) then return end
	if(parent:GetType() == fudm.ELEMENT_TYPE_PFM_BONE) then return parent:GetModelComponent() end
	if(parent:GetType() == fudm.ELEMENT_TYPE_PFM_MODEL) then return parent end
end
