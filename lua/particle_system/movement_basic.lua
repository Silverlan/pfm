--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.MovementBasic",ents.ParticleSystemComponent.BaseOperator)

function ents.ParticleSystemComponent.MovementBasic:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.MovementBasic:Simulate(pt,dt)
	local drag = 0.115 -- TODO
	local vel = pt:GetVelocity()
	drag = (1.0 -drag)
	vel = vel *drag
	--[drag]: 0.11500000208616 of type Float

	local gravity = Vector(0,20,0) *dt
	vel = vel +gravity

	pt:SetVelocity(vel)
end
ents.ParticleSystemComponent.register_operator("movement_basic",ents.ParticleSystemComponent.MovementBasic)
