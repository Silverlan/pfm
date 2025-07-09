-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local loaded
function pfm.load_unirender()
	if loaded ~= nil then
		return loaded
	end

	pfm.log("Loading unirender module...", pfm.LOG_CATEGORY_PFM_RENDER)

	local r = engine.load_library("unirender/pr_unirender")
	if r ~= true then
		loaded = false
		pfm.log("Unable to load unirender module: " .. r, pfm.LOG_CATEGORY_PFM_RENDER, pfm.LOG_SEVERITY_ERROR)
		return loaded
	end
	unirender.set_log_enabled(pfm.is_log_category_enabled(pfm.LOG_CATEGORY_PFM_UNIRENDER))
	unirender.set_kernel_compile_callback(function(building)
		local pm = tool.get_filmmaker()
		if util.is_valid(pm) == false then
			return
		end
		pm:SetBuildKernels(building)
	end)

	loaded = true
	pfm.log("Loading unirender shaders...", pfm.LOG_CATEGORY_PFM_RENDER)
	include("/unirender/shaders/")
	return loaded
end
