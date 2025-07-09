-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/pfm/pfm.lua")
include("/tests/base.lua")

tests.launch_pfm = function(fc)
	if tool.is_filmmaker_open() then
		tool.close_filmmaker()
	end
	local cb
	cb = pfm.add_event_listener("OnFilmmakerLaunched", function(pm)
		util.remove(cb)
		game.wait_for_frames(1, function()
			fc(tool.get_filmmaker())
		end, true)
	end)
	pfm.launch(nil)
end
