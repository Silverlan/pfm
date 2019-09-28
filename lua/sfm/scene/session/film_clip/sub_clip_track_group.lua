include("track.lua")

util.register_class("sfm.SubClipTrackGroup",sfm.BaseElement)

sfm.BaseElement.RegisterArray(sfm.SubClipTrackGroup,"tracks",sfm.Track)

function sfm.SubClipTrackGroup:__init()
  sfm.BaseElement.__init(self,sfm.SubClipTrackGroup)
end
