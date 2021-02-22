--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")

fudm.ELEMENT_TYPE_PFM_POINT_LIGHT = fudm.register_type("PFMPointLight",{fudm.PFMEntityComponent},true)

fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"color",fudm.Color(Color.White))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"intensity",fudm.Float(1000.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"intensityType",fudm.UInt8(ents.LightComponent.INTENSITY_TYPE_CANDELA))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"falloffExponent",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"maxDistance",fudm.Float(1000.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"castShadows",fudm.Bool(false),{
	getter = "ShouldCastShadows"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"volumetric",fudm.Bool(false),{
	getter = "IsVolumetric"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_POINT_LIGHT,"volumetricIntensity",fudm.Float(1.0))

function fudm.PFMPointLight:GetComponentName() return "pfm_light_point" end
function fudm.PFMPointLight:GetIconMaterial() return "gui/pfm/icon_light_item" end

function fudm.PFMPointLight:SetupControls(actorEditor,itemComponent)
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("intensity"),
		identifier = "intensity",
		property = "intensity",
		min = 0.0,
		max = 10000.0,
		default = 2000.0,
		unit = (self:GetIntensityType() == ents.LightComponent.INTENSITY_TYPE_CANDELA) and locale.get_text("symbol_candela") or locale.get_text("symbol_lumen")
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("light_unit"),
		addControl = function(ctrls)
			local menu,wrapper = ctrls:AddDropDownMenu(locale.get_text("intensity_unit"),"intensity_type",{
				{tostring(ents.LightComponent.INTENSITY_TYPE_CANDELA),locale.get_text("candela")},
				{tostring(ents.LightComponent.INTENSITY_TYPE_LUMEN),locale.get_text("lumen")}
			},0,function(menu,option)
				local type = tonumber(menu:GetOptionValue(option))
				if(type == self:GetIntensityType()) then return end
				local ctrlIntensity = ctrls:GetControl("intensity")
				local intensity = 0.0
				if(util.is_valid(ctrlIntensity)) then
					intensity = light.convert_light_intensity(ctrlIntensity:GetValue(),self:GetIntensityType(),type)
				end
				self:SetIntensityType(type)
				if(util.is_valid(ctrlIntensity)) then
					ctrlIntensity:SetValue(intensity)
					ctrlIntensity:SetUnit((type == ents.LightComponent.INTENSITY_TYPE_CANDELA) and locale.get_text("symbol_candela") or locale.get_text("symbol_lumen"))
				end
				actorEditor:TagRenderSceneAsDirty()
			end)
			menu:SelectOption(self:GetIntensityType())
			return wrapper
		end
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("radius"),
		property = "maxDistance",
		min = util.units_to_metres(0.0),
		max = util.units_to_metres(1000.0),
		default = util.units_to_metres(100.0),
		unit = locale.get_text("symbol_meters"),
		translateToInterface = function(val) return util.units_to_metres(val) end,
		translateFromInterface = function(val) return util.metres_to_units(val) end
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
	--[[actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("red"),
		get = function(light) return light:GetColor():ToVector4().x end,
		set = function(light,red)
			col = light:GetColor():ToVector4()
			col.x = red
			light:SetColor(Color(col))
		end,
		min = 0.0,
		max = 1.0,
		default = 1.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("green"),
		get = function(light) return light:GetColor():ToVector4().y end,
		set = function(light,green)
			col = light:GetColor():ToVector4()
			col.y = green
			light:SetColor(Color(col))
		end,
		min = 0.0,
		max = 1.0,
		default = 1.0
	})
	actorEditor:AddControl(self,itemComponent,{
		name = locale.get_text("blue"),
		get = function(light) return light:GetColor():ToVector4().z end,
		set = function(light,blue)
			col = light:GetColor():ToVector4()
			col.z = blue
			light:SetColor(Color(col))
		end,
		min = 0.0,
		max = 1.0,
		default = 1.0
	})]]
end
