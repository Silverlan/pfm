--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.ToggleOption",gui.Base)

function gui.ToggleOption:__init()
	gui.Base.__init(self)
end
function gui.ToggleOption:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,18)

	self.m_contents = gui.create("WIHBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_checkbox = gui.create("WICheckbox",self.m_contents)
	gui.create("WIBase",self.m_contents,0,0,5,1) -- Gap
	self.m_label = gui.create("WIText",self.m_contents)
	self.m_label:SetColor(Color.White)
	self.m_label:SetFont("pfm_medium")
	self.m_label:SetY(2)
end
function gui.ToggleOption:SetChecked(checked) self.m_checkbox:SetChecked(checked) end
function gui.ToggleOption:IsChecked() return self.m_checkbox:IsChecked() end
function gui.ToggleOption:Toggle() self.m_checkbox:Toggle() end
function gui.ToggleOption:SetText(text)
	self.m_label:SetText(text)
	self.m_label:SizeToContents()
end
function gui.ToggleOption:GetText() return self.m_label:GetText() end
gui.register("WIToggleOption",gui.ToggleOption)
