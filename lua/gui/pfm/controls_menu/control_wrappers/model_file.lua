-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("file.lua")

local Wrapper = util.register_class("pfm.util.ControlWrapper.ModelFile", pfm.util.ControlWrapper.File)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.File.__init(self, elControls, identifier)
end
function Wrapper:InitializeElement()
	local el, wrapper, container = self.m_elControls:AddFileEntry(
		self.m_localizedText,
		self.m_identifier,
		self:ToInterfaceValue(self.m_defaultValue or ""),
		function(resultHandler)
			gui.open_model_dialog(function(dialogResult, mdlName)
				if dialogResult ~= gui.DIALOG_RESULT_OK then
					return
				end
				resultHandler(mdlName)
			end)
		end,
		function(el)
			self:OnControlValueChanged(self:GetControlElementValue(), true)
		end
	)
	self.m_wrapper = wrapper
	self.m_container = container
	self.m_controlElement = el
	return wrapper, el
end
