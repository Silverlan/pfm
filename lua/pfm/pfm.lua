--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.impl = pfm.impl or {}

pfm.impl.projects = pfm.impl.projects or {}

include("log.lua")
include("/udm/udm.lua")
include("udm")
include("math.lua")
include("tree/pfm_tree.lua")

util.register_class("pfm.Project")
function pfm.Project:__init()
	self.m_udmRoot = udm.create_element(udm.ELEMENT_TYPE_ROOT,"root")
	self.m_sessions = {}
end

function pfm.Project:GetSessions() return self.m_sessions end

function pfm.Project:AddSession(session)
	if(type(session) == "string") then
		local name = session
		session = udm.create_element(udm.ELEMENT_TYPE_PFM_SESSION)
		session:ChangeName(name)
	end
	self:GetUDMRootNode():AddChild(session)
	table.insert(self.m_sessions,session)
	return session
end

function pfm.Project:GetUDMRootNode() return self.m_udmRoot end

function pfm.Project:DebugPrint(node,t,name)
	if(node == nil) then
		self:DebugPrint(self:GetUDMRootNode(),t,name)
		return
	end
	node:DebugPrint(t,name)
end

function pfm.Project:DebugDump(f,node,t,name)
	if(node == nil) then
		self:DebugDump(f,self:GetUDMRootNode(),t,name)
		return
	end
	node:DebugDump(f,t,name)
end

pfm.create_project = function()
	local project = pfm.Project()
	table.insert(pfm.impl.projects,project)
	return project
end

pfm.create_empty_project = function()
	local project = pfm.create_project()

	local session = project:AddSession("session")
	local filmClip = session:GetActiveClip()
	filmClip:ChangeName("new_project")
	session:GetClips():PushBack(filmClip)

	local subClipTrackGroup = udm.create_element(udm.ELEMENT_TYPE_PFM_TRACK_GROUP)
	subClipTrackGroup:ChangeName("subClipTrackGroup")
	filmClip:GetTrackGroupsAttr():PushBack(subClipTrackGroup)

	local filmTrack = udm.create_element(udm.ELEMENT_TYPE_PFM_TRACK)
	filmTrack:ChangeName("Film")
	subClipTrackGroup:GetTracksAttr():PushBack(filmTrack)

	local shot1 = session:AddFilmClip()
	shot1:GetTimeFrame():SetDuration(60.0)

	return project
end

pfm.get_projects = function() return pfm.impl.projects end

pfm.get_key_binding = function(identifier)
	return "TODO"
end
