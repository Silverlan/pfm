--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/particlesystem/pfm_particle_render_animated_sprites.lua")

util.register_class("ents.ParticleSystemComponent.RenderAnimatedSprites",ents.ParticleSystemComponent.BaseRenderer)

function ents.ParticleSystemComponent.RenderAnimatedSprites:__init()
	ents.ParticleSystemComponent.BaseRenderer.__init(self)
end
function ents.ParticleSystemComponent.RenderAnimatedSprites:Initialize()
	self.m_orientationType = tonumber(self:GetKeyValue("orientation_type")) or 0
	self.m_orientationControlPoint = tonumber(self:GetKeyValue("control_point_id")) or -1
	self.m_secondAnimationRate = tonumber(self:GetKeyValue("second_sequence_animation_rate")) or 0.0

	self:SetShader(shader.get("pfm_particle_animated_sprites"))
end

function ents.ParticleSystemComponent.RenderAnimatedSprites:Render(drawCmd,scene,renderer,bloom)
	local shader = self:GetShader()
	if(shader == nil) then return end
	local camBias = 0.0
	shader:Draw(drawCmd,self:GetParticleSystem(),scene,renderer,bloom,camBias)
end
function ents.ParticleSystemComponent.RenderAnimatedSprites:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.RenderAnimatedSprites:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.RenderAnimatedSprites:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.RenderAnimatedSprites:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_renderer("source_render_animated_sprites",ents.ParticleSystemComponent.RenderAnimatedSprites)
