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
end

function pfm.Project:SetPlaybackOffset(offset)
	for name,child in pairs(self:GetUDMRootNode():GetChildren()) do
		if(child:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP) then
			child:SetPlaybackOffset(offset)
		end
	end
end

function pfm.Project:AddFilmClip(filmClip)
	if(type(filmClip) == "string") then filmClip = udm.create_element(udm.ELEMENT_TYPE_PFM_FILM_CLIP,filmClip) end
	return self:GetUDMRootNode():AddChild(filmClip)
end

function pfm.Project:GetUDMRootNode() return self.m_udmRoot end

local function iterate_film_clips(filmClip,callback,cache)
	cache = cache or {}
	if(cache[filmClip] ~= nil) then return end
	cache[filmClip] = true

	callback(filmClip)
	for _,trackGroup in ipairs(filmClip:GetTrackGroups()) do
		for _,track in ipairs(trackGroup:GetTracks()) do
			for _,childFilmClip in ipairs(track:GetFilmClips()) do
				iterate_film_clips(childFilmClip,callback)
			end
		end
	end
end

function sfm.Project:IterateFilmClips(callback)
	local project = self:GetPFMProject()
	for name,child in pairs(project:GetUDMRootNode():GetChildren()) do
		if(child:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP) then
			iterate_film_clips(child,callback)
		end
	end
end

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
