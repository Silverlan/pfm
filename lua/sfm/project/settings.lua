--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("time_selection.lua")

sfm.register_element_type("Settings")

sfm.BaseElement.RegisterProperty(sfm.Settings,"movieSettings",sfm.MovieSettings)
sfm.BaseElement.RegisterProperty(sfm.Settings,"timeSelection",sfm.TimeSelection)
sfm.BaseElement.RegisterProperty(sfm.Settings,"proceduralPresets",sfm.ProceduralPresets)
sfm.BaseElement.RegisterProperty(sfm.Settings,"renderSettings",sfm.RenderSettings)
sfm.BaseElement.RegisterProperty(sfm.Settings,"posterSettings",sfm.PosterSettings)
--sfm.BaseElement.RegisterProperty(sfm.Settings,"sharedPresetGroupSettings")
--sfm.BaseElement.RegisterProperty(sfm.Settings,"graphEditorState")
