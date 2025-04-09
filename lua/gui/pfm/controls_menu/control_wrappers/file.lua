--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("string.lua")

local Wrapper = util.register_class("pfm.util.ControlWrapper.File", pfm.util.ControlWrapper.String)
function Wrapper:__init(elControls, identifier)
	pfm.util.ControlWrapper.String.__init(self, elControls, identifier)
end
function Wrapper:SetControlElementValue(val)
	self.m_controlElement:SetValue(tostring(val))
end
function Wrapper:GetControlElementValue()
	return self.m_controlElement:GetValue()
end
function Wrapper:SetBasePath(basePath)
	self.m_basePath = basePath
end
function Wrapper:SetRootPath(rootPath)
	self.m_rootPath = rootPath
end
function Wrapper:SetExtensions(exts)
	self.m_extensions = exts
end
function Wrapper:InitializeElement()
	local el, wrapper, container = self.m_elControls:AddFileEntry(
		self.m_localizedText,
		self.m_identifier,
		self:ToInterfaceValue(self.m_defaultValue or ""),
		function(resultHandler)
			local pFileDialog = pfm.create_file_open_dialog(function(el, fileName)
				if fileName == nil then
					return
				end
				local basePath = self.m_basePath or ""
				resultHandler(basePath .. el:GetFilePath(true))
			end)
			if self.m_rootPath ~= nil then
				pFileDialog:SetRootPath(self.m_rootPath)
			end
			if self.m_extensions ~= nil and #self.m_extensions > 0 then
				pFileDialog:SetExtensions(self.m_extensions)
			end
			pFileDialog:Update()
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
