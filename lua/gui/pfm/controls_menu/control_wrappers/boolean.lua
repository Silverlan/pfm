-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Wrapper = util.register_class("pfm.util.ControlWrapper.Boolean", pfm.util.ControlWrapper)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	self.m_controlElement:SetChecked(val)
end
function Wrapper:GetControlElementValue()
	return self.m_controlElement:IsChecked()
end
function Wrapper:InitializeElement()
	local elToggle, wrapper, container = self.m_elControls:AddToggleControl(
		self.m_localizedText,
		self.m_identifier,
		self:ToInterfaceValue(self.m_defaultValue or false),
		function(oldChecked, checked)
			self:OnControlValueChanged(self:GetControlElementValue(), true)
		end
	)
	self.m_wrapper = wrapper
	self.m_container = container
	self.m_controlElement = elToggle
	return wrapper, elToggle
end
