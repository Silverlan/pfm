--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm.optimize = function(project)
	pfm.log("Optimizing PFM project...", pfm.LOG_CATEGORY_PFM)
	local session = project:GetSession()

	local actors = {}
	local constrainedProperties = {}
	local function cleanup_film_clip(filmClip)
		for actor, data in pairs(pfm.udm.Actor.get_constrained_properties(filmClip)) do
			constrainedProperties[actor] = constrainedProperties[actor] or {}
			for targetPath, data in pairs(data) do
				constrainedProperties[actor][targetPath] = data
			end
		end

		local scene = filmClip:GetScene()
		-- These may still exist from an older version but are no longer needed
		pfm.log("Removing remnant film clip data...", pfm.LOG_CATEGORY_PFM)
		scene:GetUdmData():RemoveValue("animationClips")
		scene:GetUdmData():RemoveValue("audioClips")
		scene:GetUdmData():RemoveValue("overlayClips")
		scene:GetUdmData():RemoveValue("filmClips")

		for _, actor in ipairs(filmClip:GetActorList()) do
			actors[actor] = true
		end
	end

	for _, filmClip in ipairs(session:GetClips()) do
		cleanup_film_clip(filmClip)

		local trackGroup = filmClip:FindTrackGroup("subClipTrackGroup")
		local track = (trackGroup ~= nil) and trackGroup:FindTrack("Film") or nil
		if track ~= nil then
			for _, subFilmClip in ipairs(track:GetFilmClips()) do
				cleanup_film_clip(subFilmClip)
			end
		end
	end

	for actor, _ in pairs(actors) do
		local n = actor:DissolveSingleValueAnimationChannels(nil, constrainedProperties)
		if n > 0 then
			pfm.log(
				"Collapsed " .. n .. " single-value animation channels for actor '" .. tostring(actor) .. "'...",
				pfm.LOG_CATEGORY_PFM
			)
		end
	end

	pfm.undoredo.clear()
	pfm.log("Optimization complete!", pfm.LOG_CATEGORY_PFM)

	time.create_simple_timer(0.0, function()
		local pm = tool.get_filmmaker()
		if util.is_valid(pm) then
			pm:ReloadGameView()
		end
	end)
end
