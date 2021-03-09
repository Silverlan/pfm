--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")
include("animation_set")

fudm.ELEMENT_TYPE_PFM_ANIMATION_SET = fudm.register_type("PFMAnimationSet",{fudm.PFMEntityComponent},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ANIMATION_SET,"flexControls",fudm.Array(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_ANIMATION_SET,"transformControls",fudm.Array(fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL))

function fudm.PFMAnimationSet:AddFlexControl(flexControl)
	if(type(flexControl) == "string") then flexControl = self:CreateChild(fudm.ELEMENT_TYPE_PFM_FLEX_CONTROL,flexControl) end
	self:GetFlexControlsAttr():PushBack(flexControl)
	return flexControl
end

function fudm.PFMAnimationSet:AddTransformControl(transformControl)
	if(type(transformControl) == "string") then transformControl = self:CreateChild(fudm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,transformControl) end
	self:GetTransformControlsAttr():PushBack(transformControl)
	return transformControl
end

function fudm.PFMAnimationSet:GetComponentName() return "pfm_animation_set" end
function fudm.PFMAnimationSet:GetIconMaterial() return "gui/pfm/icon_model_item" end
