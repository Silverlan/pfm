--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("entity.lua")

local Wrapper = util.register_class("pfm.util.ControlWrapper.ComponentProperty", pfm.util.ControlWrapper.Entity)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.Entity.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	local path = val:GetPath()
	if path ~= nil then
		self.m_controlElement:SetText(path)
	else
		self.m_controlElement:SetText("-")
	end
end
function Wrapper:GetControlElementValue()
	return ents.UniversalMemberReference(util.Uuid(self.m_controlElement:GetText()))
end
