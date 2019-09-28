include("/udm/elements/udm_element.lua")
include("udm_model.lua")
include("udm_flex_control.lua")
include("udm_transform_control.lua")

udm.ELEMENT_TYPE_PFM_ANIMATION_SET = udm.register_element("PFMAnimationSet")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"model",udm.PFMModel())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"flexControls",udm.Array(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_ANIMATION_SET,"boneControls",udm.Array(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL))

function udm.PFMAnimationSet:AddFlexControl(name)
  local ctrl = self:CreateChild(udm.ELEMENT_TYPE_PFM_FLEX_CONTROL,name)
  self:GetFlexControls():PushBack(ctrl)
  return ctrl
end

function udm.PFMAnimationSet:AddTransformControl(name)
  local ctrl = self:CreateChild(udm.ELEMENT_TYPE_PFM_TRANSFORM_CONTROL,name)
  self:GetBoneControls():PushBack(ctrl)
  return ctrl
end
