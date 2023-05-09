--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:LoadTutorial(tutorial)
	pfm.log("Loading tutorial '" .. tutorial .. "'...", pfm.LOG_CATEGORY_PFM)
	local fileName = "tutorials/" .. file.remove_file_extension(tutorial, { "udm" }) .. ".udm"
	local udmData, err = udm.load(fileName)
	if udmData == false then
		pfm.log("Failed to load tutorial '" .. tutorial, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		return false, err
	end
	udmData = udmData:GetAssetData():GetData()
	local udmTutorial = udmData:Get("tutorial")
	local scriptFile = udmTutorial:GetValue("script_file", udm.TYPE_STRING)
	if scriptFile ~= nil then
		pfm.log("Loading script '" .. scriptFile .. "' for tutorial '" .. tutorial .. "'...", pfm.LOG_CATEGORY_PFM)
		include(scriptFile)

		gui.Tutorial.start_tutorial(udmTutorial:GetValue("name", udm.TYPE_STRING) or "")
	else
		local projectFile = udmTutorial:GetValue("project_file", udm.TYPE_STRING)
		if projectFile ~= nil then
			pfm.log(
				"Loading project '" .. projectFile .. "' for tutorial '" .. tutorial .. "'...",
				pfm.LOG_CATEGORY_PFM
			)
			self:LoadProject(projectFile)
		end
	end
end
