--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/sfm.lua")
include("/pfm/pfm.lua")

pfm.register_log_category("sfm_converter")

local function log_sfm_project_debug_info(project)
	local numSessions = 0
	local numClips = 0
	local numTracks = 0
	local numFilmClips = 0
	local numAudioClips = 0
	local numAnimationSets = 0
	for _,session in ipairs(project:GetSessions()) do
		numSessions = numSessions +1
		for _,clipSet in ipairs({session:GetClipBin(),session:GetMiscBin()}) do
			for _,clip in ipairs(clipSet) do
				numClips = numClips +1
				local subClipTrackGroup = clip:GetSubClipTrackGroup()
				for _,track in ipairs(subClipTrackGroup:GetTracks()) do
					numTracks = numTracks +1
					for _,filmClip in ipairs(track:GetFilmClips()) do
						numFilmClips = numFilmClips +1
						numAnimationSets = numAnimationSets +#filmClip:GetAnimationSets()
					end
					numAudioClips = numAudioClips +#track:GetSoundClips()
				end
			end
		end
	end
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("SFM project information:",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of sessions: " .. numSessions,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of clips: " .. numClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of tracks: " .. numTracks,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of film clips: " .. numFilmClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of sound clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of animation sets: " .. numAnimationSets,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
end

local function log_pfm_project_debug_info(project)
	local numTracks = 0
	local numFilmClips = 0
	local numAudioClips = 0
	local numChannelClips = 0
	local numActors = 0
	local function iterate_film_clip(filmClip)
		numFilmClips = numFilmClips +1
		numActors = numActors +#filmClip:GetActors()
		for _,trackGroup in ipairs(filmClip:GetTrackGroups()) do
			for _,track in ipairs(trackGroup:GetTracks()) do
				for _,filmClipOther in ipairs(track:GetFilmClips()) do
					iterate_film_clip(filmClipOther)
				end
				numAudioClips = numAudioClips +#track:GetAudioClips()
				numChannelClips = numChannelClips +#track:GetChannelClips()
			end
		end
	end
	for name,node in pairs(project:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_FILM_CLIP) then
			iterate_film_clip(node)
		end
	end
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("PFM project information:",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of film clips: " .. numFilmClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of audio clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of channel clips: " .. numChannelClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of actors: " .. numActors,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
end

util.register_class("sfm.ProjectConverter")
sfm.ProjectConverter.convert_project = function(projectFilePath)
	local sfmProject = sfm.import_scene(projectFilePath)
	if(sfmProject == nil) then return false end
	log_sfm_project_debug_info(sfmProject)

	local converter = sfm.ProjectConverter(sfmProject)
	local pfmScene = converter:GetConvertedScene()
	log_pfm_project_debug_info(pfmScene)
	return pfmScene
end
function sfm.ProjectConverter:__init(sfmProject)
	self.m_sfmProject = sfmProject -- Input project
	self.m_pfmProject = pfm.create_project() -- Output project

	for _,session in ipairs(sfmProject:GetSessions()) do
		self:ConvertSession(session)
	end
end
function sfm.ProjectConverter:GetConvertedScene() return self.m_pfmProject end
function sfm.ProjectConverter:ConvertSession(sfmSession)
	for _,clipSet in ipairs({sfmSession:GetClipBin(),sfmSession:GetMiscBin()}) do
		for _,clip in ipairs(clipSet) do
			if(clip:GetType() == "DmeFilmClip") then
				local pfmFilmClip = self.m_pfmProject:AddFilmClip(clip:GetName())
				clip:ToPFMFilmClip(pfmFilmClip)
			else
				pfm.log("Unsupported clip type '" .. clip:GetType() .. "'! Skipping...",pfm.LOG_CATEGORY_PFM_CONVERTER,pfm.LOG_SEVERITY_WARNING)
			end
		end
	end
end
