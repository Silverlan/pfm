--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerColorRandom",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerColorRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerColorRandom:Initialize()
	self.m_controlPointNumber = tonumber(self:GetKeyValue("tint control point") or "0")
	self.m_color1 = Color(self:GetKeyValue("color1") or "255 255 255 255")
	self.m_color2 = Color(self:GetKeyValue("color2") or "255 255 255 255")
	self.m_tintPerc = tonumber(self:GetKeyValue("tint_perc") or "0")
	self.m_tintClampMin = Color(self:GetKeyValue("tint clamp min") or "0 0 0 0")
	self.m_tintClampMax = Color(self:GetKeyValue("tint clamp max") or "255 255 255 255")
	self.m_tintUpdateMovementTreshold = tonumber(self:GetKeyValue("tint update movement threshold") or "32")
end
function ents.ParticleSystemComponent.InitializerColorRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerColorRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerColorRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local tint = Color.White:Copy()
	-- If we're factoring in luminosity or tint, then get our lighting info for this position
	if(self.m_tintPerc ~= 0.0) then
		-- TODO
	end

	local randomPerc = math.randomf(0,1)
	-- Randomly choose a range between the two colors
	local colorMin = self.m_color1:ToVector4()
	local colorMax = self.m_color2:ToVector4()
	local color = colorMin +(colorMax -colorMin) *randomPerc

	-- Tint the particles
	if(self.m_tintPerc ~= 0.0) then
		-- TODO
	end
	pt:SetColor(Color(color))
end
function ents.ParticleSystemComponent.InitializerColorRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("color random",ents.ParticleSystemComponent.InitializerColorRandom)
