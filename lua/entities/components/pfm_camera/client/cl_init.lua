--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMCamera",BaseEntityComponent)

function ents.PFMCamera:Initialize()
	BaseEntityComponent.Initialize(self)

end
function ents.PFMCamera:Setup(cameraData)
	
end
ents.COMPONENT_PFM_CAMERA = ents.register_component("pfm_camera",ents.PFMCamera)
