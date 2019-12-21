--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("particle_system")

udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM = udm.register_element("PFMParticleSystem")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"timeScale",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_PARTICLE_SYSTEM,"definition",udm.PFMParticleSystemDefinition())

function udm.PFMParticleSystem:GetComponentName() return "pfm_particle_system" end
function udm.PFMParticleSystem:GetIconMaterial() return "gui/pfm/icon_particle_item" end
