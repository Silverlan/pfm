-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("RigHandle")
sfm.link_dmx_type("DmeRigHandle", sfm.RigHandle)

sfm.BaseElement.RegisterProperty(sfm.RigHandle, "transform", sfm.Transform)
