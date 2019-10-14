--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMLightSpot",BaseEntityComponent)

function ents.PFMLightSpot:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LIGHT)
	self:AddEntityComponent(ents.COMPONENT_LIGHT_SPOT)
	self:AddEntityComponent("pfm_actor")
end
function ents.PFMLightSpot:Setup(actorData,lightData)
	local lightC = self:GetEntity():GetComponent(ents.COMPONENT_LIGHT)
	if(lightC ~= nil) then
		lightC:SetLightIntensity(lightData:GetIntensity(),lightData:GetIntensityType())
		lightC:SetFalloffExponent(lightData:GetFalloffExponent())
	end

	local spotLightC = self:GetEntity():GetComponent(ents.COMPONENT_LIGHT_SPOT)
	if(spotLightC ~= nil) then
		-- TODO
		spotLightC:SetInnerCutoffAngle(40.0)
		spotLightC:SetOuterCutoffAngle(50.0)
	end

	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then
		toggleC:TurnOn()
	end
end
ents.COMPONENT_PFM_LIGHT_SPOT = ents.register_component("pfm_light_spot",ents.PFMLightSpot)
