util.register_class("sfm.TrackGroup",sfm.BaseElement)
function sfm.TrackGroup:__init()
  sfm.BaseElement.__init(self)
  self.m_tracks = {}
end

function sfm.TrackGroup:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_tracks = self:LoadArray(el,"tracks",sfm.Track)
end

function sfm.TrackGroup:GetTracks() return self.m_tracks end
