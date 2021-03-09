--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorOscillateScalar",ents.ParticleSystemComponent.BaseOperator)

--[[local function _SinEst01(val)
	return val *(4.0 -(val *4.0))
end

local function _Sin01(val)
	local badEst = val *(4.0 -(val *4.0))
	return 0.225 *((badEst *badEst) -badEst) +badEst
end

local function SinEst01(val)
	local abs = math.abs(val)
	local reduced2 = Mod2SIMDPositiveInput(abs)
	local oddMask = (reduced2 >= 1.0)
	local val = reduced2 -(oddMask and 1.0 or 0.0)
	local sin = _SinEst01(val)
	-- TODO
	local v = bit.band(0x80000000,(val ~= 0.0 and oddMask == false) or (val == 0.0 and oddMask == true))
	if() then

	end
	sin = XorSIMD( sin, AndSIMD( 0x80000000, XorSIMD( val, oddMask ) ) );
	return sin
end]]

local function SinEst01(val)
	return math.sin(val)
end

function ents.ParticleSystemComponent.OperatorOscillateScalar:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorOscillateScalar:Initialize()
	self.m_oscillationField = self:GetKeyValue("oscillation_field") or ""
	self.m_oscillationRateMin = tonumber(self:GetKeyValue("oscillation_rate_min")) or 0.0
	self.m_oscillationRateMax = tonumber(self:GetKeyValue("oscillation_rate_max")) or 0.0
	self.m_oscillationFrequencyMin = tonumber(self:GetKeyValue("oscillation_frequency_min")) or 1.0
	self.m_oscillationFrequencyMax = tonumber(self:GetKeyValue("oscillation_frequency_max")) or 1.0
	self.m_proportional = toboolean(self:GetKeyValue("proportional"))
	self.m_startTimeMin = tonumber(self:GetKeyValue("start_time_min")) or 0.0
	self.m_startTimeMax = tonumber(self:GetKeyValue("start_time_max")) or 0.0
	self.m_endTimeMin = tonumber(self:GetKeyValue("end_time_min")) or 1.0
	self.m_endTimeMax = tonumber(self:GetKeyValue("end_time_max")) or 1.0
	self.m_startEndProportional = toboolean(self:GetKeyValue("start_end_proportional"))
	self.m_oscillationMultiplier = tonumber(self:GetKeyValue("oscillation_multiplier")) or 2.0
	self.m_oscillationStartPhase = tonumber(self:GetKeyValue("oscillation_start_phase")) or 0.5

	self.m_fieldId = ents.ParticleSystemComponent.Particle.name_to_field_id(self.m_oscillationField)
end
function ents.ParticleSystemComponent.OperatorOscillateScalar:Simulate(pt,dt,strength)
	local lifeDuration = pt:GetLifeSpan()
	local age = pt:GetTimeAlive()
	local lifeTime
	if(self.m_startEndProportional) then
		lifeTime = age *ReciprocalEst(lifeDuration)
	else
		lifeTime = age
	end
	local startTime = pt:CalcRandomFloat(self.m_startTimeMin,self.m_startTimeMax)
	local endTime = pt:CalcRandomFloat(self.m_endTimeMin,self.m_endTimeMax)
	if(lifeDuration > 0.0 and lifeTime >= startTime and lifeTime < endTime) then
		local frequency = pt:CalcRandomFloat(self.m_oscillationFrequencyMin,self.m_oscillationFrequencyMax)
		local rate = pt:CalcRandomFloat(self.m_oscillationRateMin,self.m_oscillationRateMax)
		local cos
		if(self.m_proportional) then
			lifeTime = age *ReciprocalEst(lifeDuration)
			cos = ((lifeTime *frequency) *self.m_oscillationMultiplier) +self.m_oscillationStartPhase
		else
			local curTime = pt:GetTimeCreated() +age
			local cosFactor = (self.m_oscillationMultiplier *curTime) +self.m_oscillationStartPhase
			cos = cosFactor *frequency
		end
		cos = cos *math.pi
		local scaleFactor = strength *dt *0.01 -- TODO: Factor 0.01 is arbitrary but resulted in a closer match for field 'rotation' (See particle system "Explosions_MA_Smoke_1")
		local oscMultiplier = rate *scaleFactor

		local curVal = pt:GetField(self.m_fieldId)
		if(curVal ~= nil and type(curVal) == "number") then
			if(self.m_fieldId == ents.ParticleSystemComponent.Particle.FIELD_ID_ROT) then curVal = math.rad(curVal) end
			local oscVal = curVal +oscMultiplier *SinEst01(cos)
			if(self.m_fieldId == ents.ParticleSystemComponent.Particle.FIELD_ID_ALPHA) then
				oscVal = math.clamp(oscVal,0.0,1.0)
			end
			if(self.m_fieldId == ents.ParticleSystemComponent.Particle.FIELD_ID_ROT) then oscVal = math.deg(oscVal) end
			pt:SetField(self.m_fieldId,oscVal)
		end
	end
end
function ents.ParticleSystemComponent.OperatorOscillateScalar:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorOscillateScalar:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorOscillateScalar:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorOscillateScalar:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_oscillate_scalar",ents.ParticleSystemComponent.OperatorOscillateScalar)
