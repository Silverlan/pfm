-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Wrapper = util.register_class("pfm.util.ControlWrapper.VectorProperty", pfm.util.ControlWrapper)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.__init(self, elControls, identifier)
end
function Wrapper:SetUdmType(type)
	self.m_udmType = type
end
function Wrapper:SetControlElementValue(val)
	self.m_controlElement:SetText(tostring(val))
end
function Wrapper:GetControlElementValue()
	local type = udm.get_class_type(self.m_udmType)
	return type(self.m_controlElement:GetText())
end
function Wrapper:InitializeElement()
	local type = udm.get_class_type(self.m_udmType)
	local el, wrapper, container = self.m_elControls:AddTextEntry(
		self.m_localizedText,
		self.m_identifier,
		self:ToInterfaceValue(self.m_defaultValue or type()),
		function(el)
			self:OnControlValueChanged(self:GetControlElementValue(), true)
		end
	)
	self.m_wrapper = wrapper
	self.m_container = container
	self.m_controlElement = el
	return wrapper, el
end
