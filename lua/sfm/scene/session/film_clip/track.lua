util.register_class("sfm.Track",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.Track,"mute",false,"IsMuted")
sfm.BaseElement.RegisterAttribute(sfm.Track,"volume",1.0)

function sfm.Track:__init()
  sfm.BaseElement.__init(self,sfm.Track)
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
end

function sfm.Track:GetFilmClips() return self.m_filmClips end
function sfm.Track:GetSoundClips() return self.m_soundClips end
