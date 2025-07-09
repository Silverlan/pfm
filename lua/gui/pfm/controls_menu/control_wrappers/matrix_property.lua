-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("vector_property.lua")

local Wrapper = util.register_class("pfm.util.ControlWrapper.MatrixProperty", pfm.util.ControlWrapper.VectorProperty)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.VectorProperty.__init(self, elControls, identifier)
end
