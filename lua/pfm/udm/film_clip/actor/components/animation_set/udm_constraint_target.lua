--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_rig_handle.lua")

fudm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET = fudm.register_element("PFMConstraintTarget")
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"target",fudm.PFMRigHandle())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"targetWeight",fudm.Float(1.0))
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"offset",fudm.Vector3())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET,"rotationOffset",fudm.Quaternion())

function fudm.PFMConstraintTarget:GetPose(applyTranslationOffset,applyRotationOffset)
	local target = self:GetTarget()
	local pose = (target ~= nil) and target:GetConstraintPose() or phys.Transform()
	if(applyTranslationOffset) then
		pose:TranslateGlobal(self:GetOffset())
	elseif(applyRotationOffset) then
		pose:RotateLocal(self:GetRotationOffset())
	end
	return pose
end
