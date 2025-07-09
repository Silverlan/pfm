-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

function pfm.udm.TrackGroup:FindTrack(name)
	for _, track in ipairs(self:GetTracks()) do
		if track:GetName() == name then
			return track
		end
	end
end
