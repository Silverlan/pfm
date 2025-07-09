-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("particle_system_operator.lua")

sfm.register_element_type("ParticleSystemDefinition")
sfm.link_dmx_type("DmeParticleSystemDefinition", sfm.ParticleSystemDefinition)

include("particle_child.lua")

sfm.BaseElement.RegisterArray(sfm.ParticleSystemDefinition, "renderers", sfm.ParticleSystemOperator)
sfm.BaseElement.RegisterArray(sfm.ParticleSystemDefinition, "operators", sfm.ParticleSystemOperator)
sfm.BaseElement.RegisterArray(sfm.ParticleSystemDefinition, "initializers", sfm.ParticleSystemOperator)
sfm.BaseElement.RegisterArray(sfm.ParticleSystemDefinition, "emitters", sfm.ParticleSystemOperator)
sfm.BaseElement.RegisterArray(sfm.ParticleSystemDefinition, "children", sfm.ParticleChild)
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "max_particles", 0, {
	getterName = "GetMaxParticles",
	setterName = "SetMaxParticles",
})
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "initial_particles", 0, {
	getterName = "GetInitialParticles",
	setterName = "SetInitialParticles",
})
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "material", "")
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "radius", 0)
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "lifetime", 0)
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "color", Color())
sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemDefinition, "sort_particles", false, {
	getterName = "ShouldSortParticles",
	setterName = "SetSortParticles",
})
