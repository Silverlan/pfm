--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.Camera",sfm.BaseElement)
util.register_class("sfm.Transform",sfm.BaseElement) -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.Camera,"transform",sfm.Transform)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"fieldOfView",36.0)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"znear",3,"GetZNear")
sfm.BaseElement.RegisterAttribute(sfm.Camera,"zfar",28377.919921875,"GetZFar")
sfm.BaseElement.RegisterAttribute(sfm.Camera,"focalDistance",72)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"eyeSeparation",0.75)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"aperture",0.2)
sfm.BaseElement.RegisterAttribute(sfm.Camera,"shutterSpeed",0.0208)

function sfm.Camera:__init()
  sfm.BaseElement.__init(self,sfm.Camera)
end

function sfm.Camera:ToPFMCamera(pfmCamera)
  self:GetTransform():ToPFMTransform(pfmCamera:GetTransform())
end
