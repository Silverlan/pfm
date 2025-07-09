-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.PFMTimelineClip", gui.Base)

function gui.PFMTimelineClip:__init()
	gui.Base.__init(self)
end
function gui.PFMTimelineClip:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_trackGroups = {}
	self:SetSize(256, 64)
	self.m_contentsScroll = gui.create("WIScrollContainer", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_contents = gui.create("WIVBox", self.m_contentsScroll, 0, 0, self:GetWidth(), self:GetHeight())
	self.m_contents:SetAutoFillContentsToWidth(true)
end
function gui.PFMTimelineClip:OnSizeChanged(w, h)
	if util.is_valid(self.m_contents) then
		self.m_contents:SetWidth(w)
	end
	for _, trackGroup in ipairs(self.m_trackGroups) do
		if trackGroup:IsValid() then
			trackGroup:SetWidth(w)
		end
	end
end
function gui.PFMTimelineClip:AddTrackGroup(groupName)
	if util.is_valid(self) == false then
		return
	end
	local p = gui.create("WICollapsibleGroup", self.m_contents)
	p:SetWidth(self:GetWidth())
	p:SetGroupName(groupName)
	table.insert(self.m_trackGroups, p)
	return p
end
gui.register("WIPFMTimelineClip", gui.PFMTimelineClip)
