--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Camera",sfm.BaseElement)
util.register_class("sfm.Transform",sfm.BaseElement) -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.Camera,"transform",sfm.Transform)

function sfm.Camera:__init()
  sfm.BaseElement.__init(self,sfm.Camera)
end
