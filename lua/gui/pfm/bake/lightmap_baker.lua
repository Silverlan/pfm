--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")
include("uv_atlas_mesh_overlay.lua")

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
		local lightmapC = ent:GetComponent(ents.COMPONENT_LIGHT_MAP)
		if(lightmapC == nil) then return end

		--local matPath = util.Path.CreateFilePath(reflC:GetIBLMaterialFilePath())
		--matPath:PopFront()

		local el = gui.create("WITexturedRect",contents)
		--local mat = game.load_material(matPath:GetString())
		--if(util.is_valid(mat)) then
			local elTexSelection
			local wrapper
			local options = {
				{tostring(ents.LightMapComponent.TEXTURE_DIFFUSE),"Diffuse Lightmap"},
				{tostring(ents.LightMapComponent.TEXTURE_DIFFUSE_DIRECT),"Diffuse Direct Lightmap"},
				{tostring(ents.LightMapComponent.TEXTURE_DIFFUSE_INDIRECT),"Diffuse Indirect Lightmap"},
				{tostring(ents.LightMapComponent.TEXTURE_DOMINANT_DIRECTION),"Dominant Direction Lightmap"}
			}
			local selectedOption
			for i=#options,1,-1 do
				local option = options[i]
				local id = option[1]
				local tex = lightmapC:GetLightmapTexture(tonumber(id))
				if(tex == nil) then table.remove(options,i)
				else
					selectedOption = id
					option[2] = option[2] .. " (" .. tex:GetWidth() .. "x" .. tex:GetHeight() .. ")"
				end
			end
			elTexSelection,wrapper = controls:AddDropDownMenu("Lightmap Atlas","view_lightmap",options,selectedOption or "0",function()
				if(lightmapC:IsValid() == false) then return end
				local val = toint(elTexSelection:GetOptionValue(elTexSelection:GetSelectedOption()))
				local tex = lightmapC:GetLightmapTexture(val)
				if(tex == nil) then
					el:ClearTexture()
					return
				end
				el:SetTexture(tex)
			end)
			elTexSelection:SelectOption(tonumber(selectedOption))

			options = {}
			for ent,c in ents.citerator(ents.COMPONENT_LIGHT_MAP_RECEIVER) do
				table.insert(options,{
					tostring(ent:GetUuid()),ent:GetName()
				})
			end
			local elActorSelection
			local elOverlay
			elActorSelection,wrapper = controls:AddDropDownMenu("Actor","actor",options,"",function()
				local uuid = elActorSelection:GetOptionValue(elActorSelection:GetSelectedOption())
				local ent = ents.find_by_uuid(uuid)
				if(util.is_valid(ent) == false) then return end
				if(util.is_valid(elOverlay) == false) then
					elOverlay = gui.create("WIUVAtlasMeshOverlay",el,0,0,el:GetWidth(),el:GetHeight(),0,0,1,1)
				end
				elOverlay:SetEntity(ent)

				local c = lightmapC:GetEntity():GetComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
				if(c ~= nil) then
					elOverlay:SetLightmapCache(c:GetLightMapDataCache())
					elOverlay:Update()
				end
			end)
			wrapper:SetUseAltMode(true)
		--end

		local w = contents:GetWidth()
		local h = contents:GetHeight()
		el:SetSize(w,h)

		if(onInit ~= nil) then onInit(windowHandle,contents,controls) end
	end)
end

util.register_class("WILightmapBaker",WIBaseBaker)
function WILightmapBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_lightmaps"))
	self.m_jobs = {}
end
function WILightmapBaker:Reset()
	self:SetText(locale.get_text("pfm_bake_lightmaps"))
