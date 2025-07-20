-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/fonts.lua")

util.register_class("gui.CollapsibleGroupTitleBar", gui.Base)

function gui.CollapsibleGroupTitleBar:__init()
	gui.Base.__init(self)
end
function gui.CollapsibleGroupTitleBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 20)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents = gui.create("WIHBox", self, 0, 0, self:GetWidth(), 20)
	self.m_contents:SetAutoAlignToParent(true, false)
	self.m_contents:SetFixedWidth(true)
	self.m_bg:AddStyleClass("background")

	self.m_leftPadding = gui.create("WIBase", self.m_contents, 0, 0, 7, 1) -- Gap
	self.m_collapsed = false
	self.m_button = gui.create("WITexturedRect", self.m_contents)
	self.m_button:SetMouseInputEnabled(true)
	self.m_button:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			self:Toggle()
			return util.EVENT_REPLY_HANDLED
		end
	end)
	self.m_button:SetMaterial("gui/pfm/arrow_right")
	self.m_button:SetSize(5, 7)
	self.m_button:SetY(8)
	self.m_button:SetMouseInputEnabled(true)

	gui.create("WIBase", self.m_contents, 0, 0, 8, 1) -- Gap
	self.m_name = gui.create("WIText", self.m_contents, 0, 3)
	self.m_name:SetFont("pfm_medium")
	self.m_name:SetColor(Color(152, 152, 152))
end
function gui.CollapsibleGroupTitleBar:GetLeftPadding()
	return self.m_leftPaddingSz or 0
end
function gui.CollapsibleGroupTitleBar:SetLeftPadding(padding)
	self.m_leftPaddingSz = padding
	self.m_leftPadding:SetWidth(padding + 7)
end
function gui.CollapsibleGroupTitleBar:Collapse()
	self.m_collapsed = true
	if util.is_valid(self.m_button) then
		self.m_button:SetMaterial("gui/pfm/arrow_right")
		self.m_button:SetSize(5, 7)
	end
	self:CallCallbacks("OnCollapse")
end
function gui.CollapsibleGroupTitleBar:Expand()
	self.m_collapsed = false
	if util.is_valid(self.m_button) then
		self.m_button:SetMaterial("gui/pfm/arrow_down")
		self.m_button:SetSize(7, 5)
	end
	self:CallCallbacks("OnExpand")
end
function gui.CollapsibleGroupTitleBar:Toggle()
	if self.m_collapsed then
		self:Expand()
	else
		self:Collapse()
	end
end
function gui.CollapsibleGroupTitleBar:SetGroupName(name)
	if util.is_valid(self.m_name) then
		self.m_name:SetText(name)
		self.m_name:SizeToContents()
	end
end
gui.register("WICollapsibleGroupTitleBar", gui.CollapsibleGroupTitleBar)
