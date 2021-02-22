--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")

fudm.ELEMENT_TYPE_PFM_CAMERA = fudm.register_type("PFMCamera",{fudm.PFMEntityComponent},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"fov",fudm.Float(ents.CameraComponent.DEFAULT_FOV))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"zNear",fudm.Float(ents.CameraComponent.DEFAULT_NEAR_Z))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"zFar",fudm.Float(ents.CameraComponent.DEFAULT_FAR_Z))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"aspectRatio",fudm.Float(1.0))

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"focalDistance",fudm.Float(72.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"fstop",fudm.Float(2.8),{
	getter = "GetFStop",
	setter = "SetFStop"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"apertureBokehRatio",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"apertureBladeCount",fudm.Int(0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"apertureBladesRotation",fudm.Float(0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"sensorSize",fudm.Float(36.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CAMERA,"depthOfFieldEnabled",fudm.Bool(false),{
	getter = "IsDepthOfFieldEnabled"
})

function fudm.PFMCamera:GetComponentName() return "pfm_camera" end
function fudm.PFMCamera:GetIconMaterial() return "gui/pfm/icon_camera_item" end

function fudm.PFMCamera:SetupControls(actorEditor,itemComponent)
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_field_of_view"),
		property = "fov",
		min = 10.0,
		max = 120.0,
		default = 30.0
	})

	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_enable_dof"),
		property = "depthOfFieldEnabled",
		min = 0,
		max = 1,
		default = 0,
		boolean = true
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_focal_distance"),
		property = "focalDistance",
		min = 1.0,
		max = 200.0,
		default = 72.0
	})
	actorEditor:AddControl(self,itemComponent,{
		-- F-Stop?
		name = locale.get_text("pfm_component_camera_aperture_fstop"),
		property = "fstop",
		min = 0.0,
		max = 10.0,
		default = 1.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_aperture_bokeh_ratio"),
		property = "apertureBokehRatio",
		min = 1.0,
		max = 2.0,
		default = 1.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_aperture_blade_count"),
		property = "apertureBladeCount",
		min = 0,
		max = 16,
		default = 0,
		integer = true
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_aperture_blades_rotation"),
		property = "apertureBladesRotation",
		min = -180,
		max = 180,
		default = 0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("pfm_component_camera_sensor_size"),
		property = "sensorSize",
		min = 1,
		max = 100,
		default = 36.0
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
