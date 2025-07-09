-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ParticleSystemOperator")
sfm.link_dmx_type("DmeParticleOperator", sfm.ParticleSystemOperator)

sfm.BaseElement.RegisterAttribute(sfm.ParticleSystemOperator, "functionName", "")
