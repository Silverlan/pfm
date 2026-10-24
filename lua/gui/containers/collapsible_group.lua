-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("collapsible_group_titlebar.lua")
include("/gui/pfm/controls/button.lua")

util.register_class("gui.CollapsibleGroup", gui.Base)

function gui.CollapsibleGroup:OnInitialize()
	gui.Base.OnInitialize(self)

	self:ApplySize(256, 20)
	self.m_base = gui.create_vbox(self)
		:SetName("global_container")
		:AddStyleClass("collapsible-panel__content-area")

	self.m_titleBar =
		gui.create("collapsible_group_title_bar", self.m_base)
		:SetName("titlebar")
	self.m_titleBar:AddCallback("OnCollapse", function()
		self:OnCollapse()
	end)
	self.m_titleBar:AddCallback("OnExpand", function()
		self:OnExpand()
	end)

	self.m_contents = gui.create_vbox(self.m_base)
		:SetName("inner_contents")

	self.m_subGroups = {}
	self:Collapse()
	self:SetAutoSizeToContents(false, true)
end
function gui.CollapsibleGroup:RemoveGroup(groupName)
	for i, group in ipairs(self.m_subGroups) do
		if group:IsValid() and group:GetGroupName() == groupName then
			group:Remove()
			table.remove(self.m_subGroups, i)
			break
		end
	end
end
function gui.CollapsibleGroup:AddGroup(groupName)
	if util.is_valid(self.m_contents) == false then
		return
	end
	local p = gui.create("collapsible_group", self.m_contents)
		:SetName("group_" .. groupName)
		:AddStyleClass("collapsible-panel--sub")
	p:SetGroupName(groupName)
	table.insert(self.m_subGroups, p)
	return p
end
function gui.CollapsibleGroup:Collapse()
	if util.is_valid(self.m_titleBar) then
		self.m_titleBar:Collapse()
	end
end
function gui.CollapsibleGroup:Expand()
	if util.is_valid(self.m_titleBar) then
		self.m_titleBar:Expand()
	end
end
function gui.CollapsibleGroup:OnCollapse()
	if util.is_valid(self.m_contents) then
		self.m_contents:SetVisible(false)
	end
end
function gui.CollapsibleGroup:OnExpand()
	if util.is_valid(self.m_contents) then
		self.m_contents:SetVisible(true)
	end
end
function gui.CollapsibleGroup:Toggle()
	if util.is_valid(self.m_titleBar) then
		self.m_titleBar:Toggle()
	end
end
function gui.CollapsibleGroup:AddElement(el)
	if util.is_valid(self.m_contents) then
		el:SetParent(self.m_contents)
	end
end
function gui.CollapsibleGroup:GetContents()
	return self.m_contents
end
function gui.CollapsibleGroup:GetGroupName()
	return self.m_groupName or ""
end
function gui.CollapsibleGroup:SetGroupName(name)
	self.m_groupName = name
	if util.is_valid(self.m_titleBar) then
		self.m_titleBar:SetGroupName(name)
	end
end
gui.register("collapsible_group", gui.CollapsibleGroup)
