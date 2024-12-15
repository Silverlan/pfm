--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Wrapper = util.register_class("pfm.util.ControlWrapper.Enum", pfm.util.ControlWrapper)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	local idx = self.m_controlElement:FindOptionIndex(tostring(val))
	if idx ~= nil then
		self.m_controlElement:SelectOption(idx)
	else
		self.m_controlElement:SetText(tostring(val))
	end
end
function Wrapper:GetControlElementValue()
	return tonumber(self.m_controlElement:GetOptionValue(self.m_controlElement:GetSelectedOption()))
end
function Wrapper:SetEnumValues(values)
	self.m_enumValues = values
end
function Wrapper:InitializeElement()
	local defaultValueIndex
	if self.m_defaultValue ~= nil then
		for i, eval in ipairs(self.m_enumValues) do
			if eval[1] == tostring(self.m_defaultValue) then
				defaultValueIndex = eval[1]
				break
			end
		end
	end
	local el, wrapper = self.m_elControls:AddDropDownMenu(
		self.m_localizedText,
		self.m_identifier,
		self.m_enumValues,
		tostring(defaultValueIndex or 0),
		function(el)
			self:OnControlValueChanged(self:GetControlElementValue(), true)
			if self.m_skipUpdateCallback then
				return
			end
		end
	)
	wrapper:SetUseAltMode(true)
	self.m_wrapper = wrapper
	self.m_controlElement = el
	return wrapper, el
end
