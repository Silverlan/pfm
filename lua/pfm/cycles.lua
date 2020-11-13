--[[
    Copyright (C) 2020  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local loaded
function pfm.load_cycles()
	if(loaded ~= nil) then return loaded end

	pfm.log("Loading cycles module...",pfm.LOG_CATEGORY_PFM_RENDER)

	local r = engine.load_library("cycles/pr_cycles")
	if(r ~= true) then
		loaded = false
		pfm.log("Unable to load cycles module: " .. r,pfm.LOG_CATEGORY_PFM_RENDER,pfm.LOG_SEVERITY_ERROR)
		return
	end

	loaded = true
	pfm.log("Loading cycles shaders...",pfm.LOG_CATEGORY_PFM_RENDER)
	include("/cycles/shaders/")
end


