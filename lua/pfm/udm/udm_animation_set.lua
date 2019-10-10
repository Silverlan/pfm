--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/udm/elements/udm_element.lua")
include("udm_model.lua")
include("udm_flex_control.lua")
include("udm_transform_control.lua")

udm.ELEMENT_TYPE_PFM_ANIMATION_SET = udm.register_element("PFMAnimationSet")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"flexControls",udm.Array(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"transformControls",udm.Array(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL))

function udm.PFMAnimationSet:AddFlexControl(name)
  local ctrl = self:CreateChild(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,name)
  self:GetFlexControls():PushBack(ctrl)
  return ctrl
end

function udm.PFMAnimationSet:AddTransformControl(name)
  local ctrl = self:CreateChild(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,name)
  self:GetTransformControls():PushBack(ctrl)
  return ctrl
end
