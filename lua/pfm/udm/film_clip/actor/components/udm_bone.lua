--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_BONE = udm.register_element("PFMBone")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_BONE,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_BONE,"childBones",udm.Array(udm.ELEMENT_TYPE_PFM_BONE))

function udm.PFMBone:GetModelComponent()
	local parent = self:FindParentElement()
	if(parent == nil) then return end
	if(parent:GetType() == udm.ELEMENT_TYPE_PFM_BONE) then return parent:GetModelComponent() end
	if(parent:GetType() == udm.ELEMENT_TYPE_PFM_MODEL) then return parent end
end
