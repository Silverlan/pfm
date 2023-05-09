--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}

local transformFilter = function(ent)
	return ent:HasComponent(ents.COMPONENT_UTIL_TRANSFORM_ARROW) == false
end
pfm.raycast = function(pos, dir, maxDist, filter)
	if filter ~= nil then
		local origFilter = filter
		filter = function(...)
			return transformFilter(...) and origFilter(...)
		end
	else
		filter = transformFilter
	end
	return ents.ClickComponent.raycast(pos, dir, filter, maxDist)
end
