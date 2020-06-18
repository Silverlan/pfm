--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorOscillateVector",ents.ParticleSystemComponent.BaseOperator)

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

function ents.ParticleSystemComponent.OperatorOscillateVector:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorOscillateVector:Initialize()
	self.m_oscillationField = self:GetKeyValue("oscillation_field") or ""
	self.m_oscillationRateMin = vector.create_from_string(self:GetKeyValue("oscillation_rate_min") or "0 0 0")
	self.m_oscillationRateMax = vector.create_from_string(self:GetKeyValue("oscillation_rate_max") or "0 0 0")
	self.m_oscillationFrequencyMin = vector.create_from_string(self:GetKeyValue("oscillation_frequency_min") or "1 1 1")
	self.m_oscillationFrequencyMax = vector.create_from_string(self:GetKeyValue("oscillation_frequency_max") or "1 1 1")
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
function ents.ParticleSystemComponent.OperatorOscillateVector:Simulate(pt,dt,strength)
	strength = strength *0.05 -- TODO: Why?
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
		local frequency = Vector(
			pt:CalcRandomFloat(self.m_oscillationFrequencyMin.x,self.m_oscillationFrequencyMax.x,0),
			pt:CalcRandomFloat(self.m_oscillationFrequencyMin.y,self.m_oscillationFrequencyMax.y,1),
			pt:CalcRandomFloat(self.m_oscillationFrequencyMin.z,self.m_oscillationFrequencyMax.z,2)
		)
		local rate = Vector(
			pt:CalcRandomFloat(self.m_oscillationRateMin.x,self.m_oscillationRateMax.x,0),
			pt:CalcRandomFloat(self.m_oscillationRateMin.y,self.m_oscillationRateMax.y,1),
			pt:CalcRandomFloat(self.m_oscillationRateMin.z,self.m_oscillationRateMax.z,2)
		)
		local cos
		if(self.m_proportional) then
			lifeTime = age *ReciprocalEst(lifeDuration)
			cos = ((lifeTime *frequency) *self.m_oscillationMultiplier) +Vector(self.m_oscillationStartPhase,self.m_oscillationStartPhase,self.m_oscillationStartPhase)
		else
			local curTime = pt:GetTimeCreated() +age
			local cosFactor = (self.m_oscillationMultiplier *curTime) *Vector(1,1,1) +Vector(self.m_oscillationStartPhase,self.m_oscillationStartPhase,self.m_oscillationStartPhase)
			cos = cosFactor *frequency
		end
		cos = cos *math.pi
		local scaleFactor = strength *dt *0.01 -- TODO: Factor 0.01 is arbitrary but resulted in a closer match for field 'rotation' (See particle system "Explosions_MA_Smoke_1")
		local oscMultiplier = rate *scaleFactor

		local curVal = pt:GetField(self.m_fieldId)
		if(curVal ~= nil and util.get_type_name(curVal) == "Vector4") then
			local oscVal = Vector(curVal.x,curVal.y,curVal.z) +oscMultiplier *Vector(SinEst01(cos.x),SinEst01(cos.y),SinEst01(cos.z))
			if(self.m_fieldId == ents.ParticleSystemComponent.Particle.FIELD_ID_COLOR) then
				oscVal.x = math.clamp(oscVal.x,0.0,1.0)
				oscVal.y = math.clamp(oscVal.y,0.0,1.0)
				oscVal.z = math.clamp(oscVal.z,0.0,1.0)
			end
			pt:SetField(self.m_fieldId,Vector4(oscVal.x,oscVal.y,oscVal.z,0.0))
		end
	end
end
function ents.ParticleSystemComponent.OperatorOscillateVector:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorOscillateVector:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorOscillateVector:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorOscillateVector:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("source_oscillate_vector",ents.ParticleSystemComponent.OperatorOscillateVector)
