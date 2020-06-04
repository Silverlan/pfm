--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("ParticleChild")
sfm.link_dmx_type("DmeParticleChild",sfm.ParticleChild)

sfm.BaseElement.RegisterAttribute(sfm.ParticleChild,"name")
sfm.BaseElement.RegisterAttribute(sfm.ParticleChild,"child")
sfm.BaseElement.RegisterAttribute(sfm.ParticleChild,"delay",0)