end
function WILightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	if(bakedLightingC:IsLightmapUvRebuildRequired()) then
		pfm.log("Lightmap UV data cache is out of date, rebuilding...",pfm.LOG_CATEGORY_PFM_BAKE)
		bakedLightingC:GenerateLightmapUvs()
	end
	local lmMode = bakedLightingC:GetLightmapMode()
	if(lmMode == ents.PFMBakedLighting.LIGHTMAP_MODE_DIRECTIONAL) then
		pfm.log("Directional lightmap atlas is out of date, rebuilding...",pfm.LOG_CATEGORY_PFM_BAKE)
		local job = bakedLightingC:GenerateDirectionalLightmaps()
		if(job == nil) then return end
		table.insert(self.m_jobs,job)
	end
	local job = bakedLightingC:GenerateLightmaps()
	table.insert(self.m_jobs,job)
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
function WILightmapBaker:PollBaker()
	for _,job in ipairs(self.m_jobs) do job:Poll() end
end
function WILightmapBaker:IsBakerComplete()
	for _,job in ipairs(self.m_jobs) do
		if(job:IsComplete() == false) then return false end
	end
	return true
end
function WILightmapBaker:IsBakerSuccessful()
	for _,job in ipairs(self.m_jobs) do
		if(job:IsSuccessful() == false) then return false end
	end
	return true
end
function WILightmapBaker:GetBakerProgress()
	local progress = 0.0
	for _,job in ipairs(self.m_jobs) do
		progress = progress +job:GetProgress()
	end
	progress = progress /#self.m_jobs
	return progress
end
function WILightmapBaker:FinalizeBaker() return true end

function WILightmapBaker:OnComplete()
	if(self:IsBakerSuccessful()) then
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("green"))
		self:OpenWindow("Lightmap Atlas View")
	else
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self:SetText(locale.get_text("pfm_bake_lightmaps"))
end
gui.register("WILightmapBaker",WILightmapBaker)

--------------------------------

pfm.util.open_directional_lightmap_atlas_view_window = function(ent,onInit)
	pfm.util.open_simple_window("Directional Lightmap Atlas View",function(windowHandle,contents,controls)
		if(ent:IsValid() == false) then return end

		local el = gui.create("WITexturedRect",contents,0,0,contents:GetWidth(),contents:GetHeight(),0,0,1,1)
		if(util.is_valid(ent) == false) then return end
		local lightmapC = ent:AddComponent(ents.COMPONENT_LIGHT_MAP)
		if(lightmapC == nil) then return end
		local tex = lightmapC:GetDirectionalLightmapAtlas()
		if(tex == nil) then return end
		el:SetTexture(tex)

		if(onInit ~= nil) then onInit(windowHandle,contents,controls) end
	end)
end

util.register_class("WIDirectionalLightmapBaker",WIBaseBaker)
function WIDirectionalLightmapBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_directional_lightmaps"))
end
function WIDirectionalLightmapBaker:Reset()
	self:SetText(locale.get_text("pfm_bake_directional_lightmaps"))
end
function WIDirectionalLightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	self.m_lightmapJob = bakedLightingC:GenerateDirectionalLightmaps()
end
function WIDirectionalLightmapBaker:CancelBaker()
	self:SetText(locale.get_text("pfm_baked_directional_lighting"))
end
function WIDirectionalLightmapBaker:OpenWindow(windowHandle,contents,controls)
	WIBaseBaker.OpenWindow(self,title)
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	pfm.util.open_directional_lightmap_atlas_view_window(ent,function(windowHandle,contents,controls)
		if(self:IsValid() == false) then return end
		self.m_viewWindow = windowHandle
	end)
end
function WIDirectionalLightmapBaker:PollBaker() self.m_lightmapJob:Poll() end
function WIDirectionalLightmapBaker:IsBakerComplete() return self.m_lightmapJob:IsComplete() end
function WIDirectionalLightmapBaker:IsBakerSuccessful() return self.m_lightmapJob:IsSuccessful() end
function WIDirectionalLightmapBaker:GetBakerProgress() return self.m_lightmapJob:GetProgress() end
function WIDirectionalLightmapBaker:FinalizeBaker() return true end

function WIDirectionalLightmapBaker:OnComplete()
	if(self.m_lightmapJob:IsSuccessful()) then
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("green"))
		self:OpenWindow("Directional lightmap Atlas View")
	else
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self:SetText(locale.get_text("pfm_bake_directional_lightmaps"))
end
gui.register("WIDirectionalLightmapBaker",WIDirectionalLightmapBaker)
