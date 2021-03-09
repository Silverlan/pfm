--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_constraint_target.lua")
include("udm_constraint_slave.lua")
include("udm_rig_constraint_operator.lua")

fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR = fudm.register_type("PFMRigPointConstraintOperator",{fudm.PFMRigConstraintOperator},true)
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR,"slave",fudm.PFMConstraintSlave())
fudm.register_element_property(fudm.ELEMENT_TYPE_PFM_RIG_POINT_CONSTRAINT_OPERATOR,"targets",fudm.Array(fudm.ELEMENT_TYPE_PFM_CONSTRAINT_TARGET))

function fudm.PFMRigPointConstraintOperator:ApplyConstraint(pose)
	-- TODO: Include all targets and take weights into account!!
	local targets = self:GetTargets()
	local target = targets:Get(1)
	local targetPose = (target ~= nil) and target:GetPose(true,false) or phys.Transform()
	pose:SetOrigin(targetPose:GetOrigin())
end
