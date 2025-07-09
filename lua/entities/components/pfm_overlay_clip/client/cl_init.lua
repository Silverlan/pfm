-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMOverlayClip", BaseEntityComponent)
function ents.PFMOverlayClip:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_offset = 0.0
end

function ents.PFMOverlayClip:OnRemove()
	if util.is_valid(self.m_overlay) then
		self.m_overlay:Remove()
	end
end

function ents.PFMOverlayClip:GetOverlayClipData()
	return self.overlayClipData
end
function ents.PFMOverlayClip:GetTrack()
	return self.m_track
end

function ents.PFMOverlayClip:Setup(overlayClip, trackC)
	-- TODO
	--[[self.overlayClipData = overlayClip
	self.m_track = trackC

	local overlayData = overlayClip:GetSound() -- MaterialOverlayFXClip,fadeInTime,fadeOutTime
	local ent = self:GetEntity():CreateChild("pfm_material_overlay")
	local overlayC = ent:GetComponent(ents.COMPONENT_PFM_MATERIAL_OVERLAY)
	if(overlayC ~= nil) then overlayC:Setup(self,overlayData) end
	--Setup(filmClipC,matOverlayData,fadeInTime,fadeOutTime)

	-- TODO: Render GUI, overlay over render texture

	ent:Spawn()
	self.m_overlay = ent]]
end

function ents.PFMOverlayClip:GetTimeFrame()
	local clip = self:GetOverlayClipData()
	if clip == nil then
		return fudm.PFMTimeFrame()
	end
	return clip:GetTimeFrame()
end

function ents.PFMOverlayClip:GetOffset()
	return self.m_offset
end
function ents.PFMOverlayClip:SetOffset(offset)
	local timeFrame = self:GetTimeFrame()
	offset = offset - timeFrame:GetStart() + timeFrame:GetOffset()
	if offset == self.m_offset then
		return
	end
	self.m_offset = offset

	if util.is_valid(self.m_overlay) then
		local overlayC = self.m_overlay:GetComponent(ents.COMPONENT_PFM_MATERIAL_OVERLAY)
		if overlayC ~= nil then
			overlayC:OnOffsetChanged(offset)
		end
	end
end

ents.register_component(
	"pfm_overlay_clip",
	ents.PFMOverlayClip,
	"pfm",
	ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR
)
