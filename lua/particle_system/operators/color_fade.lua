--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.OperatorColorFade",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.OperatorColorFade:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorColorFade:Initialize()
	self.m_colorFade = Color(self:GetKeyValue("color_fade") or "255 255 255 255")
	self.m_fadeStartTime = tonumber(self:GetKeyValue("fade_start_time") or "0")
	self.m_fadeEndTime = tonumber(self:GetKeyValue("fade_end_time") or "1")
	self.m_easeInAndOut = tonumber(self:GetKeyValue("ease_in_and_out") or "1.0")
end
function ents.ParticleSystemComponent.OperatorColorFade:Simulate(pt,dt)
	-- TODO
end
function ents.ParticleSystemComponent.OperatorColorFade:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorColorFade:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorColorFade:OnParticleCreated(pt)
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorColorFade:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_operator("color fade",ents.ParticleSystemComponent.OperatorColorFade)
