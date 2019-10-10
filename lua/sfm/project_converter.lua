--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/sfm.lua")
include("/pfm/pfm.lua")

pfm.register_log_category("sfm_converter")

util.register_class("sfm.ProjectConverter")
sfm.ProjectConverter.convert_project = function(projectFilePath)
	local sfmScene = sfm.import_scene(projectFilePath)
	if(sfmScene == nil) then return false end
	local converter = sfm.ProjectConverter(sfmScene)
	local pfmScene = converter:GetConvertedScene()

	-- Collect and print debug information
	local numTracks = 0
	local numFilmClips = 0
	local numAudioClips = 0
	local numAnimationSets = 0
	for name,node in pairs(pfmScene:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_TRACK) then
			numTracks = numTracks +1
			for name,child in pairs(node:GetChildren()) do
				if(child:GetType() == udm.ELEMENT_TYPE_FILM_CLIP) then
					numFilmClips = numFilmClips +1
					for name,child in pairs(child:GetChildren()) do
						if(child:GetType() == udm.ELEMENT_TYPE_ANIMATION_SET) then
							numAnimationSets = numAnimationSets +1
						end
					end
				elseif(child:GetType() == udm.ELEMENT_TYPE_AUDIO_CLIP) then
					numAudioClips = numAudioClips +1
				end
			end
		end
	end
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("PFM project information:",pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of tracks: " .. numTracks,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of film clips: " .. numFilmClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of audio clips: " .. numAudioClips,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("Number of animation sets: " .. numAnimationSets,pfm.LOG_CATEGORY_PFM_CONVERTER)
	pfm.log("---------------------------------------",pfm.LOG_CATEGORY_PFM_CONVERTER)
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
	for _,clip in ipairs(sfmSession:GetClips()) do
		self:ConvertClip(clip)
	end
end
function sfm.ProjectConverter:ConvertFilmClip(filmClip,pfmTrack)
	local pfmClip = pfmTrack:AddFilmClip(filmClip:GetName())
	filmClip:ToPFMFilmClip(pfmClip)
	return pfmClip
end
function sfm.ProjectConverter:ConvertTrack(track)
	local pfmTrack = self.m_pfmScene:AddTrack(track:GetName())
	pfmTrack:SetMuted(track:IsMuted())
	pfmTrack:SetVolume(track:GetVolume())
	--[[for _,soundClip in ipairs(track:GetSoundClips()) do
		print("Adding clip " .. soundClip:GetName() .. " to track " .. track:GetName())
		local audioClip = track:AddAudioClip(soundClip:GetName())
		soundClip:ToPFMAudioClip(audioClip)
	end]]
	for _,filmClip in ipairs(track:GetFilmClips()) do
		self:ConvertFilmClip(filmClip,pfmTrack)
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
