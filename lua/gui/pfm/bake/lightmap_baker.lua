--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")
include("/debug/lightmaps.lua")

local UvBaker = util.register_class("pfm.UvBaker", pfm.BaseBaker)
function UvBaker:__init()
	pfm.BaseBaker.__init(self, "UvBaker")
end
function UvBaker:StartBaker()
	local ent = self:GetActorEntity()
	local bakedLightingC = ent:GetComponent("lightmap_baker")
	if bakedLightingC == nil then
		return
	end
	bakedLightingC:UpdateLightmapTargets()
	bakedLightingC:GenerateLightmapUvs()
end
function UvBaker:PollBaker() end
function UvBaker:IsBakerComplete()
	return true
end
function UvBaker:IsBakerSuccessful()
	return true
end
function UvBaker:GetBakerProgress()
	return 1.0
end
function UvBaker:FinalizeBaker()
	return true
end

--------------------------------

pfm = pfm or {}
pfm.util = pfm.util or {}

local LightmapBaker = util.register_class("pfm.LightmapBaker", pfm.BaseBaker)
function LightmapBaker:__init()
	pfm.BaseBaker.__init(self, "LightmapBaker")

	self.m_jobs = {}
end
function LightmapBaker:SetGenerateRenderJob(generateRenderJob)
	self.m_generateRenderJob = generateRenderJob
end
function LightmapBaker:Reset()
	pfm.BaseBaker.Reset(self)
end
function LightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if util.is_valid(ent) == false then
		return
	end
	local bakedLightingC = ent:GetComponent("lightmap_baker")
	if bakedLightingC == nil then
		return
	end
	self.m_jobs = {}
	if self.m_generateRenderJob ~= true then
		local url = "https://wiki.pragma-engine.com/books/pragma-filmmaker/page/rendering-animations#bkmrk-lightmaps"
		pfm.create_popup_message(
			'{[l:url "' .. url .. '"]}' .. locale.get_text("pfm_popup_baking_lightmaps") .. "{[/l]}"
		)
	end
	bakedLightingC:UpdateLightmapTargets()
	if bakedLightingC:IsLightmapUvRebuildRequired() then
		pfm.log("Lightmap UV data cache is out of date, rebuilding...", pfm.LOG_CATEGORY_PFM_BAKE)
		bakedLightingC:GenerateLightmapUvs()
	end
	local lmMode = bakedLightingC:GetLightmapMode()
	if lmMode == ents.PFMBakedLighting.LIGHTMAP_MODE_DIRECTIONAL then
		pfm.log("Directional lightmap atlas is out of date, rebuilding...", pfm.LOG_CATEGORY_PFM_BAKE)
		local job = bakedLightingC:GenerateDirectionalLightmaps()
		if job == nil then
			return
		end
		table.insert(self.m_jobs, job)
	end
	local job = bakedLightingC:GenerateLightmaps(nil, nil, self.m_generateRenderJob)
	if self.m_generateRenderJob then
		return
	end
	table.insert(self.m_jobs, job)
end
function LightmapBaker:OpenWindow(windowHandle, contents, controls)
	pfm.BaseBaker.OpenWindow(self, title)
	local ent = self:GetActorEntity()
	if util.is_valid(ent) == false then
		return
	end
	debug.open_lightmap_atlas_view(ent, function(windowHandle, contents, controls)
		self.m_viewWindow = windowHandle
	end)
end
function LightmapBaker:PollBaker()
	for _, job in ipairs(self.m_jobs) do
		job:Poll()
	end
end
function LightmapBaker:IsBakerComplete()
	for _, job in ipairs(self.m_jobs) do
		if job:IsComplete() == false then
			return false
		end
	end
	return true
end
function LightmapBaker:IsBakerSuccessful()
	for _, job in ipairs(self.m_jobs) do
		if job:IsSuccessful() == false then
			return false
		end
	end
	return true
end
function LightmapBaker:GetBakerProgress()
	local progress = 0.0
	for _, job in ipairs(self.m_jobs) do
		progress = progress + job:GetProgress()
	end
	progress = progress / #self.m_jobs
	return progress
end
function LightmapBaker:CancelBaker()
	for _, job in ipairs(self.m_jobs) do
		job:Cancel()
	end
end
function LightmapBaker:FinalizeBaker()
	return true
end

function LightmapBaker:OnComplete()
	if self:IsBakerSuccessful() and self.m_generateRenderJob ~= true then
		self:OpenWindow("Lightmap Atlas View")
	end
	self:Reset()
end

--------------------------------

pfm.util.open_directional_lightmap_atlas_view_window = function(ent, onInit)
	debug.open_directional_lightmap_atlas_view(ent, onInit)
end

local DirectionalLightmapBaker = util.register_class("pfm.DirectionalLightmapBaker", pfm.BaseBaker)
function DirectionalLightmapBaker:OnInitialize()
	pfm.BaseBaker.__init(self)
end
function DirectionalLightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if util.is_valid(ent) == false then
		return
	end
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if bakedLightingC == nil then
		return
	end
	self.m_lightmapJob = bakedLightingC:GenerateDirectionalLightmaps()
end
function DirectionalLightmapBaker:OpenWindow(windowHandle, contents, controls)
	WIBaseBaker.OpenWindow(self, title)
	local ent = self:GetActorEntity()
	if util.is_valid(ent) == false then
		return
	end
	debug.open_directional_lightmap_atlas_view(ent, function(windowHandle, contents, controls)
		self.m_viewWindow = windowHandle
	end)
end
function DirectionalLightmapBaker:PollBaker()
	self.m_lightmapJob:Poll()
end
function DirectionalLightmapBaker:IsBakerComplete()
	return self.m_lightmapJob:IsComplete()
end
function DirectionalLightmapBaker:IsBakerSuccessful()
	return self.m_lightmapJob:IsSuccessful()
end
function DirectionalLightmapBaker:GetBakerProgress()
	return self.m_lightmapJob:GetProgress()
end
function DirectionalLightmapBaker:FinalizeBaker()
	return true
end

function DirectionalLightmapBaker:OnComplete()
	if self.m_lightmapJob:IsSuccessful() then
		self:OpenWindow("Directional lightmap Atlas View")
	end
end
