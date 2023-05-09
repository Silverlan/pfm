--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.FileEntry", gui.Base)

function gui.FileEntry:__init()
	gui.Base.__init(self)
end
function gui.FileEntry:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 28)

	local browseButton = gui.create("WIButton", self)
	browseButton:SetText("...")
	browseButton:SetX(self:GetWidth() - browseButton:GetWidth())
	browseButton:SetHeight(self:GetHeight())
	browseButton:SetAnchor(1, 0, 1, 1)
	browseButton:AddCallback("OnPressed", function()
		if self.m_fBrowseHandler ~= nil then
			self.m_fBrowseHandler(function(result)
				self:SetValue(result)
			end)
		end
		return util.EVENT_REPLY_HANDLED
	end)
	self.m_browseButton = browseButton

	local textEntry = gui.create("WITextEntry", self)
	textEntry:SetHeight(self:GetHeight())
	textEntry:SetWidth(browseButton:GetX() - 5)
	textEntry:SetAnchor(0, 0, 1, 1)
	textEntry:AddCallback("OnTextEntered", function(el)
		self:SetValue(el:GetText())
	end)
	self.m_textEntry = textEntry
end
function gui.FileEntry:SetValue(value)
	self.m_textEntry:SetText(value)
	self:CallCallbacks("OnValueChanged", value)
end
function gui.FileEntry:GetValue()
	return self.m_textEntry:GetText()
end
function gui.FileEntry:OnFocusGained()
	if util.is_valid(self.m_textEntry) then
		self.m_textEntry:RequestFocus()
	end
end
function gui.FileEntry:GetTextEntry()
	return self.m_textEntry
end
function gui.FileEntry:GetBrowseButton()
	return self.m_browseButton
end
function gui.FileEntry:SetBrowseHandler(fBrowseHandler)
	self.m_fBrowseHandler = fBrowseHandler
end
gui.register("WIFileEntry", gui.FileEntry)
