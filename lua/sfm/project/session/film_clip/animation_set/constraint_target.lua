-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ConstraintTarget")
sfm.link_dmx_type("DmeConstraintTarget", sfm.ConstraintTarget)

sfm.register_element_type("RigHandle") -- Predeclaration

sfm.BaseElement.RegisterProperty(sfm.ConstraintTarget, "target", sfm.RigHandle)
sfm.BaseElement.RegisterAttribute(sfm.ConstraintTarget, "targetWeight", 1.0)
sfm.BaseElement.RegisterAttribute(sfm.ConstraintTarget, "vecOffset", Vector())
sfm.BaseElement.RegisterAttribute(sfm.ConstraintTarget, "oOffset", Quaternion())
