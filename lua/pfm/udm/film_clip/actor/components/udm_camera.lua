--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_CAMERA = udm.register_element("PFMCamera")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"fov",udm.Float(ents.CameraComponent.DEFAULT_FOV))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"zNear",udm.Float(ents.CameraComponent.DEFAULT_NEAR_Z))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"zFar",udm.Float(ents.CameraComponent.DEFAULT_FAR_Z))

function udm.PFMCamera:GetComponentName() return "pfm_camera" end
