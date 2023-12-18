--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
			pfm.log(msg, pfm.LOG_CATEGORY_PFM, pfm.LOG_SEVERITY_WARNING)
		end
	end)
end

local function download_file(url, resultHandler, progressHandler, timeout)
	local r = engine.load_library("chromium/pr_chromium")
	if r ~= true then
		resultHandler(false, "Failed to load pr_chromium_module")
		return
	end
	pfm.log("Downloading file '" .. url .. "'...", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_INFO)
	local wb = gui.create("WIWeb")
	wb:SetBrowserViewSize(Vector2i(1, 1))
	wb:SetSize(1, 1)
	wb:SetInitialUrl(url)
	local dlId
	local filePath
	wb:AddCallback("OnDownloadStarted", function(el, id, path)
		dlId = id
		filePath = path
	end)
	local h = resultHandler
	local timeoutTimer
	resultHandler = function(...)
		util.remove(wb)
		util.remove(timeoutTimer)
		return h(...)
	end
	local cbUpdate
	cbUpdate = wb:AddCallback("OnDownloadUpdate", function(el, id, state, percentage)
		if id == dlId then
			util.remove(timeoutTimer)
			if state == chromium.DOWNLOAD_STATE_CANCELLED then
				resultHandler(false, "Download was cancelled.")
			elseif state == chromium.DOWNLOAD_STATE_COMPLETE then
				resultHandler(true, filePath)
			elseif state == chromium.DOWNLOAD_STATE_INVALIDATED then
				resultHandler(false, "Download was invalidated.")
			else
				progressHandler(percentage)
			end
		end
	end)

	timeoutTimer = time.create_timer(timeout, 0, function()
		resultHandler(false, "Timeout.")
	end)
	timeoutTimer:Start()

	wb:ScheduleUpdate()
	wb:SetAlwaysUpdate(true)
	wb:SetVisible(false)
end

local function extract_update_files(filePath)
	local zipFile = util.ZipFile.open(filePath, util.ZipFile.OPEN_MODE_READ)
	if zipFile == nil then
		file.delete(filePath)
		return false, "Failed to open zip file '" .. filePath .. "'."
	end
	pfm.log("Extracting update files '" .. filePath .. "'...", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_INFO)
	file.delete_directory("update")
	file.create_directory("update")
	local res, err = zipFile:ExtractFiles("update")
	if res == false then
		file.delete(filePath)
		return false, err
	end

	-- We can't update pragma while it's running, so the installation will be handled by the updater instead.
	-- Since the updater can't update itself, we have to copy the new version to the root directory first.
	local updaterPath
	if os.SYSTEM_WINDOWS then
		updaterPath = "bin/updater.exe"
	else
		updaterPath = "lib/updater"
	end
	file.copy("update/" .. updaterPath, updaterPath)
	file.delete("update/" .. updaterPath)
	return true
end

function Element:DownloadUpdate(url)
	if self.m_updateScheduled then
		return
	end
	self.m_updateScheduled = true
	pfm.log("Downloading update '" .. url .. "'...", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_INFO)
	local function autoupdate(resultHandler, progressHandler)
		download_file(url, function(success, msgOrPath)
			if success == false then
				resultHandler(false, msgOrPath)
				return
			end
			pfm.create_popup_message(locale.get_text("pfm_preparing_update_files"), 3)
			time.create_simple_timer(2.0, function()
				local res, err = extract_update_files(msgOrPath:GetString())
				resultHandler(res, err)
			end)
		end, progressHandler, 10)
	end
	util.remove(self.m_updateProgressBar)
	self.m_updateProgressBar = self:AddProgressStatusBar("update", locale.get_text("pfm_updating"))
	autoupdate(function(success, result)
		util.remove(self.m_updateProgressBar)
		if success == false then
			pfm.log("Failed to download update: " .. result .. "!", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_ERROR)

			pfm.create_popup_message(locale.get_text("pfm_update_download_failed", { tostring(result) }), 6)
			return
		end
		pfm.log("Update downloaded successfully.", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_INFO)
		self.m_runUpdaterOnShutdown = true

		pfm.create_popup_message(locale.get_text("pfm_update_ready"), 6)
	end, function(progress)
		print("Update download progress: ", progress)
		if util.is_valid(self.m_updateProgressBar) then
			self.m_updateProgressBar:SetProgress(progress / 100.0)
		end
	end)
end
