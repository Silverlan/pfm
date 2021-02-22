--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")

fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT = fudm.register_type("PFMDirectionalLight",{fudm.PFMEntityComponent},true)

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"color",fudm.Color(Color.White))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"intensity",fudm.Float(1000.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"intensityType",fudm.UInt8(ents.LightComponent.INTENSITY_TYPE_LUX))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"falloffExponent",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"maxDistance",fudm.Float(1000.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"castShadows",fudm.Bool(false),{
	getter = "ShouldCastShadows"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"volumetric",fudm.Bool(false),{
	getter = "IsVolumetric"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_DIRECTIONAL_LIGHT,"volumetricIntensity",fudm.Float(1.0))

function fudm.PFMDirectionalLight:GetComponentName() return "pfm_light_directional" end
function fudm.PFMDirectionalLight:GetIconMaterial() return "gui/pfm/icon_light_item" end

function fudm.PFMDirectionalLight:SetupControls(actorEditor,itemComponent)
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("intensity"),
		property = "intensity",
		min = 0.0,
		max = 10000.0,
		default = 2000.0,
		unit = locale.get_text("symbol_lux")
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("color"),
		addControl = function(ctrls)
			local colField,wrapper = ctrls:AddColorField(locale.get_text("color"),"color",self:GetColor(),function(oldCol,newCol)
				self:SetColor(newCol)
				actorEditor:TagRenderSceneAsDirty()
			end)
			return wrapper
		end
	})
end
