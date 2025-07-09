-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("time_selection.lua")

sfm.register_element_type("Settings")

sfm.BaseElement.RegisterProperty(sfm.Settings, "movieSettings", sfm.MovieSettings)
sfm.BaseElement.RegisterProperty(sfm.Settings, "timeSelection", sfm.TimeSelection)
sfm.BaseElement.RegisterProperty(sfm.Settings, "proceduralPresets", sfm.ProceduralPresets)
sfm.BaseElement.RegisterProperty(sfm.Settings, "renderSettings", sfm.RenderSettings)
sfm.BaseElement.RegisterProperty(sfm.Settings, "posterSettings", sfm.PosterSettings)
--sfm.BaseElement.RegisterProperty(sfm.Settings,"sharedPresetGroupSettings")
--sfm.BaseElement.RegisterProperty(sfm.Settings,"graphEditorState")
