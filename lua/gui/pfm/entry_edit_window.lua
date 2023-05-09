--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("window.lua")

local PfmEditEntryWindow = util.register_class("gui.PfmEditEntryWindow", gui.PFMWindow)
function PfmEditEntryWindow:OnInitialize()
	gui.PFMWindow.OnInitialize(self)

	self:SetWindowSize(Vector2i(202, 160))

	local contents = self:GetContents()

	gui.create("WIBase", contents, 0, 0, 1, 12) -- Gap

	local t = gui.create("WITable", contents)
	t:RemoveStyleClass("WITable")
	t:SetWidth(self:GetWidth() - 13)
	t:SetRowHeight(28)
	self.m_table = t

	gui.create("WIBase", contents, 0, 0, 1, 3) -- Gap

	local boxButtons = gui.create("WIHBox", contents)

	local btOk = gui.create("WIButton", boxButtons)
	btOk:SetSize(73, 21)
	btOk:SetText(locale.get_text("ok"))
	btOk:AddCallback("OnMousePressed", function()
		if self:CallCallbacks("OnOk") == util.EVENT_REPLY_HANDLED then
			return
		end
		self:GetFrame():Remove()
	end)

	gui.create("WIBase", boxButtons, 0, 0, 8, 1) -- Gap

	local btCancel = gui.create("WIButton", boxButtons)
	btCancel:SetSize(73, 21)
	btCancel:SetText(locale.get_text("cancel"))
	btCancel:AddCallback("OnMousePressed", function()
		if self:CallCallbacks("OnCancel") == util.EVENT_REPLY_HANDLED then
			return
		end
		self:GetFrame():Remove()
	end)

	boxButtons:Update()
	boxButtons:SetX(contents:GetWidth() - boxButtons:GetWidth())
end
function PfmEditEntryWindow:GetTable()
	return self.m_table
end
function PfmEditEntryWindow:OnSizeChanged(w, h)
	gui.PFMWindow.OnSizeChanged(self, w, h)
	if util.is_valid(self.m_table) then
		self.m_table:SetWidth(self:GetWidth() - 13)
	end
end
function PfmEditEntryWindow:OnUpdate()
	gui.PFMWindow.OnUpdate(self)
	self.m_table:Update()
	self.m_table:SizeToContents()
end
function PfmEditEntryWindow:AddText(name, text)
	local row = self.m_table:AddRow()
	row:SetValue(0, name)

	local te = gui.create("WIText")
	te:SetText(text)
	te:SizeToContents()
	te:SetWidth(self:GetWidth())
	row:InsertElement(1, te)
	return te
end
function PfmEditEntryWindow:AddTextField(name, value)
	local row = self.m_table:AddRow()
	row:SetValue(0, name)

	local textEntry = gui.create("WITextEntry")
	textEntry:SetWidth(self:GetWidth())
	textEntry:SetText(value)
	row:InsertElement(1, textEntry)
	return textEntry
end
function PfmEditEntryWindow:AddNumericEntryField(name, value)
	local row = self.m_table:AddRow()
	row:SetValue(0, name)

	local textEntry = gui.create("WINumericEntry")
	textEntry:SetWidth(self:GetWidth())
	textEntry:SetText(value)
	row:InsertElement(1, textEntry)
	return textEntry
end
pfm.open_entry_edit_window = function(title, cb)
	local p = gui.create("WIPFMEntryEditWindow")
	p:SetTitle(title)
	if cb ~= nil then
		p:AddCallback("OnOk", function()
			return cb(true)
		end)
		p:AddCallback("OnCancel", function()
			return cb(false)
		end)
	end
	return p
end
pfm.open_single_value_edit_window = function(title, cb, def)
	local te
	local p = pfm.open_entry_edit_window(title, function(ok)
		if ok then
			cb(ok, te:GetText())
		else
			cb(false)
		end
	end)
	te = p:AddTextField(title .. ":", def or "")
	te:GetTextElement():SetFont("pfm_medium")

	p:SetWindowSize(Vector2i(800, 120))
	p:Update()
	return p, te
end
gui.register("WIPFMEntryEditWindow", PfmEditEntryWindow)
