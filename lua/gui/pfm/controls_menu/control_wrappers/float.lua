-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Wrapper = util.register_class("pfm.util.ControlWrapper.Float", pfm.util.ControlWrapper)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	self.m_controlElement:SetValue(val)
end
function Wrapper:GetControlElementValue()
	return self.m_controlElement:GetValue()
end
function Wrapper:SetMin(min)
	self.m_min = min
end
function Wrapper:SetMax(max)
	self.m_max = max
end
function Wrapper:SetInteger(integer)
	self.m_integer = integer
end
function Wrapper:SetUnit(unit)
	self.m_unit = unit
end
function Wrapper:InitializeElement()
	local slider, wrapper, container = self.m_elControls:AddSliderControl(
		self.m_localizedText,
		self.m_identifier,
		self:ToInterfaceValue(self.m_defaultValue or 0.0),
		self:ToInterfaceValue(self.m_min or 0.0),
		self:ToInterfaceValue(self.m_max or 100.0),
		nil,
		nil,
		self.m_integer or false
	)
	local wrapper = slider
	local initialValue
	slider:AddCallback("OnUserInputStarted", function(el, value)
		initialValue = value
	end)
	slider:AddCallback("OnUserInputEnded", function(el, value)
		self:OnControlValueChanged(self:GetControlElementValue(), true, initialValue)
		initialValue = nil
	end)
	slider:AddCallback("OnLeftValueChanged", function(el, value)
		self:OnControlValueChanged(self:GetControlElementValue(), false)
	end)
	if self.m_unit ~= nil then
		slider:SetUnit(self.m_unit)
	end
	self.m_wrapper = wrapper
	self.m_container = container
	self.m_controlElement = slider
	return wrapper, slider
end
