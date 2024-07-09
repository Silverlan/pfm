--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMLight", BaseEntityComponent)

function ents.PFMLight:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LIGHT)
	self:AddEntityComponent("pfm_actor")
	self:BindEvent(ents.PFMActorComponent.EVENT_ON_VISIBILITY_CHANGED, "OnVisibilityChanged")

	self.m_listeners = {}
end
function ents.PFMLight:OnVisibilityChanged(visible)
	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if toggleC ~= nil then
		toggleC:SetTurnedOn(visible)
	end
end
function ents.PFMLight:OnRemove()
	for _, cb in ipairs(self.m_listeners) do
		if cb:IsValid() then
			cb:Remove()
		end
	end
end
function ents.PFMLight:Setup(actorData, pfmLightData)
	local ent = self:GetEntity()

	local colorC = ent:GetComponent(ents.COMPONENT_COLOR)
	local colorData = actorData:FindComponent("color")
	if colorC ~= nil and colorData ~= nil then
		colorC:SetColor(colorData:GetMemberValue("color"))

		table.insert(
			self.m_listeners,
			colorData:AddChangeListener("color", function(c, newColor)
				if colorC:IsValid() then
					colorC:SetColor(newColor)
				end
			end)
		)
	end

	local lightC = ent:GetComponent(ents.COMPONENT_LIGHT)
	local lightData = actorData:FindComponent("light")
	if lightC ~= nil then
		lightC:SetLightIntensity(lightData:GetMemberValue("intensity"), lightData:GetMemberValue("intensityType"))
		-- lightC:SetFalloffExponent(lightData:GetMemberValue("falloffExponent"))
		lightC:SetShadowType(
			lightData:GetMemberValue("castShadows") and ents.LightComponent.SHADOW_TYPE_FULL
				or ents.LightComponent.SHADOW_TYPE_NONE
		)

		table.insert(
			self.m_listeners,
			lightData:AddChangeListener("intensity", function(c, newIntensity)
				if lightC:IsValid() then
					lightC:SetLightIntensity(newIntensity)
				end
			end)
		)
		table.insert(
			self.m_listeners,
			lightData:AddChangeListener("intensityType", function(c, newIntensityType)
				if lightC:IsValid() then
					lightC:SetLightIntensityType(newIntensityType)
				end
			end)
		)
	end

	local spotLightC = ent:GetComponent(ents.COMPONENT_LIGHT_SPOT)
	local spotLightData = actorData:FindComponent("light_spot")
	if spotLightC ~= nil and spotLightData ~= nil then
		-- TODO (Also see volumetric light below)
		spotLightC:SetBlendFraction(spotLightData:GetMemberValue("blendFraction"))
		spotLightC:SetOuterConeAngle(spotLightData:GetMemberValue("outerConeAngle"))
		table.insert(
			self.m_listeners,
			spotLightData:AddChangeListener("blendFraction", function(c, newConeAngle)
				if spotLightC:IsValid() then
					spotLightC:SetBlendFraction(newConeAngle)
				end
			end)
		)
		table.insert(
			self.m_listeners,
			spotLightData:AddChangeListener("outerConeAngle", function(c, newConeAngle)
				if spotLightC:IsValid() then
					spotLightC:SetOuterConeAngle(newConeAngle)
				end
			end)
		)
	end

	local radiusC = ent:GetComponent(ents.COMPONENT_RADIUS)
	local radiusData = actorData:FindComponent("radius")
	if radiusC ~= nil and radiusData ~= nil then
		radiusC:SetRadius(radiusData:GetMemberValue("radius"))

		table.insert(
			self.m_listeners,
			radiusData:AddChangeListener("radius", function(c, newRadius)
				if radiusC:IsValid() then
					radiusC:SetRadius(newRadius)
				end
			end)
		)
	end

	local toggleC = ent:GetComponent(ents.COMPONENT_TOGGLE)
	if toggleC ~= nil then
		toggleC:TurnOn()
	end

	-- if(pfmLightData:IsVolumetric()) then
	-- TODO
	--[[local spotVolC = ent:AddComponent(ents.COMPONENT_LIGHT_SPOT_VOLUME)
		ent:SetKeyValue("cone_angle","20") -- TODO: Half of inner cutoff angle
		local color = lightData:GetColor():Copy()
		color.a = lightData:GetVolumetricIntensity() *255.0
		ent:SetKeyValue("cone_color",tostring(color))
		ent:SetKeyValue("cone_height",tostring(lightData:GetMaxDistance()))
		ent:SetKeyValue("spawnflags","1024")
		ent:SetKeyValue("cone_start_offset","0.0")
		ent:SetKeyValue("spotlight_target",ent:GetName())]]

	--[[local entVol = self:GetEntity():CreateChild("env_light_spot_vol")
		entVol:SetKeyValue("cone_angle","15")
		entVol:SetKeyValue("cone_color","355 355 300 5")
		entVol:SetKeyValue("cone_height","400")
		entVol:SetKeyValue("spawnflags","1024")
		entVol:SetKeyValue("cone_start_offset","10.0")
		entVol:SetKeyValue("spotlight_target",ent:GetName())
		entVol:Spawn()
		entVol:SetPose(ent:GetPose())
		ent:RemoveEntityOnRemoval(entVol)

		local attInfo = ents.AttachmentComponent.AttachmentInfo()
		attInfo.flags =  ents.AttachmentComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME
		entVol:AddComponent(ents.COMPONENT_ATTACHMENT):AttachToEntity(ent,attInfo)]]
	-- end
end
ents.COMPONENT_PFM_LIGHT = ents.register_component("pfm_light", ents.PFMLight)
