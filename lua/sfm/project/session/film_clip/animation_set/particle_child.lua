-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ParticleChild")
sfm.link_dmx_type("DmeParticleChild", sfm.ParticleChild)

sfm.BaseElement.RegisterAttribute(sfm.ParticleChild, "name")
sfm.BaseElement.RegisterAttribute(sfm.ParticleChild, "child")
sfm.BaseElement.RegisterAttribute(sfm.ParticleChild, "delay", 0)
