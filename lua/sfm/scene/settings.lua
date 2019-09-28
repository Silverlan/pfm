include("time_selection.lua")

util.register_class("sfm.Settings",sfm.BaseElement)

sfm.BaseElement.RegisterProperty(sfm.Settings,"movieSettings",sfm.MovieSettings)
sfm.BaseElement.RegisterProperty(sfm.Settings,"timeSelection",sfm.TimeSelection)
sfm.BaseElement.RegisterProperty(sfm.Settings,"proceduralPresets",sfm.ProceduralPresets)
sfm.BaseElement.RegisterProperty(sfm.Settings,"renderSettings",sfm.RenderSettings)
sfm.BaseElement.RegisterProperty(sfm.Settings,"posterSettings",sfm.PosterSettings)
--sfm.BaseElement.RegisterProperty(sfm.Settings,"sharedPresetGroupSettings")
--sfm.BaseElement.RegisterProperty(sfm.Settings,"graphEditorState")

function sfm.Settings:__init()
  sfm.BaseElement.__init(self,sfm.Settings)
end
