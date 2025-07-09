-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("Material")
sfm.link_dmx_type("DmeMaterial", sfm.Material)

sfm.BaseElement.RegisterAttribute(sfm.Material, "mtlName", "")
sfm.BaseElement.RegisterAttribute(sfm.Material, "$basetexture", "")
