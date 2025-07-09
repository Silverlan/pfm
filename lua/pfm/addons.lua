-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}
pfm.util = pfm.util or {}
if pfm.util.subAddonsLoaded == nil then
	pfm.util.subAddonsLoaded = false
end

pfm.util.mount_sub_addon = function(addonName)
	local res = engine.mount_sub_addon(addonName)
	if res == false then
		pfm.log("Failed to mount addon '" .. addonName .. "'!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
	end
end

pfm.util.mount_sub_addons = function()
	if pfm.util.subAddonsLoaded then
		return
	end
	pfm.util.subAddonsLoaded = true
	local _, dirs = file.find("addons/filmmaker/addons/*")
	for _, subAddon in ipairs(dirs) do
		pfm.util.mount_sub_addon(subAddon)
	end
end
