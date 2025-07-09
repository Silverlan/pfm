-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class(
	"ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom",
	ents.ParticleSystemComponent.BaseInitializer
)

function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:Initialize()
	self.m_controlPointNumber = tonumber(self:GetKeyValue("control_point_id")) or 0
	self.m_offsetMin = vector.create_from_string(self:GetKeyValue("offset_min") or "0 0 0")
	self.m_offsetMax = vector.create_from_string(self:GetKeyValue("offset_max") or "0 0 0")
	self.m_offsetInLocalSpace = toboolean(self:GetKeyValue("offset_in_local_space") or "0")
	self.m_offsetProportionalToRadius = toboolean(self:GetKeyValue("offset_proportional_to_radius") or "0")
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local randPos = Vector()
	if self.m_offsetProportionalToRadius then
		randPos = RandomVector((self.m_offsetMin * radius), self.m_offsetMax * radius)
	else
		randPos = RandomVector(self.m_offsetMin, self.m_offsetMax)
	end

	if self.m_offsetInLocalSpace then
		local pose = GetControlPointTransformAtTime(self, self.m_controlPointNumber, pt:GetTimeCreated())
		randPos:Rotate(pose:GetRotation())
	end
	pt:SetPosition(pt:GetPosition() + randPos)
	pt:SetPreviousPosition(pt:GetPreviousPosition() + randPos)
end
function ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer(
	"source_position_modify_random_offset",
	ents.ParticleSystemComponent.InitializerPositionModifyOffsetRandom
)
