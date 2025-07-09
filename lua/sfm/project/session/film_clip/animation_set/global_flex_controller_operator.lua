-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("GlobalFlexControllerOperator")
sfm.link_dmx_type("DmeGlobalFlexControllerOperator", sfm.GlobalFlexControllerOperator)

sfm.BaseElement.RegisterAttribute(sfm.GlobalFlexControllerOperator, "flexWeight", 0.0)
sfm.BaseElement.RegisterProperty(
	sfm.GlobalFlexControllerOperator,
	"gameModel",
	sfm.GameModel,
	nil,
	sfm.BaseElement.PROPERTY_FLAG_BIT_OPTIONAL
)
