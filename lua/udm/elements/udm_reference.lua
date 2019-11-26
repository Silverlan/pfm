--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

udm.ELEMENT_TYPE_REFERENCE = udm.register_element("Reference")
udm.register_element_property(udm.ELEMENT_TYPE_REFERENCE,"target",udm.ELEMENT_TYPE_ANY)

function udm.Reference:Initialize(name,target)
	udm.BaseElement.Initialize(self,name,target)
	self:SetTarget(target)
end

udm.create_reference = function(target)
	return udm.Reference(target:GetName(),target)
end
