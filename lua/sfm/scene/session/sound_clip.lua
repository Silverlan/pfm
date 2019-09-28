include("sound_clip")
include("time_frame.lua")

util.register_class("sfm.SoundClip",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.SoundClip,"sound",sfm.Sound)
sfm.BaseElement.RegisterProperty(sfm.SoundClip,"timeFrame",sfm.TimeFrame)

function sfm.SoundClip:__init()
  sfm.BaseElement.__init(self,sfm.SoundClip)
end

function sfm.SoundClip:GetType() return "DmeSoundClip" end

function sfm.SoundClip:ToPFMAudioClip(pfmAudioClip)
  self:GetSound():ToPFMSound(pfmAudioClip:GetSound())
  self:GetTimeFrame():ToPFMTimeFrame(pfmAudioClip:GetTimeFrame())
end
