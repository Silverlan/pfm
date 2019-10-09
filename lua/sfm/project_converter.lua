--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/sfm.lua")
include("/pfm/pfm.lua")

util.register_class("sfm.ProjectConverter")
sfm.ProjectConverter.convert_project = function(projectFilePath)
	local sfmScene = sfm.import_scene(projectFilePath)
	if(sfmScene == nil) then return false end
	local converter = sfm.ProjectConverter(sfmScene)
	return converter:GetConvertedScene()
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
