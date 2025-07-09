-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
