--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")
include("uv_atlas_mesh_overlay.lua")

local UvBaker = util.register_class("pfm.UvBaker",pfm.BaseBaker)
function UvBaker:__init()
	pfm.UvBaker.__init(self,"UvBaker")
end
function UvBaker:StartBaker()
	local ent = self:GetActorEntity()
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	bakedLightingC:GenerateLightmapUvs()
end
function UvBaker:PollBaker() end
function UvBaker:IsBakerComplete() return true end
function UvBaker:IsBakerSuccessful() return true end
function UvBaker:GetBakerProgress() return 1.0 end
function UvBaker:FinalizeBaker() return true end

--------------------------------

pfm = pfm or {}
pfm.util = pfm.util or {}

local function sign (p1, p2, p3)
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
end
local function is_point_in_triangle(pt,v1,v2,v3)
	if(v1:DistanceSqr(v2) < 0.0001 or v2:DistanceSqr(v3) < 0.0001 or v3:DistanceSqr(v1) < 0.0001) then return false end
    local d1, d2, d3;
    local has_neg, has_pos;

    d1 = sign(pt, v1, v2);
    d2 = sign(pt, v2, v3);
    d3 = sign(pt, v3, v1);

    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0);
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0);

    return not (has_neg and has_pos);
end
local function is_point_in_uv_mesh(ent,lmCache,x,y)
	if(util.is_valid(ent) == false or lmCache == nil) then return end
	local mdl = ent:GetModel()
	if(mdl == nil) then return end
	local p = Vector2(x,y)
	for img,mg in ipairs(mdl:GetMeshGroups()) do
		for im,m in ipairs(mg:GetMeshes()) do
			for ism,sm in ipairs(m:GetSubMeshes()) do
				local lightmapUvs = lmCache:FindLightmapUvs(ent:GetUuid(),sm:GetUuid())
				if(lightmapUvs ~= nil) then
					local indices = sm:GetIndices()
					for i=1,#indices,3 do
						local idx0 = indices[i]
						local idx1 = indices[i +1]
						local idx2 = indices[i +2]
						local uv0 = lightmapUvs[idx0 +1]
						local uv1 = lightmapUvs[idx1 +1]
						local uv2 = lightmapUvs[idx2 +1]
						if(is_point_in_triangle(p,uv0,uv1,uv2)) then
							local v0 = sm:GetVertexPosition(idx0)
							local v1 = sm:GetVertexPosition(idx1)
							local v2 = sm:GetVertexPosition(idx2)
							-- TODO: Calculate precise position of cursor hit
							--local p = geometry.calc_point_on_triangle(v0,v1,v2)
							if(v0 ~= nil and v1 ~= nil and v2 ~= nil) then
								local pos = v0
								pos = ent:GetPose() *v0
								v0 = ent:GetPose() *v0
								v1 = ent:GetPose() *v1
								v2 = ent:GetPose() *v2
								print("Mesh Index: ",img,im,ism)
								print("Triangle: ",v0,v1,v2)
								print("Near Position: ",pos)
							end
							return true
						end
					end
				end
			end
		end
	end
	return false
end

