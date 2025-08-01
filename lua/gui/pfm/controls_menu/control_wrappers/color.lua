-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Wrapper = util.register_class("pfm.util.ControlWrapper.Color", pfm.util.ControlWrapper)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	self.m_controlElement:SetColor(Color(val))
end
function Wrapper:GetControlElementValue()
	return self.m_controlElement:GetColor():ToVector()
end
function Wrapper:InitializeElement()
	local initialValue
	local colField, wrapper, container = self.m_elControls:AddColorField(
		self.m_localizedText,
		self.m_identifier,
		(self.m_defaultValue ~= nil) and Color(self.m_defaultValue) or Color.White,
		function(oldCol, newCol)
			self:OnControlValueChanged(self:GetControlElementValue(), false)
		end
	)
	colField:AddCallback("OnUserInputStarted", function()
		initialValue = colField:GetColor()
	end)
	colField:AddCallback("OnUserInputEnded", function()
		self:OnControlValueChanged(self:GetControlElementValue(), true, initialValue)
		initialValue = nil
	end)

	self.m_wrapper = wrapper
	self.m_container = container
	self.m_controlElement = colField
	return wrapper, colField
end
