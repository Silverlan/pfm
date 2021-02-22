--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("operator.lua")

fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION = fudm.register_element("PFMParticleSystemDefinition")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"renderers",fudm.Array(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"operators",fudm.Array(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"initializers",fudm.Array(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"emitters",fudm.Array(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"maxParticles",fudm.Int(0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"material",fudm.String())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"radius",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"lifetime",fudm.Float(0.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"color",fudm.Color(Color.White))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"sortParticles",fudm.Bool(false),{
	getter = "ShouldSortParticles"
})
