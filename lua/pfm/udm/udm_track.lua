--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/udm/elements/udm_element.lua")
include("udm_audio_clip.lua")

udm.ELEMENT_TYPE_PFM_TRACK = udm.register_element("PFMTrack")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"audioClips",udm.Array(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"filmClips",udm.Array(udm.ELEMENT_TYPE_PFM_FILM_CLIP))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"muted",udm.Bool(false))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_TRACK,"volume",udm.Float(1.0))
function udm.PFMTrack:AddAudioClip(name)
  local clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_AUDIO_CLIP,name)
  self:GetAudioClips():PushBack(clip)
  return clip
end
function udm.PFMTrack:AddFilmClip(name)
  local clip = self:CreateChild(udm.ELEMENT_TYPE_PFM_FILM_CLIP,name)
  self:GetFilmClips():PushBack(clip)
  return clip
end
