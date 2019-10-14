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
	pfm.log("Number of audio clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of animation sets: " .. numAnimationSets,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
end

local function log_pfm_project_debug_info(project)
	local numTracks = 0
	local numFilmClips = 0
	local numAudioClips = 0
	local numActors = 0
	for name,node in pairs(project:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_TRACK) then
			numTracks = numTracks +1
			for _,clip in ipairs(node:GetFilmClips():GetValue()) do
				numFilmClips = numFilmClips +1
				numActors = numActors +#clip:GetActors():GetValue()
			end
			numAudioClips = numAudioClips +#node:GetAudioClips():GetValue()
		end
	end
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("PFM project information:",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of tracks: " .. numTracks,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of film clips: " .. numFilmClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of audio clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of actors: " .. numActors,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
end

util.register_class("sfm.ProjectConverter")
sfm.ProjectConverter.convert_project = function(projectFilePath)
	local sfmScene = sfm.import_scene(projectFilePath)
	if(sfmScene == nil) then return false end
	log_sfm_project_debug_info(sfmScene)

	local converter = sfm.ProjectConverter(sfmScene)
	local pfmScene = converter:GetConvertedScene()
	log_pfm_project_debug_info(pfmScene)
	return pfmScene
end
function sfm.ProjectConverter:__init(sfmScene)
	self.m_sfmScene = sfmScene -- Input project
	self.m_pfmScene = pfm.create_scene() -- Output project

	for _,session in ipairs(sfmScene:GetSessions()) do
		self:ConvertSession(session)
	end
end
function sfm.ProjectConverter:GetConvertedScene() return self.m_pfmScene end
function sfm.ProjectConverter:ConvertSession(sfmSession)
	for _,clip in ipairs(sfmSession:GetClipBin()) do
		self:ConvertClip(clip)
	end
	for _,clip in ipairs(sfmSession:GetMiscBin()) do
		self:ConvertClip(clip)
	end
end
function sfm.ProjectConverter:ConvertFilmClip(filmClip,pfmTrack)
	local pfmClip = pfmTrack:AddFilmClip(filmClip:GetName())
	filmClip:ToPFMFilmClip(pfmClip)
	return pfmClip
end
function sfm.ProjectConverter:ConvertSoundClip(soundClip,pfmTrack)
	local pfmClip = pfmTrack:AddAudioClip(soundClip:GetName())
	soundClip:ToPFMAudioClip(pfmClip)
	return pfmClip
end
function sfm.ProjectConverter:ConvertTrack(track)
	local pfmTrack = self.m_pfmScene:AddTrack(track:GetName())
	pfmTrack:SetMuted(track:IsMuted())
	pfmTrack:SetVolume(track:GetVolume())
	for _,filmClip in ipairs(track:GetFilmClips()) do
		self:ConvertFilmClip(filmClip,pfmTrack)
	end
	for _,soundClip in ipairs(track:GetSoundClips()) do
		self:ConvertSoundClip(soundClip,pfmTrack)
	end
end
function sfm.ProjectConverter:ConvertClip(clip)
	for _,trackGroup in ipairs(clip:GetTrackGroups()) do
		for _,track in ipairs(trackGroup:GetTracks()) do
			self:ConvertTrack(track)
		end
	end

	local subClipTrackGroup = clip:GetSubClipTrackGroup()
	if(subClipTrackGroup == nil) then return end
	for _,track in ipairs(subClipTrackGroup:GetTracks()) do
		self:ConvertTrack(track)
	end
end
