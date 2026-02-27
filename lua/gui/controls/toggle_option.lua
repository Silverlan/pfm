-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.ToggleOption", gui.Base)

function gui.ToggleOption:__init()
	gui.Base.__init(self)
end
function gui.ToggleOption:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 18)

	self.m_contents = gui.create("hbox", self, 0, 0, self:GetWidth(), self:GetHeight())
	self.m_contents:SetFixedWidth(true)
	self.m_contents:SetAutoAlignToParent(true, false)
	self.m_checkbox = gui.create("WICheckbox", self.m_contents)
	gui.create("WIBase", self.m_contents, 0, 0, 5, 1) -- Gap
	self.m_label = gui.create("WIText", self.m_contents)
	self.m_label:SetColor(Color.White)
	self.m_label:SetFont("pfm_medium")
	self.m_label:SetY(2)
end
function gui.ToggleOption:SetChecked(checked)
	self.m_checkbox:SetChecked(checked)
end
function gui.ToggleOption:IsChecked()
	return self.m_checkbox:IsChecked()
end
function gui.ToggleOption:GetCheckbox()
	return self.m_checkbox
end
function gui.ToggleOption:Toggle()
	self.m_checkbox:Toggle()
end
function gui.ToggleOption:SetText(text)
	self.m_label:SetText(text)
	self.m_label:SizeToContents()
end
function gui.ToggleOption:GetText()
	return self.m_label:GetText()
end
gui.register("toggle_option", gui.ToggleOption)
