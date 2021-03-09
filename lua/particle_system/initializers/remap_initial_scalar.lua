--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerRemapInitialScalar",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerRemapInitialScalar:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerRemapInitialScalar:Initialize()
	self.m_startTime = tonumber(self:GetKeyValue("emitter_lifetime_start_time")) or -1
	self.m_endTime = tonumber(self:GetKeyValue("emitter_lifetime_end_time")) or -1
	self.m_inputField = self:GetKeyValue("input_field") or "creation_time"
	self.m_inputMinimum = tonumber(self:GetKeyValue("input_minimum")) or 0
	self.m_inputMaximum = tonumber(self:GetKeyValue("input_maximum")) or 1
	self.m_outputField = self:GetKeyValue("output_field") or "radius"
	self.m_outputMinimum = tonumber(self:GetKeyValue("output_minimum")) or 0
	self.m_outputMaximum = tonumber(self:GetKeyValue("output_maximum")) or 1
	self.m_scaleInitialRange = toboolean(self:GetKeyValue("output_scalar_of_initial_random_range")) or false
	self.m_activeRange = toboolean(self:GetKeyValue("only_active_within_specified_input_range")) or false

	self.m_inputFieldId = ents.ParticleSystemComponent.Particle.name_to_field_id(self.m_inputField)
	self.m_outputFieldId = ents.ParticleSystemComponent.Particle.name_to_field_id(self.m_outputField)
end
function ents.ParticleSystemComponent.InitializerRemapInitialScalar:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerRemapInitialScalar:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end

local attributesWhichAre0To1 = {
	-- PARTICLE_ATTRIBUTE_ALPHA_MASK | PARTICLE_ATTRIBUTE_ALPHA2_MASK
	[ents.ParticleSystemComponent.Particle.FIELD_ID_ALPHA] = true
}
local attributesWhichAreInts = {
	-- PARTICLE_ATTRIBUTE_PARTICLE_ID_MASK | PARTICLE_ATTRIBUTE_HITBOX_INDEX_MASK
}
function ents.ParticleSystemComponent.InitializerRemapInitialScalar:OnParticleCreated(pt)
	local min = self.m_outputMinimum
	local max = self.m_outputMaximum
	if(attributesWhichAre0To1[self.m_outputFieldId] == true) then
		min = math.clamp(min,0,1)
		max = math.clamp(max,0,1)
	end

	if(attributesWhichAreInts[self.m_inputFieldId] == true) then

	end

	local creationTime = pt:GetTimeCreated()
	local input = pt:GetField(self.m_inputFieldId)
	-- only use within start/end time frame and, if set, active input range
	if((((creationTime < self.m_startTime) or (creationTime >= self.m_endTime)) and ((self.m_startTime ~= -1.0) and (self.m_endTime ~= -1.0))) or (self.m_activeRange and (input < self.m_inputMinimum or input > self.m_inputMaximum))) then
		--
	else
		local output = RemapValClamped(input,self.m_inputMinimum,self.m_inputMaximum,min,max)
		if(self.m_scaleInitialRange) then output = pt:GetField(self.m_outputFieldId) *output end
		pt:SetField(self.m_outputFieldId,output)
	end
end
function ents.ParticleSystemComponent.InitializerRemapInitialScalar:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_remap_initial_scalar",ents.ParticleSystemComponent.InitializerRemapInitialScalar)
