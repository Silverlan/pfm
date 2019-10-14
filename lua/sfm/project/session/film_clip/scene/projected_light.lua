--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("sfm.ProjectedLight",sfm.BaseElement)

sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"color",sfm.Color())
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"intensity",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"constantAttenuation",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"linearAttenuation",0.0)
sfm.BaseElement.RegisterAttribute(sfm.ProjectedLight,"quadraticAttenuation",0.0)

function sfm.ProjectedLight:__init()
  sfm.BaseElement.__init(self,sfm.ProjectedLight)
end

function sfm.ProjectedLight:ToPFMLight(pfmLightSource)
	-- TODO
	pfmLightSource:SetColor(Color.Red)--self:GetColor())
	pfmLightSource:SetIntensity(2000.0)--self:GetIntensity())
	pfmLightSource:SetIntensityType(ents.LightComponent.INTENSITY_TYPE_CANDELA)
	pfmLightSource:SetFalloffExponent(1.0)
end
