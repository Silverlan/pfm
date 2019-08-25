util.register_class("sfm.Track",sfm.BaseElement)
function sfm.Track:__init()
  sfm.BaseElement.__init(self)
  self.m_filmClips = {}
  self.m_soundClips = {}
end

function sfm.Track:Load(el)
  sfm.BaseElement.Load(self,el)
  
  for _,attrClip in ipairs(el:GetAttrV("children") or {}) do
    local elClip = attrClip:GetValue()
    local type = elClip:GetType()
    if(type == "DmeFilmClip") then
      local clip = sfm.FilmClip()
      clip:Load(elClip)
      table.insert(self.m_filmClips,clip)
    elseif(type == "DmeSoundClip") then
      local clip = sfm.SoundClip()
      clip:Load(elClip)
      table.insert(self.m_soundClips,clip)
    end
  end
  self.m_bMuted = self:LoadAttributeValue(el,"mute",false)
  self.m_volume = self:LoadAttributeValue(el,"volume",1.0)
end

function sfm.Track:GetFilmClips() return self.m_filmClips end
function sfm.Track:GetSoundClips() return self.m_soundClips end
function sfm.Track:IsMuted() return self.m_bMuted end
function sfm.Track:GetVolume() return self.m_volume end
