--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("util.lua")

local function extract_update_files(filePath)
	file.delete_directory("update")
	file.create_directory("update")
	local job = util.create_parallel_job("extract_update_files", function(worker)
		pfm.log(
			"Extracting update files from archive '" .. filePath .. "'...",
			pfm.LOG_CATEGORY_UPDATE,
			pfm.LOG_SEVERITY_INFO
		)
		local jobExtract = pfm.util.extract_archive(filePath, "update")
		if jobExtract == false then
			return false
		end
		jobExtract:Start()
		worker:AddTask(jobExtract, function(worker)
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
			if os.SYSTEM_WINDOWS then
				-- This is the font used for the console. Unfortunately the file cannot be deleted after being used at least once
				-- until Windows is restarted, so we'll exempt it from the update (It's unlikely to ever be updated anyway).
				file.delete("update/fonts/ubuntu/UbuntuMono-R.ttf")
			end
			worker:SetStatus(util.ParallelJob.JOB_STATUS_SUCCESSFUL)
			return util.Worker.TASK_STATUS_COMPLETE
		end, 1.0)
		return util.Worker.TASK_STATUS_COMPLETE
	end, function(worker) end)
	job:Start()
	return job
end

pfm.update = function(url, onComplete)
	local job = util.create_parallel_job("update_pfm", function(worker)
		pfm.log("Downloading update '" .. url .. "'...", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_INFO)
		local jobDl, archiveFileNameOrErr = pfm.util.download_file(url, "temp/")
		if jobDl == false then
			local err = archiveFileNameOrErr
			worker:SetStatus(util.ParallelJob.JOB_STATUS_FAILED, err)
			return util.Worker.TASK_STATUS_COMPLETE
		end
		worker:AddTask(jobDl, function(worker)
			pfm.log("Update download complete, starting extraction...", pfm.LOG_CATEGORY_UPDATE, pfm.LOG_SEVERITY_INFO)
			local archiveFileName = archiveFileNameOrErr
			local jobExtract = extract_update_files(archiveFileName)
			if jobExtract == false then
				worker:SetStatus(util.ParallelJob.JOB_STATUS_FAILED, "Failed to extract update files!")
				return util.Worker.TASK_STATUS_COMPLETE
			end
			worker:AddTask(jobExtract, function(worker)
				pfm.log(
					"Extraction of update files complete! Files will be installed on exit.",
					pfm.LOG_CATEGORY_UPDATE,
					pfm.LOG_SEVERITY_INFO
				)
				worker:SetStatus(util.ParallelJob.JOB_STATUS_SUCCESSFUL)

				util.run_updater()
				return util.Worker.TASK_STATUS_COMPLETE
			end, 0.5)
			return util.Worker.TASK_STATUS_COMPLETE
		end, 0.5)
		return util.Worker.TASK_STATUS_COMPLETE
	end, function() end)
	if onComplete ~= nil then
		job:CallOnComplete(onComplete)
	end
	job:Start()
	return job
end
