--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

console.register_variable(
	"pfm_autosave_enabled",
	udm.TYPE_BOOLEAN,
	true,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Enables or disables PFM autosaving."
)
console.register_variable(
	"pfm_autosave_max_count",
	udm.TYPE_UINT16,
	5,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Maximum number of autosaves before old ones will be overwritten."
)
console.register_variable(
	"pfm_autosave_time_interval",
	udm.TYPE_UINT32,
	10 * 60,
	bit.bor(console.FLAG_BIT_ARCHIVE),
	"Time in seconds between autosaves."
)

pfm = pfm or {}

util.register_class("pfm.AutoSave", util.CallbackHandler)
function pfm.AutoSave:__init()
	util.CallbackHandler.__init(self)
	self.m_curAutoSaveId = 1
	self:UpdateTimer()
end

function pfm.AutoSave:Clear()
	util.remove(self.m_timer)
end

function pfm.AutoSave:UpdateTimer()
	self:Clear()
	local timeInterval = console.get_convar_int("pfm_autosave_time_interval")
	self.m_timer = time.create_timer(timeInterval, -1, function()
		self:Save()
	end)
	self.m_timer:Start()
end

function pfm.AutoSave:DetermineName(fileName)
	local baseFileName = file.remove_file_extension(fileName, pfm.Project.get_format_extensions())

	--[[local autoSaveFileName
	local i = 1
	while(autoSaveFileName == nil or file.exists(pfm.Project.get_full_project_file_name(autoSaveFileName))) do
		autoSaveFileName = baseFileName .. "_autosave" .. i
		i = i +1
	end]]

	local maxAutoSaveCount = console.get_convar_int("pfm_autosave_max_count")
	local autoSaveFileName = baseFileName .. "_autosave" .. self.m_curAutoSaveId
	self.m_curAutoSaveId = (self.m_curAutoSaveId % maxAutoSaveCount) + 1
	return autoSaveFileName
end

function pfm.AutoSave:Save()
	local fm = tool.get_filmmaker()
	local session = fm:GetSession()
	if session ~= nil and session:GetSettings():IsReadOnly() and fm:IsDeveloperModeEnabled() == false then
		return
	end

	local fileName = fm:GetProjectFileName() or "unnamed"
	local autoSaveFileName = self:DetermineName(fileName)
	fm:Save(autoSaveFileName, false)
end
