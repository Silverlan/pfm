--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")

util.register_class("WILightmapUvBaker",WIBaseBaker)
function WILightmapUvBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_lightmap_uvs"))
end
function WIBaseBaker:Reset()
	self:SetText(locale.get_text("pfm_bake_lightmap_uvs"))
end
function WILightmapUvBaker:StartBaker()
	local ent = self:GetActorEntity()
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	bakedLightingC:GenerateLightmapUvs()
end
function WILightmapUvBaker:CancelBaker()
	self:SetText(locale.get_text("pfm_baked_lighting"))
end
function WILightmapUvBaker:PollBaker() end
function WILightmapUvBaker:IsBakerComplete() return true end
function WILightmapUvBaker:IsBakerSuccessful() return true end
function WILightmapUvBaker:GetBakerProgress() return 1.0 end
function WILightmapUvBaker:FinalizeBaker() return true end

function WILightmapUvBaker:OnComplete()
	self:SetText(locale.get_text("pfm_bake_lightmap_uvs"))
end
gui.register("WILightmapUvBaker",WILightmapUvBaker)

--------------------------------

pfm = pfm or {}
pfm.util = pfm.util or {}

pfm.util.open_lightmap_atlas_view_window = function(ent,onInit)
	pfm.util.open_simple_window("Lightmap Atlas View",function(windowHandle,contents,controls)
		if(ent:IsValid() == false) then return end

		local el = gui.create("WITexturedRect",contents,0,0,contents:GetWidth(),contents:GetHeight(),0,0,1,1)
		if(util.is_valid(ent) == false) then return end
		local lightmapC = ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
		if(lightmapC == nil) then return end
		local tex = lightmapC:GetLightmapAtlas()
		if(tex == nil) then return end
		el:SetTexture(tex)

		if(onInit ~= nil) then onInit(windowHandle,contents,controls) end
	end)
end

util.register_class("WILightmapBaker",WIBaseBaker)
function WILightmapBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_lightmaps"))
end
function WIBaseBaker:Reset()
	self:SetText(locale.get_text("pfm_bake_lightmaps"))
end
function WILightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	self.m_lightmapJob = bakedLightingC:GenerateLightmaps()
end
function WILightmapBaker:CancelBaker()
	self:SetText(locale.get_text("pfm_baked_lighting"))
end
function WILightmapBaker:OpenWindow(windowHandle,contents,controls)
	WIBaseBaker.OpenWindow(self,title)
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	pfm.util.open_lightmap_atlas_view_window(ent,function(windowHandle,contents,controls)
		if(self:IsValid() == false) then return end
		self.m_viewWindow = windowHandle
	end)
end
function WILightmapBaker:PollBaker() self.m_lightmapJob:Poll() end
function WILightmapBaker:IsBakerComplete() return self.m_lightmapJob:IsComplete() end
function WILightmapBaker:IsBakerSuccessful() return self.m_lightmapJob:IsSuccessful() end
function WILightmapBaker:GetBakerProgress() return self.m_lightmapJob:GetProgress() end
function WILightmapBaker:FinalizeBaker() return true end

function WILightmapBaker:OnComplete()
	if(self.m_lightmapJob:IsSuccessful()) then
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("green"))
		self:OpenWindow("Lightmap Atlas View")
	else
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self:SetText(locale.get_text("pfm_bake_lightmaps"))
end
gui.register("WILightmapBaker",WILightmapBaker)
