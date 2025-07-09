-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.ParticleSystemComponent.MovementBasic", ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.MovementBasic:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.MovementBasic:Simulate(pt, dt)
	local drag = 0.115 -- TODO
	local vel = pt:GetVelocity()
	drag = (1.0 - drag)
	vel = vel * drag
	--[drag]: 0.11500000208616 of type Float

	local gravity = Vector(0, 20, 0) * dt
	vel = vel + gravity

	pt:SetVelocity(vel)
end
ents.ParticleSystemComponent.register_operator("movement_basic", ents.ParticleSystemComponent.MovementBasic)
