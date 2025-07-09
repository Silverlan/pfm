-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("ExpressionOperator")
sfm.link_dmx_type("DmeExpressionOperator", sfm.ExpressionOperator)

sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator, "result", 0)
sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator, "expr", "")
sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator, "spewresult", false)
sfm.BaseElement.RegisterAttribute(sfm.ExpressionOperator, "value", 0)
