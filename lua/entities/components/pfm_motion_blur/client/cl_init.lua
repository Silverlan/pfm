--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMMotionBlur", BaseEntityComponent)
Component:RegisterMember("MotionBlurIntensity", udm.TYPE_FLOAT, 4.0, {
	onChange = function(self)
		self:UpdateMotionBlurFactor()
	end,
})
function Component:Initialize()
	local ent, c = ents.citerator(ents.COMPONENT_PFM_PROJECT)()
	if c == nil then
		return
	end
	self.m_cbOnPlaybackOffsetChanged = c:AddEventCallback(ents.PFMProject.EVENT_ON_PLAYBACK_OFFSET_CHANGED, function()
		self:UpdateMotionBlurData()
	end)

	self.m_renderers = {}
	self:AddRenderer(game.get_scene():GetRenderer())

	self.m_motionBlurDataC = self:AddEntityComponent(ents.COMPONENT_MOTION_BLUR_DATA)
end
function Component:AddRenderer(c)
	if c:GetEntity():HasComponent(ents.COMPONENT_RENDERER_PP_MOTION_BLUR) then
		return
	end
	table.insert(self.m_renderers, c)

	local motionBlurC = c:GetEntity():AddComponent(ents.COMPONENT_RENDERER_PP_MOTION_BLUR)
	motionBlurC:SetAutoUpdateMotionData(false)
	motionBlurC:SetMotionBlurQuality(ents.RendererPpMotionBlurComponent.MOTION_BLUR_QUALITY_HIGH)
end
function Component:UpdateMotionBlurData()
	if util.is_valid(self.m_motionBlurDataC) == false then
		return
	end
	self.m_motionBlurDataC:UpdatePoses()
end
function Component:OnRemove()
	util.remove(self.m_cbOnPlaybackOffsetChanged)
	for _, c in ipairs(self.m_renderers) do
		if c:IsValid() then
			c:GetEntity():RemoveComponent(ents.COMPONENT_RENDERER_PP_MOTION_BLUR)
		end
	end

	self:GetEntity():RemoveComponent(ents.COMPONENT_MOTION_BLUR_DATA)
end
function Component:OnEntitySpawn()
	self:UpdateMotionBlurFactor()
end
function Component:UpdateMotionBlurFactor()
	for _, renderer in ipairs(self.m_renderers) do
		if renderer:IsValid() then
			local motionBlurC = renderer:GetEntity():GetComponent(ents.COMPONENT_RENDERER_PP_MOTION_BLUR)
			if motionBlurC ~= nil then
				motionBlurC:SetMotionBlurIntensity(self:GetMotionBlurIntensity())
			end
		end
	end
end
ents.register_component("pfm_motion_blur", Component, "pfm")
