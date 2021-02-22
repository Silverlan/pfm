--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_entity_component.lua")
include("particle_system")

fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM = fudm.register_type("PFMParticleSystem",{fudm.PFMEntityComponent},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"timeScale",fudm.Float(1.0))
-- TODO: 'definition' field is obsolete, remove it! Particle definitions are ALWAYS stored in separate particle system files.
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"definition",fudm.PFMParticleSystemDefinition())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"particleSystemName",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"controlPoints",fudm.Array(fudm.ELEMENT_TYPE_PFM_TRANSFORM))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"simulating",fudm.Bool(true),{
	getter = "IsSimulating"
})
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"emitting",fudm.Bool(true),{
	getter = "IsEmitting"
})

function fudm.PFMParticleSystem:GetComponentName() return "pfm_particle_system" end
function fudm.PFMParticleSystem:GetIconMaterial() return "gui/pfm/icon_particle_item" end
