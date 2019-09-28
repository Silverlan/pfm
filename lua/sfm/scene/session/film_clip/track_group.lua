include("track.lua")

util.register_class("sfm.TrackGroup",sfm.BaseElement)

sfm.BaseElement.RegisterArray(sfm.TrackGroup,"tracks",sfm.Track)

function sfm.TrackGroup:__init()
  sfm.BaseElement.__init(self,sfm.TrackGroup)
end
