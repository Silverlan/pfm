--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = ents.PFMProject
function Component.precache_session_assets(session)
	debug.start_profiling_task("pfm_precache_session_assets")
	pfm.log("Precaching session assets...", pfm.LOG_CATEGORY_PFM)
	local track = session:GetFilmTrack()
	if track ~= nil then
		for _, filmClip in ipairs(track:GetFilmClips()) do
			pfm.log("Precaching assets for film clip '" .. tostring(filmClip) .. "'...", pfm.LOG_CATEGORY_PFM)
			local actors = filmClip:GetActorList()
			for _, actor in ipairs(actors) do
				local component = actor:FindComponent("model")
				if component ~= nil then
					local mdlName =
						asset.normalize_asset_name(component:GetMemberValue("model") or "", asset.TYPE_MODEL)
					if #mdlName > 0 then
						pfm.log(
							"Precaching model '" .. mdlName .. "' for actor '" .. tostring(actor) .. "'...",
							pfm.LOG_CATEGORY_PFM
						)
						if game.precache_model(mdlName) == false then
							pfm.log(
								"Unable to precache model '" .. mdlName .. "'!",
								pfm.LOG_CATEGORY_PFM,
								pfm.LOG_SEVERITY_WARNING
							)
						end
					end
				end
			end
		end
	end
	debug.stop_profiling_task()
end
function Component.wait_for_session_assets(session)
	debug.start_profiling_task("pfm_wait_for_session_assets")
	pfm.log("Waiting for session assets...", pfm.LOG_CATEGORY_PFM)
	local track = session:GetFilmTrack()
	if track ~= nil then
		for _, filmClip in ipairs(track:GetFilmClips()) do
			local actors = filmClip:GetActorList()
			for _, actor in ipairs(actors) do
				local component = actor:FindComponent("model")
				if component ~= nil then
					local mdlName =
						asset.normalize_asset_name(component:GetMemberValue("model") or "", asset.TYPE_MODEL)
					if #mdlName > 0 then
						asset.wait_until_loaded(mdlName, asset.TYPE_MODEL)
					end
				end
			end
		end
	end
	debug.stop_profiling_task()
end
function Component:PrecacheSessionAssets(session)
	session = session or self:GetSession()
	if session == nil then
		return
	end
	Component.precache_session_assets(session)
end
function Component:WaitForSessionAssets(session)
	session = session or self:GetSession()
	if session == nil then
		return
	end
	Component.wait_for_session_assets(session)
end
