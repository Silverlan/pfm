--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

function pfm.udm.TrackGroup:FindTrack(name)
	for _, track in ipairs(self:GetTracks()) do
		if track:GetName() == name then
			return track
		end
	end
end
