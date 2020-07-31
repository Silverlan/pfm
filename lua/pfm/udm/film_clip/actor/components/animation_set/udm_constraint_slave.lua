--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("udm_rig_handle.lua")

udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE = udm.register_element("PFMConstraintSlave")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE,"target",udm.PFMRigHandle())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE,"position",udm.Vector3())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_CONSTRAINT_SLAVE,"rotation",udm.Quaternion())

function udm.PFMConstraintSlave:ApplyConstraint(pose)
	local parent = self:FindParentElement(function(el) return el.IsRigConstaintOperator ~= nil and el:IsRigConstaintOperator() end)
	if(parent == nil) then return end
	parent:ApplyConstraint(pose)
end
