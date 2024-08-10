--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

function Element:UpdateAutosave(clear)
	if self.m_autoSave ~= nil then
		self.m_autoSave:Clear()
		self.m_autoSave = nil
	end
	if clear or console.get_convar_bool("pfm_autosave_enabled") == false then
		return
	end
	self.m_autoSave = pfm.AutoSave()
end
function Element:IsAutosaveEnabled()
	return self.m_autoSave ~= nil
end
function Element:Save(fileName, setAsProjectName, saveAs, withProjectsPrefix, resultCallback)
	local project = self:GetProject()
	if project == nil then
		if resultCallback ~= nil then
			resultCallback(true)
		end
		return
	end
	if self:IsDeveloperModeEnabled() == false and saveAs ~= true then
		local session = self:GetSession()
		if session ~= nil and session:GetSettings():IsReadOnly() then
			pfm.log("Failed to save project: Project is read-only!", pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_ERROR)
			local msgReadOnly = locale.get_text("pfm_project_read_only")
			pfm.create_popup_message(
				locale.get_text("pfm_save_failed_reason", { msgReadOnly }),
				false,
				gui.InfoBox.TYPE_ERROR
			)
			if resultCallback ~= nil then
				resultCallback(true)
			end
			return
		end
	end
	if setAsProjectName == nil then
		setAsProjectName = true
	end
	local function saveProject(fileName)
		self:UpdateWorkCamera()
		self:UpdateWindowLayoutState()
		file.create_directory("projects")
		local ext = file.get_file_extension(fileName)
		local saveAsAscii = (ext == pfm.Project.FORMAT_EXTENSION_ASCII)
		fileName = file.remove_file_extension(fileName, pfm.Project.get_format_extensions())
		fileName = pfm.Project.get_full_project_file_name(fileName, withProjectsPrefix, saveAsAscii)
		if setAsProjectName then
			self:UpdateProjectName(fileName)
		end
		local res = self:SaveProject(fileName, setAsProjectName and fileName or nil)
		if res then
			pfm.create_popup_message(locale.get_text("pfm_save_success", { fileName }), 1)
			if setAsProjectName then
				self:AddRecentProject(fileName)
			end
		else
			pfm.create_popup_message(locale.get_text("pfm_save_failed", { fileName }), false, gui.InfoBox.TYPE_ERROR)
		end
		return res
	end
	if fileName == nil and saveAs ~= true then
		local projectFileName = self:GetProjectFileName()
		if projectFileName ~= nil then
			fileName = util.Path.CreateFilePath(projectFileName)
			fileName:PopFront() -- Pop "projects/"
			fileName = fileName:GetString()
		end
	end
	if fileName ~= nil then
		local res = saveProject(fileName)
		if resultCallback ~= nil then
			resultCallback(res)
		end
	else
		util.remove(self.m_openDialogue)
		local path = tool.get_filmmaker():GetFileDialogPath("project_path")
		self.m_openDialogue = pfm.create_file_save_dialog(function(pDialog, fileName)
			local res = saveProject(fileName)
			if resultCallback then
				resultCallback(res)
				tool.get_filmmaker()
					:SetFileDialogPath(
						"project_path",
						file.get_file_path(self.m_openDialogue:MakePathRelative(fileName))
					)
			end
		end)
		self.m_openDialogue:SetRootPath("projects")
		self.m_openDialogue:SetExtensions(pfm.Project.get_format_extensions())
		if path ~= nil then
			self.m_openDialogue:SetPath(path)
		end
		self.m_openDialogue:Update()
	end
end
