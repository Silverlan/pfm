--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMLight",BaseEntityComponent)

function ents.PFMLight:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LIGHT)
	self:AddEntityComponent("pfm_actor")

	self.m_listeners = {}
end
function ents.PFMLight:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
end
function ents.PFMLight:Setup(actorData,lightData)
	local ent = self:GetEntity()
	local colorC = ent:GetComponent(ents.COMPONENT_COLOR)
	if(colorC ~= nil) then
		colorC:SetColor(lightData:GetColor())

		table.insert(self.m_listeners,lightData:GetColorAttr():AddChangeListener(function(newColor)
			if(colorC:IsValid()) then colorC:SetColor(newColor) end
		end))
	end

	local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
	if(lightC ~= nil) then
		lightC:SetLightIntensity(lightData:GetIntensity(),lightData:GetIntensityType())
		lightC:SetFalloffExponent(lightData:GetFalloffExponent())
		lightC:SetShadowType(lightData:ShouldCastShadows() and ents.LightComponent.SHADOW_TYPE_FULL or ents.LightComponent.SHADOW_TYPE_NONE)

		table.insert(self.m_listeners,lightData:GetIntensityAttr():AddChangeListener(function(newIntensity)
			if(lightC:IsValid()) then lightC:SetLightIntensity(newIntensity) end
		end))
		table.insert(self.m_listeners,lightData:GetIntensityTypeAttr():AddChangeListener(function(newIntensityType)
			if(lightC:IsValid()) then lightC:SetLightIntensityType(newIntensityType) end
		end))
	end

	local spotLightC = ent:GetComponent(ents.COMPONENT_LIGHT_SPOT)
	if(spotLightC ~= nil) then
		-- TODO (Also see volumetric light below)
		spotLightC:SetInnerCutoffAngle(lightData:GetInnerConeAngle() *0.5)
		spotLightC:SetOuterCutoffAngle(lightData:GetOuterConeAngle() *0.5)
		table.insert(self.m_listeners,lightData:GetInnerConeAngleAttr():AddChangeListener(function(newConeAngle)
			if(spotLightC:IsValid()) then spotLightC:SetInnerCutoffAngle(newConeAngle *0.5) end
		end))
		table.insert(self.m_listeners,lightData:GetOuterConeAngleAttr():AddChangeListener(function(newConeAngle)
			if(spotLightC:IsValid()) then spotLightC:SetOuterCutoffAngle(newConeAngle *0.5) end
		end))
	end

	local radiusC = ent:GetComponent(ents.COMPONENT_RADIUS)
	if(radiusC ~= nil) then
		radiusC:SetRadius(lightData:GetMaxDistance())

		table.insert(self.m_listeners,lightData:GetMaxDistanceAttr():AddChangeListener(function(newRadius)
			if(radiusC:IsValid()) then radiusC:SetRadius(newRadius) end
		end))
	end

	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then
		toggleC:TurnOn()
	end

	if(lightData:IsVolumetric()) then
		local spotVolC = ent:AddComponent(ents.COMPONENT_LIGHT_SPOT_VOLUME)
		ent:SetKeyValue("cone_angle","20") -- TODO: Half of inner cutoff angle
		local color = lightData:GetColor():Copy()
		color.a = lightData:GetVolumetricIntensity() *255.0
		ent:SetKeyValue("cone_color",tostring(color))
		ent:SetKeyValue("cone_height",tostring(lightData:GetMaxDistance()))
		ent:SetKeyValue("spawnflags","1024")
		ent:SetKeyValue("cone_start_offset","0.0")
		ent:SetKeyValue("spotlight_target",ent:GetName())

		--[[local entVol = ents.create("env_light_spot_vol")
		entVol:SetKeyValue("cone_angle","15")
		entVol:SetKeyValue("cone_color","355 355 300 5")
		entVol:SetKeyValue("cone_height","400")
		entVol:SetKeyValue("spawnflags","1024")
		entVol:SetKeyValue("cone_start_offset","10.0")
		entVol:SetKeyValue("spotlight_target",ent:GetName())
		entVol:Spawn()
		entVol:SetPose(ent:GetPose())
		ent:RemoveEntityOnRemoval(entVol)

		local attInfo = ents.AttachableComponent.AttachmentInfo()
		attInfo.flags =  ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME
		entVol:AddComponent(ents.COMPONENT_ATTACHABLE):AttachToEntity(ent,attInfo)]]
	end
end
ents.COMPONENT_PFM_LIGHT = ents.register_component("pfm_light",ents.PFMLight)
