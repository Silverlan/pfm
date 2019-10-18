--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Track",sfm.BaseElement)

include("track")

sfm.BaseElement.RegisterAttribute(sfm.Track,"mute",false,"IsMuted")
sfm.BaseElement.RegisterAttribute(sfm.Track,"volume",1.0)

function sfm.Track:__init()
  sfm.BaseElement.__init(self,sfm.Track)
  self.m_channelClips = {}
  self.m_soundClips = {}
  self.m_filmClips = {}
end

function sfm.Track:Load(el)
  sfm.BaseElement.Load(self,el)
  
  for _,attrClip in ipairs(el:GetAttrV("children") or {}) do
    local elClip = attrClip:GetValue()
    local type = elClip:GetType()
    if(type == "DmeSoundClip") then
      local clip = sfm.SoundClip()
      clip:Load(elClip)
      table.insert(self.m_soundClips,clip)
    elseif(type == "DmeChannelsClip") then
      local clip = sfm.ChannelClip()
      clip:Load(elClip)
      table.insert(self.m_channelClips,clip)
    elseif(type == "DmeFilmClip") then
      local clip = sfm.FilmClip()
      clip:Load(elClip)
      table.insert(self.m_filmClips,clip)
    else
      pfm.log("Unsupported track child type '" .. type .. "' for track '" .. self:GetName() .. "'! Child will be ignored!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
    end
  end
end

function sfm.Track:GetChannelClips() return self.m_channelClips end
function sfm.Track:GetSoundClips() return self.m_soundClips end
function sfm.Track:GetFilmClips() return self.m_filmClips end

function sfm.Track:ToPFMTrack(pfmTrack)
  pfmTrack:SetMuted(self:IsMuted())
  pfmTrack:SetVolume(self:GetVolume())

  for _,clip in ipairs(self:GetFilmClips()) do
    local pfmClip = udm.PFMFilmClip(clip:GetName())
    clip:ToPFMFilmClip(pfmClip)
    pfmTrack:GetFilmClipsAttr():PushBack(pfmClip)
  end
  
  for _,clip in ipairs(self:GetSoundClips()) do
    local pfmClip = udm.PFMAudioClip(clip:GetName())
    clip:ToPFMAudioClip(pfmClip)
    pfmTrack:GetAudioClipsAttr():PushBack(pfmClip)
  end
  
  for _,clip in ipairs(self:GetChannelClips()) do
    local pfmClip = udm.PFMChannelClip(clip:GetName())
    clip:ToPFMChannelClip(pfmClip)
    pfmTrack:GetChannelClipsAttr():PushBack(pfmClip)
  end
end
