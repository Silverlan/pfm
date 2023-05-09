--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("../base_loading_screen.lua")

pfm.show_loading_screen = function(enabled, mapName)
	local loadText
	if mapName ~= nil then
		loadText = locale.get_text("pfm_loading_map", { mapName })
	end
	return pfm.show_base_loading_screen(enabled, "pragma filmmaker", "pfm/logo/pfm_logo", loadText)
end