pfm.util.open_lightmap_atlas_view_window = function(ent,onInit)
	pfm.util.open_simple_window(locale.get_text("pfm_lightmap_atlas_view"),function(windowHandle,contents,controls)
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
				{tostring(ents.LightMapComponent.TEXTURE_DIFFUSE),locale.get_text("pfm_lightmap_diffuse")},
				{tostring(ents.LightMapComponent.TEXTURE_DIFFUSE_DIRECT),locale.get_text("pfm_lightmap_diffuse_direct")},
				{tostring(ents.LightMapComponent.TEXTURE_DIFFUSE_INDIRECT),locale.get_text("pfm_lightmap_diffuse_indirect")},
				{tostring(ents.LightMapComponent.TEXTURE_DOMINANT_DIRECTION),locale.get_text("pfm_lightmap_dominant_direction")}
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
			elTexSelection,wrapper = controls:AddDropDownMenu(locale.get_text("pfm_lightmap_atlas"),"view_lightmap",options,selectedOption or "0",function()
				if(lightmapC:IsValid() == false) then return end
				local val = toint(elTexSelection:GetOptionValue(elTexSelection:GetSelectedOption()))
				local tex = lightmapC:GetLightmapTexture(val)
				if(tex == nil) then
					el:ClearTexture()
					return
				end
				el:SetTexture(tex)
			end)
			if(selectedOption ~= nil) then elTexSelection:SelectOption(tonumber(selectedOption)) end

			options = {}
			for ent,c in ents.citerator(ents.COMPONENT_LIGHT_MAP_RECEIVER) do
				table.insert(options,{
					tostring(ent:GetUuid()),ent:GetName()
				})
			end
			local elActorSelection
			local elOverlay
			elActorSelection,wrapper = controls:AddDropDownMenu(locale.get_text("actor"),"actor",options,"",function()
				if(lightmapC:IsValid() == false) then return end
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
		el:SetMouseInputEnabled(true)
		el:AddCallback("OnMousePressed",function()
			if(lightmapC:IsValid() == false) then return end
			local c = lightmapC:GetEntity():GetComponent(ents.COMPONENT_LIGHT_MAP_DATA_CACHE)
			if(c == nil) then return end
			local lmCache = c:GetLightMapDataCache()
			local pos = el:GetCursorPos()
			local x = pos.x
			local y = pos.y
			local w = el:GetWidth()
			local h = el:GetHeight()
			if(w == 0 or h == 0) then return end
			x = x /w
			y = y /h
			if(x > 1.0 or y > 1.0) then return end

			for ent,c in ents.citerator(ents.COMPONENT_LIGHT_MAP_RECEIVER) do
				if(is_point_in_uv_mesh(ent,lmCache,x,y)) then
					elActorSelection:SelectOption(tostring(ent:GetUuid()))
					break
				end
			end
		end)

		if(onInit ~= nil) then onInit(windowHandle,contents,controls) end
	end)
end

local LightmapBaker = util.register_class("pfm.LightmapBaker",pfm.BaseBaker)
function LightmapBaker:__init()
	pfm.BaseBaker.__init(self,"LightmapBaker")

	self.m_jobs = {}
end
function LightmapBaker:SetGenerateRenderJob(generateRenderJob) self.m_generateRenderJob = generateRenderJob end
function LightmapBaker:Reset()
	pfm.BaseBaker.Reset(self)
end
function LightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	self.m_jobs = {}
	if(self.m_generateRenderJob ~= true) then
		local url = "https://wiki.pragma-engine.com/books/pragma-filmmaker/page/rendering-animations#bkmrk-lightmaps"
		pfm.create_popup_message("{[l:url \"" .. url .. "\"]}" .. locale.get_text("pfm_popup_baking_lightmaps") .. "{[/l]}")
	end
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
	local job = bakedLightingC:GenerateLightmaps(nil,nil,self.m_generateRenderJob)
	if(self.m_generateRenderJob) then
		return
	end
	table.insert(self.m_jobs,job)
end
function LightmapBaker:OpenWindow(windowHandle,contents,controls)
	pfm.BaseBaker.OpenWindow(self,title)
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	pfm.util.open_lightmap_atlas_view_window(ent,function(windowHandle,contents,controls)
		self.m_viewWindow = windowHandle
	end)
end
function LightmapBaker:PollBaker()
	for _,job in ipairs(self.m_jobs) do job:Poll() end
end
function LightmapBaker:IsBakerComplete()
	for _,job in ipairs(self.m_jobs) do
		if(job:IsComplete() == false) then return false end
	end
	return true
end
function LightmapBaker:IsBakerSuccessful()
	for _,job in ipairs(self.m_jobs) do
		if(job:IsSuccessful() == false) then return false end
	end
	return true
end
function LightmapBaker:GetBakerProgress()
	local progress = 0.0
	for _,job in ipairs(self.m_jobs) do
		progress = progress +job:GetProgress()
	end
	progress = progress /#self.m_jobs
	return progress
end
function LightmapBaker:CancelBaker()
	for _,job in ipairs(self.m_jobs) do
		job:Cancel()
	end
end
function LightmapBaker:FinalizeBaker() return true end

function LightmapBaker:OnComplete()
	if(self:IsBakerSuccessful()) then
		self:OpenWindow("Lightmap Atlas View")
	end
	self:Reset()
end

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

local DirectionalLightmapBaker = util.register_class("pfm.DirectionalLightmapBaker",pfm.BaseBaker)
function DirectionalLightmapBaker:OnInitialize()
	pfm.BaseBaker.__init(self)
end
function DirectionalLightmapBaker:StartBaker()
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	local bakedLightingC = ent:GetComponent("pfm_baked_lighting")
	if(bakedLightingC == nil) then return end
	self.m_lightmapJob = bakedLightingC:GenerateDirectionalLightmaps()
end
function DirectionalLightmapBaker:OpenWindow(windowHandle,contents,controls)
	WIBaseBaker.OpenWindow(self,title)
	local ent = self:GetActorEntity()
	if(util.is_valid(ent) == false) then return end
	pfm.util.open_directional_lightmap_atlas_view_window(ent,function(windowHandle,contents,controls)
		self.m_viewWindow = windowHandle
	end)
end
function DirectionalLightmapBaker:PollBaker() self.m_lightmapJob:Poll() end
function DirectionalLightmapBaker:IsBakerComplete() return self.m_lightmapJob:IsComplete() end
function DirectionalLightmapBaker:IsBakerSuccessful() return self.m_lightmapJob:IsSuccessful() end
function DirectionalLightmapBaker:GetBakerProgress() return self.m_lightmapJob:GetProgress() end
function DirectionalLightmapBaker:FinalizeBaker() return true end

function DirectionalLightmapBaker:OnComplete()
	if(self.m_lightmapJob:IsSuccessful()) then
		self:OpenWindow("Directional lightmap Atlas View")
	end
end
