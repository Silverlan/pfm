util.register_class("sfm.SubClipTrackGroup",sfm.BaseElement)
function sfm.SubClipTrackGroup:__init()
  sfm.BaseElement.__init(self)
  self.m_tracks = {}
end

function sfm.SubClipTrackGroup:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_tracks = self:LoadArray(el,"tracks",sfm.Track)
end

function sfm.SubClipTrackGroup:GetTracks() return self.m_tracks end
