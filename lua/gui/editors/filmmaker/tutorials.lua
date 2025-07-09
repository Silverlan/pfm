-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = gui.WIFilmmaker

function Element:LoadTutorial(tutorial)
	self:LogInfo("Loading tutorial '" .. tutorial .. "'...")
	local fileName = "tutorials/" .. file.remove_file_extension(tutorial, { "udm" }) .. ".udm"
	local udmData, err = udm.load(fileName)
	if udmData == false then
		self:LogWarn("Failed to load tutorial '" .. tutorial .. "': " .. err)
		return false, err
	end
	udmData = udmData:GetAssetData():GetData()
	local udmTutorial = udmData:Get("tutorial")
	local scriptFile = udmTutorial:GetValue("script_file", udm.TYPE_STRING)
	if scriptFile ~= nil then
		self:LogInfo("Loading script '" .. scriptFile .. "' for tutorial '" .. tutorial .. "'...")
		include(scriptFile)

		gui.Tutorial.start_tutorial(udmTutorial:GetValue("name", udm.TYPE_STRING) or "")
	else
		local projectFile = udmTutorial:GetValue("project_file", udm.TYPE_STRING)
		if projectFile ~= nil then
			self:LogInfo("Loading project '" .. projectFile .. "' for tutorial '" .. tutorial .. "'...")
			self:LoadProject(projectFile)
		end
	end
end

function Element:SetTutorialCompleted(name)
	if name == nil then
		name = gui.Tutorial.get_current_tutorial_identifier()
		if name == nil then
			return
		end
	end
	local gsd = tool.get_filmmaker():GetGlobalStateData()
	local udmTutorials = gsd:Get("tutorials")
	local udmTutorial = udmTutorials:Get(name)
	udmTutorial:SetValue("completed", udm.TYPE_BOOLEAN, true)
	self:SaveGlobalStateData()
end

function Element:IsTutorialCompleted(name)
	local gsd = tool.get_filmmaker():GetGlobalStateData()
	local udmTutorials = gsd:Get("tutorials")
	local udmTutorial = udmTutorials:Get(name)
	return udmTutorial:GetValue("completed", udm.TYPE_BOOLEAN) or false
end
