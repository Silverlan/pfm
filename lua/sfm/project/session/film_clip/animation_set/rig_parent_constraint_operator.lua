-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("RigParentConstraintOperator")
sfm.link_dmx_type("DmeRigParentConstraintOperator", sfm.RigParentConstraintOperator)

sfm.register_element_type("ConstraintTarget") -- Predeclaration
sfm.register_element_type("ConstraintSlave") -- Predeclaration

sfm.BaseElement.RegisterArray(sfm.RigParentConstraintOperator, "targets", sfm.ConstraintTarget)
sfm.BaseElement.RegisterProperty(sfm.RigParentConstraintOperator, "slave", sfm.ConstraintSlave)
