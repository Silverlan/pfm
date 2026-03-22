-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("timeline_editor_base.lua")

local TimelineEditorClip = util.register_class("gui.pfm.TimelineEditorClip", gui.pfm.TimelineEditorBase)

function TimelineEditorClip:OnInitialize()
	gui.pfm.TimelineEditorBase.OnInitialize(self)

	self.m_trackGroups = {}
	self:SetSize(256, 64)
	self.m_contentsScroll = gui.create("WIScrollContainer", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents = gui.create("vbox", self.m_contentsScroll, 0, 0, self:GetWidth(), self:GetHeight())
	self.m_contents:SetAutoFillContentsToWidth(true)
end
function TimelineEditorClip:OnSizeChanged(w, h)
	if util.is_valid(self.m_contents) then
		self.m_contents:ApplyWidth(w)
	end
	for _, trackGroup in ipairs(self.m_trackGroups) do
		if trackGroup:IsValid() then
			trackGroup:ApplyWidth(w)
		end
	end
end
function TimelineEditorClip:AddTrackGroup(groupName)
	if util.is_valid(self) == false then
		return
	end
	local p = gui.create("collapsible_group", self.m_contents)
	p:SetWidth(self:GetWidth())
	p:SetGroupName(groupName)
	table.insert(self.m_trackGroups, p)
	return p
end
gui.register("pfm_timeline_editor_clip", TimelineEditorClip)
