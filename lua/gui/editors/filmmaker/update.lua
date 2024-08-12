--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/update.lua")

local Element = gui.WIFilmmaker

pfm.register_log_category("update")

pfm.UPDATE_CHECK_RESULT_NO_UPDATE_AVAILABLE = 0
pfm.UPDATE_CHECK_RESULT_UPDATE_AVAILABLE = 1
pfm.UPDATE_CHECK_RESULT_FAILED = 2
pfm.check_for_updates = function(callback)
	local r = engine.load_library("git/pr_git")
	if r ~= true then
		callback(pfm.UPDATE_CHECK_RESULT_FAILED, "Failed to load pr_git module: " .. r)
		return
	end

	local res, err = git.get_remote_tags("https://github.com/Silverlan/pragma.git")
	if res == false then
		callback(pfm.UPDATE_CHECK_RESULT_FAILED, "Failed to retrieve remote tags: " .. err)
		return
	end

	local enableExperimental = console.get_convar_bool("pfm_enable_experimental_updates")
	if enableExperimental then
		local gitInfo = engine.get_git_info()
		local newVersionAvailable = false
		local versionSha
		for _, tagInfo in ipairs(res) do
			if tagInfo.tagName == "nightly" then
				if gitInfo == nil or tagInfo.sha ~= gitInfo.commitSha then
					newVersionAvailable = true
					versionSha = tagInfo.sha
				end
				break
			end
		end
		if newVersionAvailable then
			callback(pfm.UPDATE_CHECK_RESULT_UPDATE_AVAILABLE, true, versionSha)
		else
			callback(pfm.UPDATE_CHECK_RESULT_NO_UPDATE_AVAILABLE, true, (gitInfo ~= nil) and gitInfo.commitSha or nil)
		end
		return
	end

	local highestVersion = util.Version(0, 0, 0)
	for _, tagInfo in ipairs(res) do
		if tagInfo.tagName:sub(1, 1) == "v" then
			local v = util.Version(tagInfo.tagName:sub(2))
			if v > highestVersion then
				highestVersion = v
			end
		end
	end

	local curVersion = engine.get_info().version
	if highestVersion > curVersion then
		callback(pfm.UPDATE_CHECK_RESULT_UPDATE_AVAILABLE, false, highestVersion)
	else
		callback(pfm.UPDATE_CHECK_RESULT_NO_UPDATE_AVAILABLE)
	end
end

pfm.util = pfm.util or {}
pfm.util.get_release_archive_postfix = function()
	if os.SYSTEM_WINDOWS then
		return "-win64.zip"
	else
		return "-lin64.tar.gz"
	end
end

function Element:CheckForUpdates(verbose)
	if self:AreAutomaticUpdatesEnabled() == false then
		return
	end
	local function download_update(updateUrl, fileName)
		pfm.open_message_prompt(
			locale.get_text("pfm_new_update_available"),
			locale.get_text("pfm_update_available_download_now"),
			bit.bor(gui.PfmPrompt.BUTTON_YES, gui.PfmPrompt.BUTTON_NO),
			function(bt)
				if bt == gui.PfmPrompt.BUTTON_YES then
					self:DownloadUpdate(updateUrl .. "/" .. fileName)
					pfm.create_popup_message(locale.get_text("pfm_update_info"), 6)
				end
			end
		)
	end
	pfm.check_for_updates(function(resultCode, ...)
		if resultCode == pfm.UPDATE_CHECK_RESULT_NO_UPDATE_AVAILABLE then
			local experimental, sha = ...
			if verbose then
				if experimental then
					pfm.create_popup_message(locale.get_text("pfm_up_to_date", { sha or locale.get_text("unknown") }))
				else
					pfm.create_popup_message(locale.get_text("pfm_up_to_date", { pfm.VERSION:ToString() }))
				end
			end
		elseif resultCode == pfm.UPDATE_CHECK_RESULT_UPDATE_AVAILABLE then
			local experimental = ...
			if experimental then
				local updateUrl = "https://github.com/Silverlan/pragma/releases/download/nightly"
				local fileName = "pragma" .. pfm.util.get_release_archive_postfix()
				download_update(updateUrl, fileName)
			else
				local newVersion = select(2, ...)
				-- New version available!
				local updateUrl = "https://github.com/Silverlan/pragma/releases/download/v" .. newVersion:ToString()
				local fileName = "pragma-v" .. newVersion:ToString() .. pfm.util.get_release_archive_postfix()
				download_update(updateUrl, fileName)
			end
		elseif resultCode == pfm.UPDATE_CHECK_RESULT_FAILED then
			local msg = ...
			self:LogWarn(msg)
		end
	end)
end

function Element:DownloadUpdate(url)
	if self.m_updateScheduled then
		return
	end
	self.m_updateScheduled = true

	util.remove(self.m_updateProgressBar)
	self.m_updateProgressBar = self:AddProgressStatusBar("update", locale.get_text("pfm_updating"))

	self.m_updateJob = pfm.update(url, function(worker)
		util.remove(self.m_updateProgressBar)
		if worker:IsSuccessful() == false then
			self:LogErr("Failed to download update: " .. worker:GetResultMessage() .. "!")

			pfm.create_popup_message(
				locale.get_text("pfm_update_download_failed", { tostring(worker:GetResultMessage()) }),
				6
			)
			return
		end
		self:LogInfo("Update downloaded successfully.")
	end)
	self.m_updateJob:SetProgressCallback(function(worker, progress)
		if util.is_valid(self.m_updateProgressBar) then
			self.m_updateProgressBar:SetProgress(progress)
		end
	end)
end
