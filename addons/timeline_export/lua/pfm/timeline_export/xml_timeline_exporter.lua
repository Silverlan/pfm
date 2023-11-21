--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local xml2lua = require("xml2lua")

pfm = pfm or {}
pfm.util = pfm.util or {}
util.register_class("pfm.util.XMLTimelineExporter")
pfm.util.XMLTimelineExporter.PROJECTION_TYPE_EQUIRECTANGULAR = "equirectangular"
pfm.util.XMLTimelineExporter.PROJECTION_TYPE_FISHEYE = "fisheye"
function pfm.util.XMLTimelineExporter:__init(width, height, frameRate)
	self.m_width = width
	self.m_height = height
	self.m_frameRate = frameRate

	self.m_formats = {}
	self.m_resources = {}
	self.resourceIds = {}
	self.m_nextResourceIndex = 0
	self.m_frameSequences = {}
	self.m_audioClips = {}

	self:InitializeFormat()
end
function pfm.util.XMLTimelineExporter:InitializeFormat()
	table.insert(self.m_formats, {
		_attr = {
			["id"] = "img_format",
			["name"] = "FFVideoFormatRateUndefined",
			["width"] = self.m_width,
			["height"] = self.m_height,
		},
	})
end
function pfm.util.XMLTimelineExporter:SetProjectionType(projectionType)
	self.m_projectionType = projectionType
end
function pfm.util.XMLTimelineExporter:GetProjectionType()
	return self.m_projectionType
end
function pfm.util.XMLTimelineExporter:SetStereoscopic(stereo)
	self.m_stereoscopic = stereo
end
function pfm.util.XMLTimelineExporter:IsStereoscopic()
	return self.m_stereoscopic or false
end
function pfm.util.XMLTimelineExporter:AddResource(type, filePath, durationMs)
	if self.resourceIds[filePath] ~= nil then
		return self.resourceIds[filePath]
	end
	local index = self.m_nextResourceIndex
	self.m_nextResourceIndex = self.m_nextResourceIndex + 1
	local id = type .. "_res" .. index
	self.resourceIds[filePath] = id
	local attrs = {
		["id"] = id,
		["src"] = filePath,
		["start"] = "0s",
	}
	if type == "video" then
		attrs["format"] = "r2"
		attrs["hasVideo"] = "1"
		attrs["name"] = "frame" .. index
		attrs["duration"] = "0s"

		local projectionType = self:GetProjectionType()
		if projectionType ~= nil then
			attrs["projectionOverride"] = projectionType

			if projectionType == pfm.util.XMLTimelineExporter.PROJECTION_TYPE_EQUIRECTANGULAR then
				attrs["stereoscopicOverride"] = self:IsStereoscopic() and "over under" or "mono"
			end
		end
	else
		attrs["hasAudio"] = "1"
		attrs["name"] = "audio" .. index
		attrs["duration"] = self:GetTimeAttr(durationMs)
	end
	self.m_resources["asset"] = self.m_resources["asset"] or {}
	table.insert(self.m_resources["asset"], {
		_attr = attrs,
	})
	return id
end
function pfm.util.XMLTimelineExporter:AddImageResource(imgPath)
	return self:AddResource("video", imgPath)
end
function pfm.util.XMLTimelineExporter:AddAudioResource(filePath, durationMs)
	return self:AddResource("audio", filePath, durationMs)
end
function pfm.util.XMLTimelineExporter:GetFrameTimeMs()
	return math.round((1.0 / self.m_frameRate) * 1000)
end
function pfm.util.XMLTimelineExporter:GetTimeAttr(t)
	return t .. "/1000s"
end
function pfm.util.XMLTimelineExporter:AddFrameSequence(clipName, imgPaths, startTimeMs)
	local assetClips = {}
	local offset = 0
	local duration = self:GetFrameTimeMs()
	local seqIdx = #self.m_frameSequences
	for i, imgPath in ipairs(imgPaths) do
		local resId = self:AddImageResource(imgPath)

		table.insert(assetClips, {
			_attr = {
				name = clipName .. "_s" .. seqIdx .. "f" .. i,
				offset = self:GetTimeAttr(offset),
				ref = resId,
				duration = self:GetTimeAttr(duration),
			},
		})
		offset = offset + duration
	end

	local id = "seq_res_" .. seqIdx
	self.m_resources["media"] = self.m_resources["media"] or {}
	table.insert(self.m_resources["media"], {
		_attr = {
			id = id,
			name = "seq" .. seqIdx,
		},
		sequence = {
			{
				spine = {
					{
						["asset-clip"] = assetClips,
					},
				},
			},
		},
	})
	table.insert(self.m_frameSequences, {
		clipName = clipName,
		resourceId = id,
		startTimeMs = math.round(startTimeMs),
		durationMs = duration * #imgPaths,
	})
end
function pfm.util.XMLTimelineExporter:AddAudio(filePath, startTimeMs, durationMs, soundFileDurationMs)
	local resId = self:AddAudioResource(filePath, soundFileDurationMs)
	table.insert(self.m_audioClips, {
		resourceId = resId,
		startTimeMs = startTimeMs,
		durationMs = durationMs,
	})
end
function pfm.util.XMLTimelineExporter:GenerateXML()
	local trefClips = {}
	for i, sequence in ipairs(self.m_frameSequences) do
		table.insert(trefClips, {
			_attr = {
				ref = sequence.resourceId,
				duration = self:GetTimeAttr(sequence.durationMs),
				name = sequence.clipName .. "_s" .. i,
				offset = self:GetTimeAttr(sequence.startTimeMs),
			},
		})
	end
	if #trefClips == 0 then
		trefClips = nil
	end

	local taudioClips = {}
	for i, frame in ipairs(self.m_audioClips) do
		table.insert(taudioClips, {
			_attr = {
				name = "audio" .. i,
				offset = self:GetTimeAttr(frame.startTimeMs),
				ref = frame.resourceId,
				duration = self:GetTimeAttr(frame.durationMs),
				start = "0s",
			},
		})
	end
	if #taudioClips == 0 then
		taudioClips = nil
	end

	self.m_resources["format"] = self.m_formats
	local txml = {}
	txml = {
		fcpxml = {
			{
				_attr = { version = "1.6" },
				resources = {
					{
						self.m_resources,
					},
				},
				library = {
					event = {
						{
							_attr = { name = "Storyboarder" },
							project = {
								{
									_attr = { name = "PFM Project" },
									sequence = {
										{
											_attr = { format = "img_format", renderColorSpace = "Rec. 709" },
											spine = {
												{
													["ref-clip"] = trefClips,
													["asset-clip"] = taudioClips,
												},
											},
										},
									},
								},
							},
						},
					},
				},
			},
		},
	}
	return xml2lua.toXml(txml, "fcpxml")
end
