--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_rig_handle.lua")

udm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET = udm.register_element("PFMConstraintTarget")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"target",udm.PFMRigHandle())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"targetWeight",udm.Float(1.0))
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"offset",udm.Vector3())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"rotationOffset",udm.Quaternion())

function udm.PFMConstraintTarget:GetPose(applyTranslationOffset,applyRotationOffset)
	local target = self:GetTarget()
	local pose = (target ~= nil) and target:GetConstraintPose() or phys.Transform()
	if(applyTranslationOffset) then
		pose:TranslateGlobal(self:GetOffset())
	elseif(applyRotationOffset) then
		pose:RotateLocal(self:GetRotationOffset())
	end
	return pose
end
