--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorAlphaFade",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorAlphaFade:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorAlphaFade:Initialize()
	self.m_startAlpha = tonumber(self:GetKeyValue("start_alpha") or "1")
	self.m_endAlpha = tonumber(self:GetKeyValue("end_alpha") or "0")
	self.m_startFadeInTime = tonumber(self:GetKeyValue("start_fade_in_time") or "0")
	self.m_endFadeInTime = tonumber(self:GetKeyValue("end_fade_in_time") or "0.5")
	self.m_startFadeOutTime = tonumber(self:GetKeyValue("start_fade_out_time") or "0.5")
	self.m_endFadeOutTime = tonumber(self:GetKeyValue("end_fade_out_time") or "1")

	-- Cache off and validate values
	if(self.m_endFadeInTime < self.m_startFadeInTime) then
		self.m_endFadeInTime = self.m_startFadeInTime
	end
	if(self.m_endFadeOutTime < self.m_startFadeOutTime) then
		self.m_endFadeOutTime = self.m_startFadeOutTime
	end
	
	if(self.m_startFadeOutTime < self.m_startFadeInTime) then
		local tmp = self.m_startFadeInTime
		self.m_startFadeInTime = self.m_startFadeOutTime
		self.m_startFadeOutTime = tmp
	end

	if(self.m_endFadeOutTime < self.m_endFadeInTime) then
		local tmp = self.m_endFadeInTime
		self.m_endFadeInTime = self.m_endFadeOutTime
		self.m_endFadeOutTime = tmp
	end
end
function ents.ParticleSystemComponent.OperatorAlphaFade:Simulate(pt,dt)
	local fadeInDuration = self.m_endFadeInTime -self.m_startFadeInTime
	local fadeInDurationOO = ReciprocalEst(fadeInDuration)
	local fadeOutDuration = self.m_endFadeOutTime -self.m_startFadeOutTime
	local fadeOutDurationOO = ReciprocalEst(fadeOutDuration)
	local col = pt:GetColor()
	local initialAlpha = pt:GetInitialAlpha()
	local age = pt:GetTimeAlive()
	local lifeDuration = pt:GetLifeSpan()
	age = age /lifeDuration
	if(age < 1.0) then
		if(age >= self.m_startFadeInTime and age <= self.m_endFadeInTime) then
			local goal = initialAlpha *self.m_startAlpha
			local newAlpha = SimpleSplineRemapValWithDeltasClamped(age,self.m_startFadeInTime,fadeInDuration,fadeInDurationOO,goal,(initialAlpha -goal))
			pt:SetAlpha(newAlpha)
		end
		if(age >= self.m_startFadeOutTime and age <= self.m_endFadeOutTime) then
			local goal = initialAlpha *self.m_endAlpha
			local newAlpha = SimpleSplineRemapValWithDeltasClamped(age,self.m_startFadeOutTime,fadeOutDuration,fadeOutDurationOO,initialAlpha,(goal -initialAlpha))
			pt:SetAlpha(newAlpha)
		end
	else
		pt:Die()
	end
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorAlphaFade:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_alpha_fade_and_decay",ents.ParticleSystemComponent.OperatorAlphaFade)
