--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_tonemapping.lua")

util.register_class("gui.ToneMappedImage",gui.Base)

function gui.ToneMappedImage:__init()
	gui.Base.__init(self)
end
function gui.ToneMappedImage:OnInitialize()
	gui.Base.OnInitialize(self)
	self.m_shader = shader.get("pfm_tonemapping")

	self:SetExposure(1.0)
	self:SetToneMappingAlgorithm(shader.TONE_MAPPING_ACES)
	self:SetToneMappingAlgorithmArgs({})
	self:SetLuminance(shader.PFMTonemapping.Luminance())

	self.m_dsTonemapping = self.m_shader:CreateDescriptorSet(shader.PFMTonemapping.DESCRIPTOR_SET_TEXTURE)
end
function gui.ToneMappedImage:SetTexture(tex)
	self.m_texture = tex
	self:SetVisible(tex ~= nil)
	if(tex == nil) then return end

	self.m_dsTonemapping:SetBindingTexture(shader.PFMTonemapping.TEXTURE_BINDING_HDR_COLOR,tex)
end
function gui.ToneMappedImage:GetTexture() return self.m_texture end
function gui.ToneMappedImage:GetDescriptorSet() return self.m_dsTonemapping end
function gui.ToneMappedImage:SetExposure(exposure) self.m_exposure = exposure end
function gui.ToneMappedImage:GetExposure() return self.m_exposure end
function gui.ToneMappedImage:SetToneMappingAlgorithm(toneMapping) self.m_toneMapping = toneMapping end
function gui.ToneMappedImage:GetToneMappingAlgorithm() return self.m_toneMapping end
function gui.ToneMappedImage:SetToneMappingAlgorithmArgs(args) self.m_toneMappingArgs = args end
function gui.ToneMappedImage:GetToneMappingAlgorithmArgs() return self.m_toneMappingArgs end
function gui.ToneMappedImage:SetLuminance(luminance) self.m_luminance = luminance end
function gui.ToneMappedImage:GetLuminance() return self.m_luminance end
function gui.ToneMappedImage:Render(drawCmd,pose,toneMapping)
	if(self.m_shader == nil or self.m_texture == nil) then return end
	local parent = self:GetParent()
	local x,y,w,h = gui.get_render_scissor_rect()

	local exposure = self:GetExposure()
	toneMapping = toneMapping or self:GetToneMappingAlgorithm()
	local args = self:GetToneMappingAlgorithmArgs()
	-- TODO: Apply scissor
	local img = self.m_texture:GetImage()
	local isGammaCorrected = (img:GetFormat() ~= prosper.FORMAT_R16G16B16A16_SFLOAT) -- Assume the image is gamma corrected if it's not a HDR image
	self.m_shader:Draw(drawCmd,pose,self.m_dsTonemapping,exposure,toneMapping,isGammaCorrected,self.m_luminance,args)
end
function gui.ToneMappedImage:OnDraw(drawInfo,pose)
	self:Render(game.get_draw_command_buffer(),pose)
end
gui.register("WIToneMappedImage",gui.ToneMappedImage)
