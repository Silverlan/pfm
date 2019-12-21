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
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"aspectRatio",udm.Float(1.0))

function udm.PFMCamera:GetComponentName() return "pfm_camera" end
function udm.PFMCamera:GetIconMaterial() return "gui/pfm/icon_camera_item" end

function udm.PFMCamera:SetupControls(actorEditor,itemComponent)
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_field_of_view"),
		property = "fov",
		min = 10.0,
		max = 120.0,
		default = 30.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_focal_distance"),
		-- property = "", -- TODO
		min = 1.0,
		max = 200.0,
		default = 72.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_aperture"),
		-- property = "", -- TODO
		min = 0.0,
		max = 10.0,
		default = 0.2
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_near_z"),
		property = "zNear",
		min = 0.0,
		max = 1000.0,
		default = ents.CameraComponent.DEFAULT_NEAR_Z
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_far_z"),
		property = "zFar",
		min = 0.0,
		max = ents.CameraComponent.DEFAULT_FAR_Z,
		default = ents.CameraComponent.DEFAULT_FAR_Z
	})
end
