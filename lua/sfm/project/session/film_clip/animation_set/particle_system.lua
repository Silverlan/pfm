-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("particle_system_definition.lua")

sfm.register_element_type("GameParticleSystem")
sfm.link_dmx_type("DmeGameParticleSystem", sfm.GameParticleSystem)

sfm.register_element_type("Transform") -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.GameParticleSystem, "transform", sfm.Transform)
sfm.BaseElement.RegisterProperty(sfm.GameParticleSystem, "overrideParent")
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "overridePos")
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "overrideRot")
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "simulationTimeScale", 0)
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "particleSystemType", "")
sfm.BaseElement.RegisterProperty(sfm.GameParticleSystem, "particleSystemDefinition", sfm.ParticleSystemDefinition)
sfm.BaseElement.RegisterArray(sfm.GameParticleSystem, "controlPoints", sfm.Transform)
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "visible", false, {
	getterName = "IsVisible",
})
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "simulating", false, {
	getterName = "IsSimulating",
})
sfm.BaseElement.RegisterAttribute(sfm.GameParticleSystem, "emitting", false, {
	getterName = "IsEmitting",
})
