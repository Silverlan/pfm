-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ConstraintSlave")
sfm.link_dmx_type("DmeConstraintSlave", sfm.ConstraintSlave)

sfm.BaseElement.RegisterProperty(sfm.ConstraintSlave, "target", sfm.Dag)
sfm.BaseElement.RegisterAttribute(sfm.ConstraintSlave, "position", Vector())
sfm.BaseElement.RegisterAttribute(sfm.ConstraintSlave, "orientation", Quaternion())
