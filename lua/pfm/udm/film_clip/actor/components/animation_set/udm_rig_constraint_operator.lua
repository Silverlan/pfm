--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("fudm.PFMRigConstraintOperator",fudm.BaseElement)
function fudm.PFMRigConstraintOperator:__init(...)
	fudm.BaseElement.__init(self,...)
end

function fudm.PFMRigConstraintOperator:IsRigConstaintOperator() return true end
