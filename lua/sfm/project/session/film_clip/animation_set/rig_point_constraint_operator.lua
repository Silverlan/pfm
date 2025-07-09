-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("RigPointConstraintOperator")
sfm.link_dmx_type("DmeRigPointConstraintOperator", sfm.RigPointConstraintOperator)

sfm.register_element_type("ConstraintTarget") -- Predeclaration
sfm.register_element_type("ConstraintSlave") -- Predeclaration

sfm.BaseElement.RegisterArray(sfm.RigPointConstraintOperator, "targets", sfm.ConstraintTarget)
sfm.BaseElement.RegisterProperty(sfm.RigPointConstraintOperator, "slave", sfm.ConstraintSlave)
