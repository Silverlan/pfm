--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.TimeFrame",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"start",0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"duration",0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"offset",0.0)
sfm.BaseElement.RegisterAttribute(sfm.TimeFrame,"scale",1.0)

function sfm.TimeFrame:__init()
  sfm.BaseElement.__init(self,sfm.TimeFrame)
end

function sfm.TimeFrame:ToPFMTimeFrame(pfmTimeFrame)
	pfmTimeFrame:SetStart(self:GetStart())
	pfmTimeFrame:SetDuration(self:GetDuration())
end
