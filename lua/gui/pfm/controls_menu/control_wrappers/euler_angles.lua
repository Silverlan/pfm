--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Wrapper = util.register_class("pfm.util.ControlWrapper.EulerAngles", pfm.util.ControlWrapper)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	self.m_controlElement:SetText(tostring(val))
end
function Wrapper:GetControlElementValue()
	return EulerAngles(self.m_controlElement:GetText())
end
function Wrapper:InitializeElement()
	local el, wrapper, container = self.m_elControls:AddTextEntry(
		self.m_localizedText,
		self.m_identifier,
		self:ToInterfaceValue(self.m_defaultValue or EulerAngles()),
		function(el)
			self:OnControlValueChanged(self:GetControlElementValue(), true)
		end
	)
	self.m_wrapper = wrapper
	self.m_container = container
	self.m_controlElement = el
	return wrapper, el
end
