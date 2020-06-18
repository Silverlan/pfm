--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerRemapScalarToVector",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerRemapScalarToVector:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerRemapScalarToVector:Initialize()
	self.m_startTime = tonumber(self:GetKeyValue("emitter_lifetime_start_time")) or -1
	self.m_endTime = tonumber(self:GetKeyValue("emitter_lifetime_end_time")) or -1
	self.m_inputField = self:GetKeyValue("input_field") or "creation_time"
	self.m_inputMinimum = tonumber(self:GetKeyValue("input_minimum")) or 0
	self.m_inputMaximum = tonumber(self:GetKeyValue("input_maximum")) or 1
	self.m_outputField = self:GetKeyValue("output_field") or "radius"
	self.m_outputMinimum = vector.create_from_string(self:GetKeyValue("output_minimum") or "0 0 0")
	self.m_outputMaximum = vector.create_from_string(self:GetKeyValue("output_maximum") or "1 1 1")
	self.m_scaleInitialRange = toboolean(self:GetKeyValue("output_scalar_of_initial_random_range")) or false
	self.m_useLocalSystem = toboolean(self:GetKeyValue("use_local_system") or "1")
	self.m_controlPointNumber = tonumber(self:GetKeyValue("control_point_id") or "0")

	self.m_inputFieldId = ents.ParticleSystemComponent.Particle.name_to_field_id(self.m_inputField)
	self.m_outputFieldId = ents.ParticleSystemComponent.Particle.name_to_field_id(self.m_outputField)
end
function ents.ParticleSystemComponent.InitializerRemapScalarToVector:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerRemapScalarToVector:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerRemapScalarToVector:OnParticleCreated(pt)
	local creationTime = pt:GetTimeCreated()

	-- only use within start/end time frame and, if set, active input range
	if(((creationTime < self.m_startTime) or (creationTime >= self.m_endTime)) and ((self.m_startTime ~= -1.0) and (self.m_endTime ~= -1.0))) then
		--
	else
		local input = pt:GetField(self.m_inputFieldId)
		local vecOutput = Vector()
		vecOutput.x = RemapValClamped(input,self.m_inputMinimum,self.m_inputMaximum,self.m_outputMinimum.x,self.m_outputMaximum.x)
		vecOutput.y = RemapValClamped(input,self.m_inputMinimum,self.m_inputMaximum,self.m_outputMinimum.y,self.m_outputMaximum.y)
		vecOutput.z = RemapValClamped(input,self.m_inputMinimum,self.m_inputMaximum,self.m_outputMinimum.z,self.m_outputMaximum.z)

		if(self.m_outputFieldId == ents.ParticleSystemComponent.Particle.FIELD_ID_POS) then
			if(self.m_useLocalSystem == false) then
				local pose = GetControlPointTransformAtTime(self,self.m_controlPointNumber,creationTime)
				local vecControlPoint = pose:GetOrigin()
				vecOutput = vecOutput +vecControlPoint
				local vecOutputPrev = vecOutput:Copy()
				if(self.m_scaleInitialRange) then
					vecOutput = vecOutput *pt:GetField(self.m_outputFieldId)
					vecOutputPrev = vecOutputPrev *pt:GetPreviousPosition()
				end
				pt:SetField(self.m_outputFieldId,Vector4(vecOutput,0))
				pt:SetPreviousPosition(vecOutputPrev)
			else
				local pose = GetControlPointTransformAtTime(self,self.m_controlPointNumber,creationTime)
				local vecTransformLocal = pose *vecOutput
				vecOutput = vecTransformLocal:Copy()
				local vecOutputPrev = vecOutput:Copy()
				if(self.m_scaleInitialRange) then
					vecOutput = vecOutput *pt:GetField(self.m_outputFieldId)
					vecOutputPrev = vecOutputPrev *pt:GetPreviousPosition()
				end
				pt:SetField(self.m_outputFieldId,Vector4(vecOutput,0))
				pt:SetPreviousPosition(vecOutputPrev)
			end
		else
			if(self.m_scaleInitialRange) then
				vecOutput = vecOutput *pt:GetField(self.m_outputFieldId)
			end
			pt:SetField(self.m_outputFieldId,Vector4(vecOutput,0))
		end
	end
end
function ents.ParticleSystemComponent.InitializerRemapScalarToVector:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_remap_scalar_to_vector",ents.ParticleSystemComponent.InitializerRemapScalarToVector)
