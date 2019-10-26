--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Transform",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Transform,"position",Vector())
sfm.BaseElement.RegisterAttribute(sfm.Transform,"orientation",Quaternion())

function sfm.Transform:__init()
  sfm.BaseElement.__init(self,sfm.Transform)
end

function sfm.Transform:ToPFMTransform(pfmTransform)
  pfmTransform:SetName(self:GetName())
  pfmTransform:SetPosition(sfm.convert_source_position_to_pragma(self:GetPosition()))
  pfmTransform:SetRotation(sfm.convert_source_rotation_to_pragma(self:GetOrientation()))
end

function sfm.Transform:ToPFMTransformGlobal(pfmTransform)
  pfmTransform:SetName(self:GetName())
  pfmTransform:SetPosition(sfm.convert_source_position_to_pragma(self:GetPosition()))
  pfmTransform:SetRotation(sfm.convert_source_global_rotation_to_pragma(self:GetOrientation()))
end

function sfm.Transform:ToPFMTransformBone(pfmTransform)
  pfmTransform:SetName(self:GetName())
  pfmTransform:SetPosition(sfm.convert_source_anim_set_position_to_pragma(self:GetPosition()))
  pfmTransform:SetRotation(sfm.convert_source_anim_set_rotation_to_pragma(self:GetOrientation()))
end

-- Some transforms are in a different coordinate system for some reason, so we need a different conversion
function sfm.Transform:ToPFMTransformAlt(pfmTransform)
  pfmTransform:SetName(self:GetName())
  pfmTransform:SetPosition(sfm.convert_source_transform_position_to_pragma(self:GetPosition()))
  pfmTransform:SetRotation(sfm.convert_source_transform_rotation_to_pragma(self:GetOrientation()))
end
