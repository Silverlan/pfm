--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")

udm.ELEMENT_TYPE_PFM_CAMERA = udm.register_type("PFMCamera",{udm.PFMEntityComponent},true)
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"fov",udm.Float(ents.CameraComponent.DEFAULT_FOV))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"zNear",udm.Float(ents.CameraComponent.DEFAULT_NEAR_Z))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"zFar",udm.Float(ents.CameraComponent.DEFAULT_FAR_Z))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"aspectRatio",udm.Float(1.0))

udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"focalDistance",udm.Float(72.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"fstop",udm.Float(2.8),{
	getter = "GetFStop",
	setter = "SetFStop"
})
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"apertureBokehRatio",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"apertureBladeCount",udm.Int(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"apertureBladesRotation",udm.Float(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"sensorSize",udm.Float(36.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CAMERA,"depthOfFieldEnabled",udm.Bool(false),{
	getter = "IsDepthOfFieldEnabled"
})

function udm.PFMCamera:GetComponentName() return "pfm_camera" end
function udm.PFMCamera:GetIconMaterial() return "gui/pfm/icon_camera_item" end

function udm.PFMCamera:SetupControls(actorEditor,itemComponent)
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_field_of_view",
		property = "fov",
		min = 10.0,
		max = 120.0,
		default = 30.0
	})

	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_enable_dof",
		property = "depthOfFieldEnabled",
		min = 0,
		max = 1,
		default = 0,
		boolean = true
	})
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_focal_distance",
		property = "focalDistance",
		min = 1.0,
		max = 200.0,
		default = 72.0
	})
	actorEditor:AddControl(self,itemComponent,{
		-- F-Stop?
		name = "pfm_component_camera_aperture_fstop",
		property = "fstop",
		min = 0.0,
		max = 10.0,
		default = 1.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_aperture_bokeh_ratio",
		property = "apertureBokehRatio",
		min = 1.0,
		max = 2.0,
		default = 1.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_aperture_blade_count",
		property = "apertureBladeCount",
		min = 0,
		max = 16,
		default = 0,
		integer = true
	})
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_aperture_blades_rotation",
		property = "apertureBladesRotation",
		min = -180,
		max = 180,
		default = 0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_sensor_size",
		property = "sensorSize",
		min = 1,
		max = 100,
		default = 36.0
	})

	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_near_z",
		property = "zNear",
		min = 0.0,
		max = 1000.0,
		default = ents.CameraComponent.DEFAULT_NEAR_Z
	})
	actorEditor:AddControl(self,itemComponent,{
		name = "pfm_component_camera_far_z",
		property = "zFar",
		min = 0.0,
		max = ents.CameraComponent.DEFAULT_FAR_Z,
		default = ents.CameraComponent.DEFAULT_FAR_Z
	})
end
