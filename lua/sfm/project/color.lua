--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Color",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Color,"color",Color())

function sfm.Color:__init()
  sfm.BaseElement.__init(self,sfm.Color)
end

function sfm.Color:ToPFMTransform(pfmColor)
  pfmColor:SetValue(self:GetColor())
end
