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
