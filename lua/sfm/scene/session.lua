include("session")
include("settings.lua")

util.register_class("sfm.Session",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.Session,"settings",sfm.Settings)
sfm.BaseElement.RegisterArray(sfm.Session,"clipBin",sfm.FilmClip,"GetClips")

function sfm.Session:__init(elSession)
  sfm.BaseElement.__init(self,sfm.Session)
  self:Load(elSession)
end
