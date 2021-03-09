--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

fudm.ELEMENT_TYPE_REFERENCE = fudm.register_element("Reference")
fudm.register_element_property(fudm.ELEMENT_TYPE_REFERENCE,"target",fudm.ELEMENT_TYPE_ANY)

function fudm.Reference:Initialize(name,target)
	fudm.BaseElement.Initialize(self,name,target)
	self:SetTarget(target)
end

fudm.create_reference = function(target)
	return fudm.Reference(target:GetName(),target)
end
