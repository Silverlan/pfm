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
include("tree/pfm_tree.lua")

util.register_class("pfm.Project")
function pfm.Project:__init()
	self.m_udmRoot = udm.create_element(udm.ELEMENT_TYPE_ROOT,"root")
	self.m_sessions = {}
end

function pfm.Project:GetSessions() return self.m_sessions end

function pfm.Project:AddSession(session)
	self:GetUDMRootNode():AddChild(session)
	table.insert(self.m_sessions,session)
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

pfm.get_projects = function() return pfm.impl.projects end
