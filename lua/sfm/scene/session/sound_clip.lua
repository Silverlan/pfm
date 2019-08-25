include("sound_clip")

util.register_class("sfm.SoundClip",sfm.BaseElement)
function sfm.SoundClip:__init()
  sfm.BaseElement.__init(self)
end

function sfm.SoundClip:GetType() return "DmeSoundClip" end

function sfm.SoundClip:Load(el)
  sfm.BaseElement.Load(self,el)
  
  self.m_sound = self:LoadProperty(el,"sound",sfm.Sound)
  self.m_timeFrame = self:LoadProperty(el,"timeFrame",sfm.TimeFrame)
end

function sfm.SoundClip:GetSound() return self.m_sound end
function sfm.SoundClip:GetTimeFrame() return self.m_timeFrame end

function sfm.SoundClip:ToPFMAudioClip(pfmAudioClip)
  self:GetSound():ToPFMSound(pfmAudioClip:GetSound())
  self:GetTimeFrame():ToPFMTimeFrame(pfmAudioClip:GetTimeFrame())
end
