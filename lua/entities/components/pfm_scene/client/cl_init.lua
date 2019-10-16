--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMScene",BaseEntityComponent)

function ents.PFMScene:Initialize()
	BaseEntityComponent.Initialize(self)
	
	self.m_activeTracks = {}
end

function ents.PFMScene:OnRemove()
	self:StopPlayback()
end

function ents.PFMScene:SetScene(scene) self.m_scene = scene end

function ents.PFMScene:SetOffset(offset)
	for _,track in ipairs(self.m_activeTracks) do
		if(track:IsValid()) then
			local trackC = track:GetComponent(ents.COMPONENT_PFM_TRACK)
			if(trackC ~= nil) then trackC:SetOffset(offset) end
		end
	end
end

function ents.PFMScene:GetOffset()
	local track = self.m_activeTracks[1]
	if(util.is_valid(track) == false) then return 0.0 end
	local trackC = track:GetComponent(ents.COMPONENT_PFM_TRACK)
	return (trackC ~= nil) and trackC:GetOffset() or 0.0
end

function ents.PFMScene:GetTrackTimeFrame()
	local timeFrame
	for _,track in ipairs(self.m_activeTracks) do
		local trackC = track:IsValid() and track:GetComponent(ents.COMPONENT_PFM_TRACK) or nil
		if(trackC ~= nil) then
			if(timeFrame == nil) then timeFrame = trackC:GetTimeFrame()
			else timeFrame = timeFrame:Max(trackC:GetTimeFrame()) end
		end
	end
	return timeFrame or udm.TimeFrame()
end

function ents.PFMScene:PlayAudio()
	for _,track in ipairs(self.m_activeTracks) do
		if(track:IsValid()) then
			local trackC = track:GetComponent(ents.COMPONENT_PFM_TRACK)
			if(trackC ~= nil) then trackC:PlayAudio() end
		end
	end
end

function ents.PFMScene:PauseAudio()
	for _,track in ipairs(self.m_activeTracks) do
		if(track:IsValid()) then
			local trackC = track:GetComponent(ents.COMPONENT_PFM_TRACK)
			if(trackC ~= nil) then trackC:PauseAudio() end
		end
	end
end

function ents.PFMScene:StartPlayback(track)
	local entTrack = ents.create("pfm_track")
	table.insert(self.m_activeTracks,entTrack)
	entTrack:Spawn()
	entTrack:GetComponent(ents.COMPONENT_PFM_TRACK):SetTrack(track)
end

function ents.PFMScene:Start()
	self:StopPlayback()
	pfm.log("Starting PFM scene...",pfm.LOG_CATEGORY_PFM)
	local scene = self.m_scene
	if(scene == nil) then
		pfm.log("Unable to start PFM scene: Scene object is invalid!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_ERROR)
		return
	end
	for name,node in pairs(scene:GetUDMRootNode():GetChildren()) do
		if(node:GetType() == udm.ELEMENT_TYPE_PFM_TRACK) then
			if(node:GetMuted() == false) then
				pfm.log("Found unmuted film track '" .. name .. "'! Starting playback...",pfm.LOG_CATEGORY_PFM)
				self:StartPlayback(node)
			end
		end
	end
	pfm.log("Unable to start PFM scene: No unmuted film track has been found!",pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
end

function ents.PFMScene:StopPlayback()
	for _,ent in ipairs(self.m_activeTracks) do
		if(ent:IsValid()) then ent:Remove() end
	end
	self.m_activeTracks = {}
end
ents.COMPONENT_PFM_SCENE = ents.register_component("pfm_scene",ents.PFMScene)
