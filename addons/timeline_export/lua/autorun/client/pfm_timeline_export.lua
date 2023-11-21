--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}
pfm.util = pfm.util or {}
function pfm.util.export_xml_timeline(pm)
	local session = pm:GetSession()

	local settings = session:GetSettings()
	local renderSettings = settings:GetRenderSettings()

	local projectionType
	local stereoscopic = false
	if toint(renderSettings:GetCameraType()) == pfm.RaytracingRenderJob.Settings.CAM_TYPE_PANORAMA then
		local panoramaType = toint(renderSettings:GetPanoramaType())
		if panoramaType == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_EQUIRECTANGULAR then
			projectionType = pfm.util.XMLTimelineExporter.PROJECTION_TYPE_EQUIRECTANGULAR
			stereoscopic = renderSettings:IsStereoscopic()
		elseif
			panoramaType == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUIDISTANT
			or panoramaType == pfm.RaytracingRenderJob.Settings.PANORAMA_TYPE_FISHEYE_EQUISOLID
		then
			projectionType = pfm.util.XMLTimelineExporter.PROJECTION_TYPE_FISHEYE
		end
	end

	local width = renderSettings:GetWidth()
	local height = renderSettings:GetHeight()
	local frameRate = renderSettings:GetFrameRate()
	local exporter = pfm.util.XMLTimelineExporter(width, height, frameRate)
	if projectionType ~= nil then
		exporter:SetProjectionType(projectionType)
	end
	exporter:SetStereoscopic(stereoscopic)

	for _, clip in ipairs(session:GetClips()) do
		local soundTrackGroup
		local filmTrackGroup
		for _, trackGroup in ipairs(clip:GetTrackGroups()) do
			if trackGroup:GetName() == "Sound" then
				soundTrackGroup = trackGroup
			end
			if trackGroup:GetName() == "subClipTrackGroup" then
				filmTrackGroup = trackGroup
			end
		end
		local absRootPath = util.get_program_path()
		if soundTrackGroup ~= nil then
			for _, track in ipairs(soundTrackGroup:GetTracks()) do
				for _, audioClip in ipairs(track:GetAudioClips()) do
					local soundObject = (audioClip ~= nil) and audioClip:GetSound() or nil
					local timeFrame = (audioClip ~= nil) and audioClip:GetTimeFrame() or nil
					if soundObject ~= nil and timeFrame ~= nil then
						local soundName = soundObject:GetSoundName()
						local soundPath = asset.find_file(soundName, asset.TYPE_AUDIO)
						if soundPath ~= nil then
							local soundDuration = sound.get_duration(soundPath)
							soundPath = file.find_absolute_path(
								asset.get_asset_root_directory(asset.TYPE_AUDIO) .. "/" .. soundPath
							)
							if soundPath ~= nil then
								local start = timeFrame:GetStart()
								local duration = timeFrame:GetDuration()
								local pitch = soundObject:GetPitch()
								local volume = soundObject:GetVolume()
								-- TODO: Can we apply pitch and volume somehow?
								local absSoundPath = absRootPath .. soundPath
								if absSoundPath ~= nil then
									exporter:AddAudio(
										absSoundPath,
										math.round(start * 1000),
										math.ceil(duration * 1000),
										math.ceil((soundDuration or duration) * 1000)
									)
								end
							end
						end
					end
				end
			end
		end
		if filmTrackGroup ~= nil then
			local clipName = clip:GetName()
			for _, track in ipairs(filmTrackGroup:GetTracks()) do
				for _, filmClip in ipairs(track:GetFilmClips()) do
					local filmClipName = filmClip:GetName()
					local renderRootPath = "render/" .. clipName .. "/" .. filmClipName .. "/"
					local timeFrame = filmClip:GetTimeFrame()
					local duration = timeFrame:GetDuration()
					local start = timeFrame:GetStart()

					local files = file.find(renderRootPath .. "*.png")
					table.sort(files)
					local frameToFile = {}
					for _, f in ipairs(files) do
						local frameIndex = tonumber(string.match(f, "%d+"))
						frameToFile[frameIndex] = f
					end

					local startFrame = 1
					local endFrame = math.ceil(duration * frameRate)
					local sequenceStart
					local sequencePaths = {}
					local function update_sequence(sequenceEnd)
						if sequenceStart == nil then
							return
						end
						local sequenceStartTime = start + (sequenceStart - 1) * (1.0 / frameRate)
						exporter:AddFrameSequence(filmClipName, sequencePaths, math.round(sequenceStartTime * 1000))

						sequenceStart = nil
						sequencePaths = {}
					end
					for i = startFrame, endFrame do
						local validFrame = false
						if frameToFile[i] ~= nil then
							local path = renderRootPath .. frameToFile[i]
							local absPath = file.find_absolute_path(path)
							if absPath ~= nil then
								validFrame = true
								sequenceStart = sequenceStart or i
								table.insert(sequencePaths, absRootPath .. absPath)
							end
						end
						if validFrame == false then
							update_sequence(i)
						end
					end
					update_sequence(endFrame)
				end
			end
		end
	end
	return exporter:GenerateXML()
end

pfm.add_event_listener("OnFilmmakerLaunched", function(pm)
	include("/pfm/timeline_export/xml_timeline_exporter.lua")
	pm:RegisterMenuOption("export", function(pContextMenu)
		local pSubItem = pContextMenu:AddItem(locale.get_text("pfm_timeline"), function(pItem)
			if util.is_valid(pm) == false then
				return
			end
			local xml = pfm.util.export_xml_timeline(pm)
			if xml == nil then
				return
			end

			local pFileDialog
			pFileDialog = gui.create_file_save_dialog(function(pDialoge, fileName)
				if fileName == nil then
					return
				end
				fileName = file.remove_file_extension(fileName, { "xml" })
				fileName = fileName .. ".xml"

				xml = '<?xml version="1.0" encoding="UTF-8"?>\n' .. "<!DOCTYPE fcpxml>\n" .. xml

				if file.write(fileName, xml) then
					util.open_path_in_explorer(file.get_file_path(fileName), file.get_file_name(fileName))
				end
			end)
			pFileDialog:SetRootPath("")
			pFileDialog:Update()
		end)
		pSubItem:SetName("export_timeline")
	end)
end)
