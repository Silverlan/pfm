--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("particle_system_definition.lua")

sfm.register_element_type("GameParticleSystem")
sfm.link_dmx_type("DmeGameParticleSystem",sfm.GameParticleSystem)

sfm.register_element_type("Transform") -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.GameParticleSystem,"transform",sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.GameParticleSystem,"overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"overridePos")
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"simulationTimeScale",0)
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"particleSystemType","")
sfm.BaseElement.RegisterProperty(sfm.GameParticleSystem,"particleSystemDefinition",sfm.ParticleSystemDefinition)
sfm.BaseElement.RegisterArray(sfm.GameParticleSystem,"controlPoints",sfm.Transform)
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"visible",false,{
	getterName = "IsVisible"
})
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"simulating",false,{
	getterName = "IsSimulating"
})
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem,"emitting",false,{
	getterName = "IsEmitting"
})
