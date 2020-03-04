--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.ParticleSystemComponent.Test",ents.ParticleSystemComponent.BaseInitializer)

function ents.ParticleSystemComponent.Test:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.Test:Initialize()
	--print("[Particle Initializer] Initialize")
end
function ents.ParticleSystemComponent.Test:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.Test:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.Test:OnParticleCreated(pt)
	pt:SetAnimationFrameOffset(math.randomf(0,1))
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.Test:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
ents.ParticleSystemComponent.register_initializer("test",ents.ParticleSystemComponent.Test)

--

util.register_class("ents.ParticleSystemComponent.OperatorSine",ents.ParticleSystemComponent.BaseOperator)
function ents.ParticleSystemComponent.OperatorSine:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorSine:Simulate(pt,dt)
	local t = math.sin(time.cur_time() *(math.pi /2.0))
	local pos = pt:GetPosition()
	pos.y = pos.y +t *500.0 *dt
	pt:SetPosition(pos)
	pt:SetVelocity(Vector(-500,0,0))
end
ents.ParticleSystemComponent.register_operator("sine",ents.ParticleSystemComponent.OperatorSine)

---

util.register_class("ents.ParticleSystemComponent.RandomInitialFrame",ents.ParticleSystemComponent.BaseInitializer)
function ents.ParticleSystemComponent.RandomInitialFrame:__init()
	ents.ParticleSystemComponent.BaseInitializer.__init(self)
end
function ents.ParticleSystemComponent.RandomInitialFrame:OnParticleCreated(pt)
	pt:SetAnimationFrameOffset(math.randomf(0,55))
end
ents.ParticleSystemComponent.register_initializer("random_initial_frame",ents.ParticleSystemComponent.RandomInitialFrame)

---

util.register_class("ents.ParticleSystemComponent.OperatorAnimation",ents.ParticleSystemComponent.BaseOperator)
function ents.ParticleSystemComponent.OperatorAnimation:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorAnimation:Simulate(pt,dt)
	pt:SetAnimationFrameOffset(pt:GetAnimationFrameOffset() +dt *4)
end
ents.ParticleSystemComponent.register_operator("animation",ents.ParticleSystemComponent.OperatorAnimation)

---

util.register_class("ents.ParticleSystemComponent.OperatorFlamethrower",ents.ParticleSystemComponent.BaseOperator)
function ents.ParticleSystemComponent.OperatorFlamethrower:__init()
	ents.ParticleSystemComponent.BaseOperator.__init(self)
end
function ents.ParticleSystemComponent.OperatorFlamethrower:OnParticleSystemStarted(pt)
	--print("[Particle Initializer] On particle system started")
end
function ents.ParticleSystemComponent.OperatorFlamethrower:OnParticleSystemStopped(pt)
	--print("[Particle Initializer] On particle system stopped")
end
function ents.ParticleSystemComponent.OperatorFlamethrower:OnParticleCreated(pt)
	--pt:SetAnimationFrameOffset(math.randomf(0,1))
	--print("[Particle Initializer] On particle created")
end
function ents.ParticleSystemComponent.OperatorFlamethrower:OnParticleDestroyed(pt)
	--print("[Particle Initializer] On particle destroyed")
end
function ents.ParticleSystemComponent.OperatorFlamethrower:Simulate(pt,dt)
	local gravity = Vector(250,0,0) *dt
	pt:SetVelocity(pt:GetVelocity() +gravity +Vector(0,-500,0) *dt)
end
ents.ParticleSystemComponent.register_operator("flamethrower",ents.ParticleSystemComponent.OperatorFlamethrower)

include("movement_basic.lua")

-- lua_exec_cl particle_system/initializer_test.lua
