--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("operator.lua")

udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION = udm.register_element("PFMParticleSystemDefinition")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"renderers",udm.Array(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"operators",udm.Array(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"initializers",udm.Array(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"emitters",udm.Array(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_OPERATOR))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"maxParticles",udm.Int(0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"material",udm.String())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"radius",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"lifetime",udm.Float(0.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"color",udm.Color(Color.White))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM_DEFINITION,"sortParticles",udm.Bool(false),{
	getter = "ShouldSortParticles"
})
