--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.InitializerLifetimeFromSequence",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.InitializerLifetimeFromSequence:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.InitializerLifetimeFromSequence:Initialize()
	console.print_table(self:GetKeyValues())
	self.m_fps = tonumber(self:GetKeyValue("frames_per_second")) or 30

	-- Priority has to be lower than that of initializers like "sequence random", because
	-- we need to ensure that the particle's sequence is set before this initializer is executed!
	self:SetPriority(-10)
end
function ents.ParticleSystemComponent.InitializerLifetimeFromSequence:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.InitializerLifetimeFromSequence:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.InitializerLifetimeFromSequence:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
	local pts = self:GetParticleSystem()
	local spriteSheetAnim = pts:GetSpriteSheetAnimation()
	if(spriteSheetAnim == nil) then return end
	local seq = spriteSheetAnim:GetSequence(pt:GetSequence())
	if(seq == nil) then return end
	local numFrames = seq:GetFrameCount()
	if(numFrames > 0) then numFrames = numFrames -1 end
	local lifeTime = numFrames /self.m_fps
	pt:SetLife(lifeTime)
end
function ents.ParticleSystemComponent.InitializerLifetimeFromSequence:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("source_lifetime_from_sequence",ents.ParticleSystemComponent.InitializerLifetimeFromSequence)
