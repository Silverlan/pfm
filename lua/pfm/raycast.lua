-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
