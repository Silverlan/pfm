--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorAnimation",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorAnimation:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorAnimation:Initialize()
	self.m_animationRate = tonumber(self:GetKeyValue("animation_rate")) or 0.1
	self.m_animationFitLifetime = toboolean(self:GetKeyValue("animation_fit_lifetime")) or false
	self.m_animateInFps = toboolean(self:GetKeyValue("use_animation_rate_as_fps")) or false
end
function ents.ParticleSystemComponent.OperatorAnimation:Simulate(pt,dt)
	-- TODO: Unsure about these
	if(self.m_animationFitLifetime) then
		local lifeDuration = pt:GetLifeSpan()
		pt:SetAnimationFrameOffset(pt:GetTimeAlive() /lifeDuration)
	else
		if(self.m_animateInFps) then
			pt:SetAnimationFrameOffset(pt:GetTimeAlive() /self.m_animationRate)
		else
			pt:SetAnimationFrameOffset(self.m_animationRate)
		end
	end
end
function ents.ParticleSystemComponent.OperatorAnimation:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorAnimation:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorAnimation:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorAnimation:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_animation",ents.ParticleSystemComponent.OperatorAnimation)
