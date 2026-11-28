-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/ui/fonts.lua")

util.register_class("gui.CollapsibleGroupTitleBar", gui.Base)
function gui.CollapsibleGroupTitleBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetAutoSizeToContents(true)
	self.m_contents = gui.create_hbox(self)
	self.m_contents:AddStyleClass("collapsible-panel-title-bar")

	self.m_collapsed = false
	self.m_button = gui.create("WIBase", self.m_contents)
	self.m_button:SetMouseInputEnabled(true)
	self.m_button:AddCallback("OnMouseEvent", function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
			self:Toggle()
			return util.EVENT_REPLY_HANDLED
		end
	end)
	self.m_button:AddStyleClass("collapsible-panel__button")
	self.m_button:AddStyleClass("collapsible-panel__button--collapsed")
	self.m_button:SetMouseInputEnabled(true)
	
	self.m_name = gui.create("WIText", self.m_contents)
end
function gui.CollapsibleGroupTitleBar:Collapse()
	self.m_collapsed = true
	if util.is_valid(self.m_button) then
		self.m_button:RemoveStyleClass("collapsible-panel__button--expanded")
		self.m_button:AddStyleClass("collapsible-panel__button--collapsed")
		self.m_button:RefreshSkin()
	end
	self:CallCallbacks("OnCollapse")
end
function gui.CollapsibleGroupTitleBar:Expand()
	self.m_collapsed = false
	if util.is_valid(self.m_button) then
		self.m_button:RemoveStyleClass("collapsible-panel__button--collapsed")
		self.m_button:AddStyleClass("collapsible-panel__button--expanded")
		self.m_button:RefreshSkin()
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
	end
end
gui.register("collapsible_group_title_bar", gui.CollapsibleGroupTitleBar)
