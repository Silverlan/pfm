-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("RigOrientConstraintOperator")
sfm.link_dmx_type("DmeRigOrientConstraintOperator", sfm.RigOrientConstraintOperator)

sfm.register_element_type("ConstraintTarget") -- Predeclaration
sfm.register_element_type("ConstraintSlave") -- Predeclaration

sfm.BaseElement.RegisterArray(sfm.RigOrientConstraintOperator, "targets", sfm.ConstraintTarget)
sfm.BaseElement.RegisterProperty(sfm.RigOrientConstraintOperator, "slave", sfm.ConstraintSlave)
