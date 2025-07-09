-- SPDX-FileCopyrightText: (c) 2021 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("PackColorOperator")
sfm.link_dmx_type("DmePackColorOperator", sfm.PackColorOperator)

sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator, "red", 1)
sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator, "green", 1)
sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator, "blue", 1)
sfm.BaseElement.RegisterAttribute(sfm.PackColorOperator, "alpha", 1)
