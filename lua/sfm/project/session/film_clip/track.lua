--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

sfm.register_element_type("Track")
sfm.link_dmx_type("DmeTrack",sfm.Track)

include("track")
include("scene")

sfm.BaseElement.RegisterAttribute(sfm.Track,"mute",false,{
	getterName = "IsMuted"
})
sfm.BaseElement.RegisterAttribute(sfm.Track,"volume",1.0)

function sfm.Track:Initialize()
	self.m_channelClips = {}
	self.m_soundClips = {}
	self.m_filmClips = {}
end

function sfm.Track:Load(el)
	sfm.BaseElement.Load(self,el)
	
	for _,attrClip in ipairs(el:GetAttrV("children") or {}) do
		local elClip = attrClip:GetValue()
		local type = elClip:GetType()
		if(type == "DmeSoundClip") then
			table.insert(self.m_soundClips,self:LoadArrayValue(attrClip,sfm.SoundClip))
		elseif(type == "DmeChannelsClip") then
			table.insert(self.m_channelClips,self:LoadArrayValue(attrClip,sfm.ChannelClip))
		elseif(type == "DmeFilmClip") then
			table.insert(self.m_filmClips,self:LoadArrayValue(attrClip,sfm.FilmClip))
		else
			pfm.log("Unsupported track child type '" .. type .. "' for track '" .. self:GetName() .. "'! Child will be ignored!",pfm.LOG_CATEGORY_SFM,pfm.LOG_SEVERITY_WARNING)
		end
	end
end

function sfm.Track:GetChannelClips() return self.m_channelClips end
function sfm.Track:GetSoundClips() return self.m_soundClips end
function sfm.Track:GetFilmClips() return self.m_filmClips end
