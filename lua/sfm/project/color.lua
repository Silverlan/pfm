-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("Color")
sfm.link_dmx_type("DmeColor", sfm.Color)

sfm.BaseElement.RegisterAttribute(sfm.Color, "color", Color())
