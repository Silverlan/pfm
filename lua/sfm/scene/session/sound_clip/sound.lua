--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Sound",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Sound,"soundname","")
sfm.BaseElement.RegisterAttribute(sfm.Sound,"gameSoundName","")
sfm.BaseElement.RegisterAttribute(sfm.Sound,"volume",1.0)
sfm.BaseElement.RegisterAttribute(sfm.Sound,"pitch",100)
sfm.BaseElement.RegisterAttribute(sfm.Sound,"origin",Vector())
sfm.BaseElement.RegisterAttribute(sfm.Sound,"direction",Vector())

function sfm.Sound:__init()
  sfm.BaseElement.__init(self,sfm.Sound)
end

function sfm.Sound:ToPFMSound(pfmSound)
	pfmSound:SetSoundName(self:GetSoundName())
	pfmSound:SetVolume(self:GetVolume())
	pfmSound:SetPitch(self:GetPitch() /100.0)
	pfmSound:SetOrigin(self:GetOrigin()) -- TODO: Convert coordinate system
	pfmSound:SetDirection(self:GetDirection()) -- TODO: Convert coordinate system
end
