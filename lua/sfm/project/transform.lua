-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

sfm.register_element_type("Transform")
sfm.link_dmx_type("DmeTransform", sfm.Transform)

sfm.BaseElement.RegisterAttribute(sfm.Transform, "position", Vector())
sfm.BaseElement.RegisterAttribute(sfm.Transform, "orientation", Quaternion())
sfm.BaseElement.RegisterAttribute(sfm.Transform, "scale", 1.0)

function sfm.Transform:GetPose()
	local scale = 1.0
	return math.ScaledTransform(self:GetPosition(), self:GetOrientation(), Vector(scale, scale, scale))
end
