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
  pfmTransform:SetPosition(sfm.convert_source_position_to_pragma(self:GetPosition()))
  pfmTransform:SetRotation(sfm.convert_source_rotation_to_pragma(self:GetOrientation()))
end
