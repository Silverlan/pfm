--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("animation_set")

udm.ELEMENT_TYPE_PFM_ANIMATION_SET = udm.register_element("PFMAnimationSet")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"flexControls",udm.Array(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"transformControls",udm.Array(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL))

function udm.PFMAnimationSet:AddFlexControl(flexControl)
	if(type(flexControl) == "string") then flexControl = self:CreateChild(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,flexControl) end
	self:GetFlexControlsAttr():PushBack(flexControl)
	return flexControl
end

function udm.PFMAnimationSet:AddTransformControl(transformControl)
	if(type(transformControl) == "string") then transformControl = self:CreateChild(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,transformControl) end
	self:GetTransformControlsAttr():PushBack(transformControl)
	return transformControl
end

function udm.PFMAnimationSet:GetComponentName() return "pfm_animation_set" end
function udm.PFMAnimationSet:GetIconMaterial() return "gui/pfm/icon_model_item" end
