--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.WIBaseFilmmaker

function Element:BuildKernels()
	if util.is_valid(self.m_rtBuildKernels) then
		return
	end
	local tFiles = file.find("modules/unirender/cycles/cache/kernels/*")
	if #tFiles > 0 then
		return
	end
	local rt = gui.create("WIRealtimeRaytracedViewport", self)
	rt:Refresh(true)
	self.m_rtBuildKernels = rt
end
function Element:SetBuildKernels(buildKernels)
	if buildKernels == self.m_buildingKernels then
		return
	end
	self.m_buildingKernels = buildKernels
	if buildKernels and util.is_valid(self.m_kernelsBuildMessage) then
		return
	end
	util.remove(self.m_kernelsBuildMessage)
	util.remove(self.m_cbKernelProgress)
	util.remove(self.m_kernelProgressBar)
	if buildKernels == false then
		util.remove(self.m_rtBuildKernels)
		-- pfm.create_popup_message(locale.get_text("pfm_render_kernels_built_msg"), false)
	end
	if buildKernels == false then
		return
	end
	local frame = self.m_windowFrames["timeline"]
	if util.is_valid(frame) == false then
		return
	end
	local tabContainer = frame:GetTabContainer()
	if util.is_valid(tabContainer) == false then
		return
	end
	self.m_kernelsBuildMessage = gui.create("WIKernelsBuildMessage", tabContainer)
	self.m_kernelProgressBar = self:AddProgressStatusBar("kernel", locale.get_text("pfm_building_kernels"))
	local tStart = time.real_time()
	self.m_cbKernelProgress = game.add_callback("Think", function()
		-- There's no way to get the actual kernel progress, so we'll just
		-- move the progress bar to indicate that something is happening.
		local dt = time.real_time() - tStart
		local f = (dt % 5.0) / 5.0
		self.m_kernelProgressBar:SetProgress(f)
	end)

	-- pfm.create_popup_message(locale.get_text("pfm_building_render_kernels_msg"), 16)
end
function Element:CheckBuildKernels()
	local buildingKernels = self.m_buildingKernels or false
	if buildingKernels == false then
		return false
	end
	-- pfm.create_popup_message(locale.get_text("pfm_wait_for_kernels"), 16)
	return true
end
function Element:OpenUrlInBrowser(url)
	self:OpenWindow("web_browser")
	self:GoToWindow("web_browser")
	time.create_simple_timer(0.25, function()
		if self:IsValid() == false then
			return
		end
		local w = self:GetWindow("web_browser")
		w = util.is_valid(w) and w:GetBrowser() or nil
		w = util.is_valid(w) and w:GetWebBrowser() or nil
		if util.is_valid(w) == false then
			return
		end
		w:LoadUrl(url)
	end)
end
function Element:DoChangeMap(mapName)
	tool.close_filmmaker()
	pfm.show_loading_screen(true, locale.get_text("pfm_loading_map", { mapName }))
	time.create_simple_timer(0.1, function()
		console.run("pfm_restore", "1")
		console.run("map", mapName)
	end)
end
function Element:ChangeMap(map, projectFileName)
	pfm.log("Changing map to '" .. map .. "'...", pfm.LOG_CATEGORY_PFM)
	time.create_simple_timer(0.0, function()
		local elBase = gui.get_base_element()
		local mapName = asset.get_normalized_path(map, asset.TYPE_MAP)

		local el = udm.create_element()
		local writeNewMapName = (projectFileName == nil)
		local restoreProjectName = projectFileName
		projectFileName = projectFileName or self:GetProjectFileName()
		if projectFileName ~= nil then
			el:SetValue("originalProjectFileName", udm.TYPE_STRING, projectFileName)
		end

		file.create_path("temp/pfm/restore")
		if restoreProjectName == nil then
			restoreProjectName = "temp/pfm/restore/project"
			if self:Save(restoreProjectName, false, nil, false) == false then
				pfm.log(
					"Failed to save restore project. Map will not be changed!",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_ERROR
				)
				return
			end
		end
		el:SetValue("restoreProjectFileName", udm.TYPE_STRING, restoreProjectName)
		if writeNewMapName then
			el:SetValue("newProjectMapName", udm.TYPE_STRING, map)
		end

		local udmData, err = udm.create("PFMRST", 1)
		local assetData = udmData:GetAssetData()
		assetData:GetData():Merge(el:Get())

		local f = file.open("temp/pfm/restore/restore.udm", file.OPEN_MODE_WRITE)
		if f ~= nil then
			local res, msg = udmData:SaveAscii(f)
			f:Close()

			if res == false then
				pfm.log(
					"Failed to write restore file. Map will not be changed!",
					pfm.LOG_CATEGORY_PFM,
					pfm.LOG_SEVERITY_ERROR
				)
				return
			end
		else
			pfm.log(
				"Failed to write restore file. Map will not be changed!",
				pfm.LOG_CATEGORY_PFM,
				pfm.LOG_SEVERITY_ERROR
			)
			return
		end

		self:DoChangeMap(mapName)
	end)
end
