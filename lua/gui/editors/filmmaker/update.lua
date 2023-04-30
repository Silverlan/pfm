--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIFilmmaker

pfm.register_log_category("update")

function Element:CheckForUpdates(verbose)
	local r = engine.load_library("git/pr_git")
	if(r ~= true) then
		pfm.log("Failed to load pr_git module: " .. r,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local res,err = git.get_remote_tags("https://github.com/Silverlan/pragma.git")
	if(res == false) then
		pfm.log("Failed to retrieve remote tags: " .. err,pfm.LOG_CATEGORY_PFM,pfm.LOG_SEVERITY_WARNING)
		return
	end

	local highestVersion = util.Version(0,0,0)
	for _,tag in ipairs(res) do
		if(tag:sub(1,1) == "v") then
			local v = util.Version(tag:sub(2))
			if(v > highestVersion) then highestVersion = v end
		end
	end

	local curVersion = engine.get_info().version
	if(highestVersion > curVersion) then
		-- New version available!
		local updateUrl = "https://github.com/Silverlan/pragma/releases/download/v" .. highestVersion:ToString()
        pfm.open_message_prompt(
            "New update available",
            "A new update is available. Would you like to download it now?",
            bit.bor(gui.PfmPrompt.BUTTON_YES,gui.PfmPrompt.BUTTON_NO),
            function(bt)
                if(bt == gui.PfmPrompt.BUTTON_YES) then
                    local fileName
                    if(os.SYSTEM_WINDOWS) then
                        fileName = "pragma-v" .. highestVersion:ToString() .. "-win64.zip"
                    else
                        fileName = "pragma-v" .. highestVersion:ToString() .. "-lin64.zip"
                    end

                    self:DownloadUpdate(updateUrl .. "/" .. fileName)
                    pfm.create_popup_message(
                        "The update will be downloaded in the background and installed when you quit PFM.",
                        6
                    )
                end
            end
        )
	elseif(verbose) then
		pfm.create_popup_message(locale.get_text("pfm_up_to_date",{pfm.VERSION:ToString()}))
	end
end

local function download_file(url,resultHandler,progressHandler,timeout)
    local r = engine.load_library("chromium/pr_chromium")
    if(r ~= true) then
        resultHandler(false,"Failed to load pr_chromium_module")
        return
    end
    pfm.log("Downloading file '" .. url .. "'...",pfm.LOG_CATEGORY_UPDATE,pfm.LOG_SEVERITY_INFO)
    local wb = gui.create("WIWeb")
    wb:SetBrowserViewSize(Vector2i(1,1))
    wb:SetSize(1,1)
    wb:SetInitialUrl(url)
    local dlId
    local filePath
    wb:AddCallback("OnDownloadStarted",function(el,id,path)
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
    cbUpdate = wb:AddCallback("OnDownloadUpdate",function(el,id,state,percentage)
        if(id == dlId) then
            util.remove(timeoutTimer)
            if(state == chromium.DOWNLOAD_STATE_CANCELLED) then
                resultHandler(false,"Download was cancelled.")
            elseif(state == chromium.DOWNLOAD_STATE_COMPLETE) then
                resultHandler(true,filePath)
            elseif(state == chromium.DOWNLOAD_STATE_INVALIDATED) then
                resultHandler(false,"Download was invalidated.")
            else
                progressHandler(percentage)
            end
        end
    end)
    
    timeoutTimer = time.create_timer(timeout,0,function()
        resultHandler(false,"Timeout.")
    end)
    timeoutTimer:Start()

    wb:ScheduleUpdate()
    wb:SetAlwaysUpdate(true)
    wb:SetVisible(false)
end

local function extract_update_files(filePath)
    local zipFile = util.ZipFile.open(filePath,util.ZipFile.OPEN_MODE_READ)
    if(zipFile == nil) then
        file.delete(filePath)
        return false,"Failed to open zip file '" .. filePath .. "'."
    end
    pfm.log("Extracting update files '" .. filePath .. "'...",pfm.LOG_CATEGORY_UPDATE,pfm.LOG_SEVERITY_INFO)
    file.delete_directory("update")
    file.create_directory("update")
    local res,err = zipFile:ExtractFiles("update")
    if(res == false) then
        file.delete(filePath)
        return false,err
    end

    -- We can't update pragma while it's running, so the installation will be handled by the updater instead.
    -- Since the updater can't update itself, we have to copy the new version to the root directory first.
    local updaterPath
    if(os.SYSTEM_WINDOWS) then
        updaterPath = "bin/updater.exe"
    else
        updaterPath = "lib/updater"
    end
    file.copy("update/" .. updaterPath,updaterPath)
    file.delete("update/" .. updaterPath)
    return true
end

function Element:DownloadUpdate(url)
    if(self.m_updateScheduled) then return end
    self.m_updateScheduled = true
    pfm.log("Downloading update '" .. url .. "'...",pfm.LOG_CATEGORY_UPDATE,pfm.LOG_SEVERITY_INFO)
    local function autoupdate(resultHandler,progressHandler)
        download_file(url,function(success,msgOrPath)
            if(success == false) then
                resultHandler(false,msgOrPath)
                return
            end
            local res,err = extract_update_files(msgOrPath:GetString())
            resultHandler(res,err)
        end,progressHandler,10)
    end
    autoupdate(function(success,result)
        if(success == false) then
            pfm.log("Failed to download update: " .. result .. "...",pfm.LOG_CATEGORY_UPDATE,pfm.LOG_SEVERITY_ERROR)
            return
        end
        pfm.log("Update downloaded successfully.",pfm.LOG_CATEGORY_UPDATE,pfm.LOG_SEVERITY_INFO)
        self.m_runUpdaterOnShutdown = true
    end,function(progress)
        print("Update download progress: ",progress)
    end)
end
