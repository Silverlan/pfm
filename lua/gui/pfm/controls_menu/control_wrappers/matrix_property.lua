--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("vector_property.lua")

local Wrapper = util.register_class("pfm.util.ControlWrapper.MatrixProperty", pfm.util.ControlWrapper.VectorProperty)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.VectorProperty.__init(self, elControls, identifier)
end
