--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_PFM_GROUP = udm.register_element("PFMGroup")
udm.register_element_property(udm.ELEMENT_TYPE_PFM_GROUP,"transform",udm.Transform())
udm.register_element_property(udm.ELEMENT_TYPE_PFM_GROUP,"visible",udm.Bool(false),{
	getter = "IsVisible"
})

function udm.PFMGroup:Initialize()
	udm.BaseElement.Initialize(self)
end

function udm.PFMGroup:IsAbsoluteVisible()
	if(self:IsVisible() == false) then return false end
	local parent = self:FindParentElement()
	if(parent == nil or parent.IsAbsoluteVisible == nil) then return true end
	return parent:IsAbsoluteVisible()
end
