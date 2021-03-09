--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMMaterialOverlay",BaseEntityComponent)
function ents.PFMMaterialOverlay:Initialize()
	BaseEntityComponent.Initialize(self)
end

function ents.PFMMaterialOverlay:OnRemove()
	if(util.is_valid(self.m_guiEl)) then self.m_guiEl:Remove() end
	if(util.is_valid(self.m_cbOnOffsetChanged)) then self.m_cbOnOffsetChanged:Remove() end
end

function ents.PFMMaterialOverlay:GetMaterialOverlayData() return self.m_materialOverlayData end

function ents.PFMMaterialOverlay:Setup(overlayClipC,matOverlayData,fadeInTime,fadeOutTime)
	fadeInTime = fadeInTime or 0.0
	fadeOutTime = fadeOutTime or 0.0

	self.m_materialOverlayData = matOverlayData
	self.m_fadeInTime = fadeInTime
	self.m_fadeOutTime = fadeOutTime

	if(fadeInTime == 0.0) then return end
	self.m_cbOnOffsetChanged = overlayClipC:AddEventCallback(ents.PFMFilmClip.EVENT_ON_OFFSET_CHANGED,function(filmClipOffset,absOffset)
		self:OnOffsetChanged(filmClipOffset)
	end)
end

function ents.PFMMaterialOverlay:OnOffsetChanged(offset)
	if(util.is_valid(self.m_guiEl) == false) then return end
	offset = offset -self.m_materialOverlayData:GetTimeFrame():GetOffset()
	local alpha = 1.0 -offset /self.m_fadeInTime
	self.m_guiEl:SetAlpha(math.clamp(alpha *255.0,0.0,255.0))
end

function ents.PFMMaterialOverlay:OnEntitySpawn()
	local matOverlayData = self:GetMaterialOverlayData()
	local mat = (matOverlayData and matOverlayData:GetMaterial() or "")
	if(#mat == 0) then return end
	local el = gui.create("WITexturedRect")
	el:SetMaterial(mat)
	el:SetZPos(2000)---2)
	if(matOverlayData:IsFullscreen()) then
		local resolution = engine.get_render_resolution()
		el:SetPos(0,0)
		el:SetSize(resolution.x,resolution.y)
		el:SetAnchor(0.0,0.0,1.0,1.0)
	else
		el:SetLeft(matOverlayData:GetLeft())
		el:SetTop(matOverlayData:GetTop())
		el:SetWidth(matOverlayData:GetWidth())
		el:SetHeight(matOverlayData:GetHeight())
	end
	if(self.m_fadeInTime > 0.0 or self.m_fadeOutTime > 0.0) then el:SetAlpha(0.0) end
	self.m_guiEl = el
end

ents.COMPONENT_PFM_MATERIAL_OVERLAY = ents.register_component("pfm_material_overlay",ents.PFMMaterialOverlay)
