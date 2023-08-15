--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:OnFilmClipAdded(el)
	if util.is_valid(self.m_timeline) == false then
		return
	end
	self:AddFilmClipElement(newEl)
end
function Element:SelectFilmClip(filmClip)
	local actorEditor = self:GetActorEditor()
	if util.is_valid(actorEditor) == false then
		return
	end
	actorEditor:Setup(filmClip)
end
function Element:ChangeFilmClipDuration(filmClip, dur)
	local timeFrame = filmClip:GetTimeFrame()
	pfm.undoredo.push(
		"pfm_set_film_clip_duration",
		pfm.create_command("set_film_clip_duration", filmClip, timeFrame:GetDuration(), dur)
	)()
end
function Element:ChangeFilmClipOffset(filmClip, offset)
	local el = self.m_filmStrip:FindFilmClipElement(filmClip)
	if util.is_valid(el) == false then
		return
	end
	filmClip:GetTimeFrame():SetOffset(offset)
	el:UpdateFilmClipData()
end
function Element:ChangeFilmClipName(filmClip, name)
	pfm.undoredo.push(
		"pfm_rename_film_clip",
		pfm.create_command("rename_film_clip", filmClip, filmClip:GetName(), name)
	)()
end
function Element:AddFilmClip()
	local session = self:GetSession()
	local trackFilm = (session ~= nil) and session:GetFilmTrack() or nil
	if trackFilm == nil then
		return
	end
	local lastFilmClip
	local sortedClips = trackFilm:GetSortedFilmClips()
	lastFilmClip = sortedClips[#sortedClips]
	self:InsertFilmClipAfter(lastFilmClip, name)
end
function Element:InsertFilmClipAfter(filmClip, name)
	name = name or "shot"
	local track = filmClip:GetParent()
	local newFc = track:InsertFilmClipAfter(filmClip)
	newFc:SetName(name)

	local channelTrackGroup = newFc:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")

	local elFc = self:AddFilmClipElement(newFc)
	self.m_timeline:GetTimeline():AddTimelineItem(elFc, newFc:GetTimeFrame())
end
function Element:InsertFilmClipBefore(filmClip, name)
	name = name or "shot"
	local track = filmClip:GetParent()
	local newFc = track:InsertFilmClipBefore(filmClip)
	newFc:SetName(name)

	local channelTrackGroup = newFc:AddTrackGroup()
	channelTrackGroup:SetName("channelTrackGroup")

	local animSetEditorChannelsTrack = channelTrackGroup:AddTrack()
	animSetEditorChannelsTrack:SetName("animSetEditorChannels")

	local elFc = self:AddFilmClipElement(newFc)
	self.m_timeline:GetTimeline():AddTimelineItem(elFc, newFc:GetTimeFrame())
end
function Element:MoveFilmClipToLeft(filmClip)
	local track = filmClip:GetParent()
	track:MoveFilmClipToLeft(filmClip)
end
function Element:MoveFilmClipToRight(filmClip)
	local track = filmClip:GetParent()
	track:MoveFilmClipToRight(filmClip)
end
function Element:RemoveFilmClip(filmClip)
	local el = self.m_filmStrip:FindFilmClipElement(filmClip)
	if util.is_valid(el) == false then
		return
	end
	local track = filmClip:GetParent()
	track:RemoveFilmClip(filmClip)
	-- TODO: This probably requires some cleanup
	el:Remove()
	track:UpdateFilmClipTimeFrames()

	self:UpdateTrackCallbacks()
end
function Element:UpdateTrackCallbacks()
	if self.m_tracks == nil then
		return
	end
	local newTracks = {}
	if util.is_valid(self.m_filmStrip) then
		for _, elFilmClip in ipairs(self.m_filmStrip:GetFilmClips()) do
			if elFilmClip:IsValid() then
				local filmClip = elFilmClip:GetFilmClip()
				newTracks[filmClip:GetParent()] = true
			end
		end
	end

	local rem = {}
	for track, trackData in pairs(self.m_tracks) do
		if newTracks[track] ~= true then
			util.remove(trackData.callbacks)
			self.m_tracks[track] = nil
		end
	end
	for _, track in ipairs(rem) do
		self.m_tracks[track] = nil
	end
end
function Element:AddTrackCallbacks(track)
	self.m_tracks = self.m_tracks or {}
	if self.m_tracks[track] ~= nil then
		return
	end
	local cb = track:AddChangeListener("OnFilmClipTimeFramesUpdated", function(c)
		if self:IsValid() == false or self.m_filmStrip:IsValid() == false then
			return
		end
		for _, elFilmClip in ipairs(self.m_filmStrip:GetFilmClips()) do
			if elFilmClip:IsValid() then
				elFilmClip:UpdateFilmClipData()
			end
		end
	end)
	self.m_tracks[track] = {
		callbacks = { cb },
	}
end
function Element:AddFilmClipElement(filmClip)
	local pFilmClip = self.m_timeline:AddFilmClip(self.m_filmStrip, filmClip, function(elFilmClip)
		local filmClipData = elFilmClip:GetFilmClipData()
		if util.is_valid(self:GetActorEditor()) then
			self:SelectFilmClip(filmClipData)
		end
	end)
	local listeners = {}
	pFilmClip:AddCallback("OnRemove", function()
		util.remove(listeners)
	end)
	table.insert(
		listeners,
		filmClip:AddChangeListener("name", function(c)
			if self:IsValid() == false or self.m_filmStrip:IsValid() == false then
				return
			end
			local el = self.m_filmStrip:FindFilmClipElement(filmClip)
			if util.is_valid(el) == false then
				return
			end
			el:UpdateFilmClipData()
		end)
	)
	self:AddTrackCallbacks(filmClip:GetParent())
	pFilmClip:AddCallback("OnMouseEvent", function(pFilmClip, button, state, mods)
		if button == input.MOUSE_BUTTON_RIGHT and state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())
			pContext:AddItem(locale.get_text("pfm_change_duration"), function()
				local p = pfm.open_single_value_edit_window(locale.get_text("duration"), function(ok, val)
					if self:IsValid() == false then
						return
					end
					if ok then
						local dur = tonumber(val)
						if dur ~= nil then
							self:ChangeFilmClipDuration(filmClip, math.max(dur, 0.1))
						end
					end
				end, tostring(filmClip:GetTimeFrame():GetDuration()))
			end)
			pContext:AddItem(locale.get_text("pfm_change_offset"), function()
				local p = pfm.open_single_value_edit_window(locale.get_text("offset"), function(ok, val)
					if self:IsValid() == false then
						return
					end
					if ok then
						local offset = tonumber(val)
						if offset ~= nil then
							self:ChangeFilmClipOffset(filmClip, offset)
						end
					end
				end, tostring(filmClip:GetTimeFrame():GetOffset()))
			end)
			pContext:AddItem(locale.get_text("pfm_change_name"), function()
				local p = pfm.open_single_value_edit_window(locale.get_text("name"), function(ok, val)
					if self:IsValid() == false then
						return
					end
					if ok then
						self:ChangeFilmClipName(filmClip, val)
					end
				end, tostring(filmClip:GetName()))
			end)
			pContext:AddItem(locale.get_text("pfm_add_clip_after"), function()
				local p = pfm.open_single_value_edit_window(locale.get_text("name"), function(ok, val)
					if self:IsValid() == false then
						return
					end
					if ok then
						self:InsertFilmClipAfter(filmClip, val)
					end
				end, tostring(filmClip:GetName()))
			end)
			pContext:AddItem(locale.get_text("pfm_add_clip_before"), function()
				local p = pfm.open_single_value_edit_window(locale.get_text("name"), function(ok, val)
					if self:IsValid() == false then
						return
					end
					if ok then
						self:InsertFilmClipBefore(filmClip, val)
					end
				end, tostring(filmClip:GetName()))
			end)
			pContext:AddItem(locale.get_text("pfm_move_clip_to_left"), function()
				self:MoveFilmClipToLeft(filmClip)
			end)
			pContext:AddItem(locale.get_text("pfm_move_clip_to_right"), function()
				self:MoveFilmClipToRight(filmClip)
			end)
			pContext:AddItem(locale.get_text("remove"), function()
				self:RemoveFilmClip(filmClip)
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
		return util.EVENT_REPLY_UNHANDLED
	end)
	return pFilmClip
end
