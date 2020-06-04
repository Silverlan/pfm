--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/particlesystem/pfm_particle_sprite_trail.lua")

util.register_class("ents.ParticleSystemComponent.RendererSpriteTrail",ents.ParticleSystemComponent.BaseRenderer)

function ents.ParticleSystemComponent.RendererSpriteTrail:__init()
	ents.ParticleSystemComponent.BaseRenderer.__init(self)
end
function ents.ParticleSystemComponent.RendererSpriteTrail:Initialize()
	self.m_minLength = tonumber(self:GetKeyValue("min_length")) or 0.0
	self.m_maxLength = tonumber(self:GetKeyValue("max_length")) or 2000.0
	self.m_lengthFadeInTime = tonumber(self:GetKeyValue("length_fade_in_time")) or 0.0
	self.m_animationRate = tonumber(self:GetKeyValue("animation_rate")) or 0.1

	self:SetShader(shader.get("pfm_particle_sprite_trail"))
end

function ents.ParticleSystemComponent.RendererSpriteTrail:GetMinLength() return self.m_minLength end
function ents.ParticleSystemComponent.RendererSpriteTrail:GetMaxLength() return self.m_maxLength end
function ents.ParticleSystemComponent.RendererSpriteTrail:GetLengthFadeInTime() return self.m_lengthFadeInTime end
function ents.ParticleSystemComponent.RendererSpriteTrail:GetAnimationRate() return self.m_animationRate end

function ents.ParticleSystemComponent.RendererSpriteTrail:Render(drawCmd,renderer,bloom)
	local shader = self:GetShader()
	if(shader == nil) then return end
	shader:Draw(drawCmd,self:GetParticleSystem(),renderer,bloom,self.m_minLength,self.m_maxLength,self.m_lengthFadeInTime,self.m_animationRate)
end
function ents.ParticleSystemComponent.RendererSpriteTrail:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.RendererSpriteTrail:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.RendererSpriteTrail:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.RendererSpriteTrail:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_renderer("source_render_sprite_trail",ents.ParticleSystemComponent.RendererSpriteTrail)
