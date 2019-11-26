--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMProject",BaseEntityComponent)

function ents.PFMProject:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_offset = 0.0 -- Current playback offset in seconds
	self.m_timeFrame = udm.PFMTimeFrame()
end

function ents.PFMProject:OnRemove()
	self:Reset()
end

function ents.PFMProject:SetProjectData(project)
	self.m_project = project

	local timeFrame
	local session = project:GetSessions()[1] -- TODO: How to handle multiple sessions?
	if(session ~= nil) then
		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			local timeFrameClip = filmClip:GetTimeFrame()
			timeFrame = timeFrame and timeFrame:Max(timeFrameClip) or timeFrameClip
		end
	end
	self.m_timeFrame = timeFrame or udm.PFMTimeFrame()

	self.m_rootTrack = udm.PFMTrack()
	if(session ~= nil) then
		for _,filmClip in ipairs(session:GetClips():GetTable()) do
			self.m_rootTrack:GetFilmClipsAttr():PushBack(filmClip)
		end
	end
end

function ents.PFMProject:Start()
	self:Reset()

	local ent = ents.create("pfm_track")
	ent:GetComponent(ents.COMPONENT_PFM_TRACK):Setup(self.m_rootTrack)
	ent:Spawn()
	self.m_entRootTrack = ent
end

function ents.PFMProject:GetProject() return self.m_project end

function ents.PFMProject:SetOffset(offset)
	if(offset == self.m_offset) then return end
	-- pfm.log("Changing playback offset to " .. offset .. "...",pfm.LOG_CATEGORY_PFM_GAME)
	self.m_offset = offset
	if(util.is_valid(self.m_entRootTrack)) then
		local trackC = self.m_entRootTrack:GetComponent(ents.COMPONENT_PFM_TRACK)
		if(trackC ~= nil) then trackC:OnOffsetChanged(offset) end
	end
end

function ents.PFMProject:GetOffset()
	return self.m_offset
end

function ents.PFMProject:Reset()
	if(util.is_valid(self.m_entRootTrack)) then self.m_entRootTrack:Remove() end
end

function ents.PFMProject:GetTimeFrame() return self.m_timeFrame end
ents.COMPONENT_PFM_PROJECT = ents.register_component("pfm_project",ents.PFMProject)
