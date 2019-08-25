util.register_class("sfm.Sound",sfm.BaseElement)
function sfm.Sound:__init()
  sfm.BaseElement.__init(self)
end

function sfm.Sound:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_soundName = self:LoadAttributeValue(el,"soundname","")
  self.m_gameSoundName = self:LoadAttributeValue(el,"gameSoundName","")
  self.m_volume = self:LoadAttributeValue(el,"volume",1.0)
  self.m_pitch = self:LoadAttributeValue(el,"pitch",100)
  self.m_origin = self:LoadAttributeValue(el,"origin",Vector())
  self.m_direction = self:LoadAttributeValue(el,"direction",Vector())
end

function sfm.Sound:GetSoundName() return self.m_soundName end
function sfm.Sound:GetGameSoundName() return self.m_gameSoundName end
function sfm.Sound:GetVolume() return self.m_volume end
function sfm.Sound:GetPitch() return self.m_pitch end
function sfm.Sound:GetOrigin() return self.m_origin end
function sfm.Sound:GetDirection() return self.m_direction end

function sfm.Sound:ToPFMSound(pfmSound)
	pfmSound:SetSoundName(self:GetSoundName())
	pfmSound:SetVolume(self:GetVolume())
	pfmSound:SetPitch(self:GetPitch() /100.0)
	pfmSound:SetOrigin(self:GetOrigin()) -- TODO: Convert coordinate system
	pfmSound:SetDirection(self:GetDirection()) -- TODO: Convert coordinate system
end
