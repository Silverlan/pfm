--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/bake/lightmaps.lua")

local Component = util.register_class("ents.PFMBakedLighting", BaseEntityComponent)

Component:RegisterMember("LightmapMode", udm.TYPE_UINT32, 1, {
	enumValues = {
		["NonDirectional"] = 0,
		["Directional"] = 1,
	},
	onChange = function(self)
		local bakerC = self:GetEntityComponent(ents.COMPONENT_LIGHTMAP_BAKER)
		if bakerC ~= nil then
			bakerC:SetLightmapMode(self:GetLightmapMode())
		end
	end,
})
-- Debug mode
Component:RegisterMember("Resolution", udm.TYPE_STRING, "2048x2048", {
	onChange = function(self)
		local bakerC = self:GetEntityComponent(ents.COMPONENT_LIGHTMAP_BAKER)
		if bakerC ~= nil then
			local width = 512
			local height = 512
			local resolution = string.split(self:GetResolution(), "x")
			if resolution[1] ~= nil then
				width = tonumber(resolution[1]) or 0
			end
			if resolution[2] ~= nil then
				height = tonumber(resolution[2]) or 0
			end
			bakerC:SetWidth(width)
			bakerC:SetHeight(height)
		end
	end,
})
Component:RegisterMember("SampleCount", udm.TYPE_UINT32, 20000, {
	onChange = function(self)
		local bakerC = self:GetEntityComponent(ents.COMPONENT_LIGHTMAP_BAKER)
		if bakerC ~= nil then
			bakerC:SetSampleCount(self:GetSampleCount())
		end
	end,
})
Component:RegisterMember("LightIntensityFactor", udm.TYPE_FLOAT, 1.0, {
	min = 0,
	max = 10,
	onChange = function(self)
		local bakerC = self:GetEntityComponent(ents.COMPONENT_LIGHTMAP_BAKER)
		if bakerC ~= nil then
			bakerC:SetLightIntensityFactor(self:GetLightIntensityFactor())
		end
	end,
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	local bakerC = self:AddEntityComponent("lightmap_baker")
	local pm = pfm.get_project_manager()
	local session = pm:GetProject():GetSession()
	local uuid = tostring(session:GetUniqueId())
	bakerC:SetLightmapUuid(uuid)

	self:BindEvent(ents.LightmapBaker.EVENT_UPDATE_LIGHTMAP_TARGETS, "UpdateLightmapTargets")
	self:BindEvent(ents.LightmapBaker.EVENT_ON_LIGHTMAP_MATERIAL_CHANGED, "OnLightmapMaterialChanged")
	self:BindEvent(ents.LightmapBaker.EVENT_ON_LIGHTMAP_DATA_CACHE_CHANGED, "OnLightmapDataCacheChanged")
end
function Component:UpdateLightmapTargets()
	local bakerC = self:GetEntity():GetComponent(ents.COMPONENT_LIGHTMAP_BAKER)
	local bakeEntities = pfm.bake.find_bake_entities()
	local lightSources = pfm.bake.find_bake_light_sources()
	bakerC:SetLightSources(lightSources)
	bakerC:SetLightmapReceivers(bakeEntities)
	bakerC:SetLightmapInfluencers({})
	return util.EVENT_REPLY_HANDLED
end
function Component:OnLightmapMaterialChanged(lmMat)
	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		local pm = pfm.get_project_manager()
		pm:SetActorGenericProperty(actorC, "ec/light_map/lightmapMaterial", lmMat, udm.TYPE_STRING)
	end
end
function Component:OnLightmapDataCacheChanged(cachePath)
	local actorC = self:GetEntityComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC ~= nil then
		local pm = pfm.get_project_manager()
		pm:SetActorGenericProperty(actorC, "ec/light_map_data_cache/lightmapDataCache", cachePath, udm.TYPE_STRING)
	end
end
ents.COMPONENT_PFM_BAKED_LIGHTING = ents.register_component("pfm_baked_lighting", Component)
