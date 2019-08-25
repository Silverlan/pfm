include("film_clip")

util.register_class("sfm.FilmClip",sfm.BaseElement)
function sfm.FilmClip:__init()
  sfm.BaseElement.__init(self)
end

function sfm.FilmClip:GetType() return "DmeFilmClip" end

function sfm.FilmClip:Load(el)
  sfm.BaseElement.Load(self,el)
  self.m_mapName = self:LoadAttributeValue(el,"mapname","")
  self.m_trackGroups = self:LoadArray(el,"trackGroups",sfm.TrackGroup)
  self.m_subClipTrackGroup = self:LoadProperty(el,"subClipTrackGroup",sfm.SubClipTrackGroup)
  self.m_animationSets = self:LoadArray(el,"animationSets",sfm.AnimationSet)
  self.m_camera = self:LoadProperty(el,"camera",sfm.Camera)
  self.m_timeFrame = self:LoadProperty(el,"timeFrame",sfm.TimeFrame)
end

function sfm.FilmClip:GetMapName() return self.m_mapName end
function sfm.FilmClip:GetSubClipTrackGroup() return self.m_subClipTrackGroup end
function sfm.FilmClip:GetTrackGroups() return self.m_trackGroups end
function sfm.FilmClip:GetAnimationSets() return self.m_animationSets end
function sfm.FilmClip:GetCamera() return self.m_camera end
function sfm.FilmClip:GetTimeFrame() return self.m_timeFrame end
