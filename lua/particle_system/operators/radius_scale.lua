--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorRadiusScale",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorRadiusScale:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorRadiusScale:Initialize()
	self.m_startTime = tonumber(self:GetKeyValue("start_time") or "0")
	self.m_endTime = tonumber(self:GetKeyValue("end_time") or "1")
	self.m_radiusStartScale = tonumber(self:GetKeyValue("radius_start_scale") or "1")
	self.m_radiusEndScale = tonumber(self:GetKeyValue("radius_end_scale") or "1")
	self.m_easeInAndOut = toboolean(self:GetKeyValue("ease_in_and_out") or false)
	self.m_scaleBias = tonumber(self:GetKeyValue("scale_bias") or "0.5")

	self.m_biasParam = PreCalcBiasParameter(self.m_scaleBias)
end
function ents.ParticleSystemComponent.OperatorRadiusScale:Simulate(pt,dt)
	if(self.m_endTime <= self.m_startTime) then return end
	local creationTime = pt:GetTimeCreated()
	local lifeDuration = pt:GetLifeSpan()
	local radius = pt:GetRadius()
	local initialRadius = pt:GetInitialRadius()
	local startTime = self.m_startTime
	local endTime = self.m_endTime
	local timeWidthOO = Reciprocal(endTime -startTime)
	local scaleWidth = self.m_radiusEndScale -self.m_radiusStartScale
	local startScale = self.m_radiusStartScale

	local curTime = time.real_time()--pt:GetTimeAlive()
	local lifeTime = (curTime -creationTime) *ReciprocalEst(lifeDuration)
	local goodMask = (lifeDuration > 0.0 and lifeTime >= startTime and lifeTime < endTime)
	if(self.m_easeInAndOut) then
		if(lifeDuration > 0.0) then
			local fadeWindow = (lifeTime -startTime) *timeWidthOO
			fadeWindow = startScale +SimpleSpline(fadeWindow) *scaleWidth
			if(goodMask) then
				pt:SetRadius(initialRadius *fadeWindow)
			end
		end
	else
		if(self.m_scaleBias == 0.5) then
			if(goodMask) then
				local fadeWindow = (lifeTime -startTime) *timeWidthOO
				fadeWindow = startScale +fadeWindow *scaleWidth
				pt:SetRadius(initialRadius *fadeWindow)
			end
		else
			-- use rational approximation to bias
			if(goodMask) then
				local fadeWindow = (lifeTime -startTime) *timeWidthOO
				fadeWindow = startScale +(Bias(fadeWindow,self.m_biasParam) *scaleWidth)
				pt:SetRadius(initialRadius *fadeWindow)
			end
		end
	end
end
function ents.ParticleSystemComponent.OperatorRadiusScale:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorRadiusScale:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorRadiusScale:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	
end
function ents.ParticleSystemComponent.OperatorRadiusScale:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_radius_scale",ents.ParticleSystemComponent.OperatorRadiusScale)
