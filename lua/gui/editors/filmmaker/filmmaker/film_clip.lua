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
	local timeFrame = filmClip:GetTimeFrame()
	pfm.undoredo.push(
		"pfm_set_film_clip_offset",
		pfm.create_command("set_film_clip_offset", filmClip, timeFrame:GetOffset(), offset)
	)()
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
	self:InsertFilmClipAfter(lastFilmClip)
end
function Element:InsertFilmClipAfter(filmClip, name)
	pfm.undoredo.push("pfm_add_film_clip", pfm.create_command("add_film_clip", name or "shot", filmClip, false))()
end
function Element:InsertFilmClipBefore(filmClip, name)
	pfm.undoredo.push("pfm_add_film_clip", pfm.create_command("add_film_clip", name or "shot", filmClip, true))()
end
function Element:MoveFilmClipToLeft(filmClip)
	pfm.undoredo.push("pfm_move_film_clip", pfm.create_command("move_film_clip", filmClip, true))()
end
function Element:MoveFilmClipToRight(filmClip)
	pfm.undoredo.push("pfm_move_film_clip", pfm.create_command("move_film_clip", filmClip, false))()
end
function Element:RemoveFilmClip(filmClip)
	pfm.undoredo.push("pfm_delete_film_clip", pfm.create_command("delete_film_clip", filmClip))()
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
	local function update_film_clip_data()
		if self:IsValid() == false or self.m_filmStrip:IsValid() == false then
			return
		end
		local el = self.m_filmStrip:FindFilmClipElement(filmClip)
		if util.is_valid(el) == false then
			return
		end
		el:UpdateFilmClipData()
	end
	table.insert(listeners, filmClip:AddChangeListener("name", update_film_clip_data))
	table.insert(listeners, filmClip:AddChangeListener("duration", update_film_clip_data))
	table.insert(listeners, filmClip:AddChangeListener("offset", update_film_clip_data))
	table.insert(
		listeners,
		filmClip:AddChangeListener("OnActorPoseChanged", function(filmClip, actor, oldPose, newPose, changeFlags)
			local vp = self:GetViewport()
			local ent = actor:FindEntity()
			if util.is_valid(vp) and util.is_valid(ent) then
				local rt = util.is_valid(vp) and vp:GetRealtimeRaytracedViewport() or nil
				if util.is_valid(rt) then
					rt:MarkActorAsDirty(ent)
				end
				self:TagRenderSceneAsDirty()

				self:GetAnimationManager():SetAnimationDirty(actor)
				local prefixPath = "ec/pfm_actor/"
				if bit.band(changeFlags, pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_POSITION) ~= 0 then
					ent:SetMemberValue(prefixPath .. "position", newPose:GetOrigin())
					self:GetActorEditor():UpdateActorProperty(actor, prefixPath .. "position")
				end
				if bit.band(changeFlags, pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_ROTATION) ~= 0 then
					ent:SetMemberValue(prefixPath .. "rotation", newPose:GetRotation())
					self:GetActorEditor():UpdateActorProperty(actor, prefixPath .. "rotation")
				end
				if bit.band(changeFlags, pfm.udm.Actor.POSE_CHANGE_FLAG_BIT_SCALE) ~= 0 then
					ent:SetMemberValue(prefixPath .. "scale", newPose:GetScale())
					self:GetActorEditor():UpdateActorProperty(actor, prefixPath .. "scale")
				end

				vp:OnActorTransformChanged(ent)
			end
		end)
	)
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
