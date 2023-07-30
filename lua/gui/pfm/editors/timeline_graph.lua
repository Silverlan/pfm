--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/curve.lua")
include("/gui/pfm/treeview.lua")
include("/gui/pfm/grid.lua")
include("/gui/pfm/selection.lua")
include("/gui/pfm/cursor_tracker.lua")
include("/gui/selectionrect.lua")
include("/gui/timelinestrip.lua")
include("/graph_axis.lua")
include("graph_editor")
include("key.lua")
include("easing.lua")

-- Quaternions are represented as euler angles in the interface and have to be
-- converted accordingly
local function channel_value_to_editor_value(val, channelValueType)
	if channelValueType ~= udm.TYPE_QUATERNION then
		return val
	end
	return val:ToEulerAngles()
end
local function channel_value_type_to_editor_value_type(channelValueType)
	if channelValueType ~= udm.TYPE_QUATERNION then
		return udm.TYPE_EULER_ANGLES
	end
	return channelValueType
end
local function editor_value_to_channel_value(val, channelValueType)
	if channelValueType ~= udm.TYPE_QUATERNION then
		return val
	end
	return val:ToQuaternion()
end

----------------

util.register_class("gui.PFMTimelineGraph", gui.Base)

gui.PFMTimelineGraph.CURSOR_MODE_SELECT = 0
gui.PFMTimelineGraph.CURSOR_MODE_MOVE = 1
gui.PFMTimelineGraph.CURSOR_MODE_PAN = 2
gui.PFMTimelineGraph.CURSOR_MODE_SCALE = 3
gui.PFMTimelineGraph.CURSOR_MODE_ZOOM = 4
function gui.PFMTimelineGraph:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512, 256)
	self.m_bg = gui.create("WIRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_bg:SetColor(Color(128, 128, 128))

	self.m_grid = gui.create("WIGrid", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	local session = tool.get_filmmaker():GetSession()
	local settings = session:GetSettings()
	local renderSettings = settings:GetRenderSettings()

	local function updateTimeLayer()
		local frameRate = renderSettings:GetFrameRate()
		if frameRate <= 0 then
			frameRate = 24
		end
		self.m_grid:GetTimeLayer():SetStepSize(1.0 / frameRate)
		self.m_grid:Update()
	end
	self.m_cbUpdateFrameRate = renderSettings:AddChangeListener("frameRate", updateTimeLayer)
	updateTimeLayer()

	self.m_graphContainer = gui.create("WIBase", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)

	local listContainer = gui.create("WIRect", self, 0, 0, 204, self:GetHeight(), 0, 0, 0, 1)
	listContainer:SetColor(Color(38, 38, 38))
	self.m_listContainer = listContainer

	self.m_scrollContainer = gui.create(
		"WIScrollContainer",
		listContainer,
		0,
		0,
		listContainer:GetWidth(),
		listContainer:GetHeight(),
		0,
		0,
		1,
		1
	)

	self.m_transformList = gui.create(
		"WIPFMTreeView",
		self.m_scrollContainer,
		0,
		0,
		self.m_scrollContainer:GetWidth(),
		self.m_scrollContainer:GetHeight()
	)
	self.m_transformList:SetName("properties")
	self.m_transformList:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)

	local dataAxisStrip =
		gui.create("WILabelledTimelineStrip", self, listContainer:GetRight(), 0, 30, self:GetHeight(), 0, 0, 0, 1)
	dataAxisStrip:SetHorizontal(false)
	dataAxisStrip:SetDataAxisInverted(true)
	-- dataAxisStrip:AddDebugMarkers()
	-- dataAxisStrip:SetFlipped(true)
	self.m_dataAxisStrip = dataAxisStrip

	self.m_keys = {}

	self.m_graphs = {}
	self.m_channelPathToGraphIndices = {}
	self.m_timeAxis = util.GraphAxis()
	self.m_dataAxis = util.GraphAxis()

	dataAxisStrip:SetAxis(self.m_dataAxis)
	self.m_grid:SetXAxis(self.m_timeAxis)
	self.m_grid:SetYAxis(self.m_dataAxis)

	self:SetCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SELECT)
	self:SetKeyboardInputEnabled(true)
	self:SetMouseInputEnabled(true)
	self:SetScrollInputEnabled(true)
	-- gui.set_mouse_selection_enabled(self,true)

	local animManager = pfm.get_project_manager():GetAnimationManager()
	self.m_cbOnChannelValueChanged = animManager:AddCallback("OnChannelValueChanged", function(data)
		if self.m_skipOnChannelValueChangedCallback == true then
			return
		end
		self:UpdateChannelValue(data)
	end)
	self.m_cbOnKeyframeUpdated = animManager:AddCallback("OnKeyframeUpdated", function(data)
		if self.m_skipOnChannelValueChangedCallback == true then
			return
		end
		self:UpdateChannelValue(data)
	end)
end
local function get_editor_channel_keyframe_time_boundaries(editorChannel, startTime, endTime)
	startTime = startTime or math.huge
	endTime = endTime or -math.huge
	local editorGraphCurve = editorChannel:GetGraphCurve()
	local numKeys = editorGraphCurve:GetKeyCount()
	local startTimeBoundary = startTime
	local endTimeBoundary = endTime
	for i = 0, numKeys - 1 do
		local pathKeys = editorGraphCurve:GetKey(i)

		local keyIndexStart = editorChannel:FindLowerKeyIndex(startTime, i) or 0
		local t = pathKeys:GetTime(keyIndexStart)
		if t ~= nil then
			startTimeBoundary = math.min(startTimeBoundary, t)
		end

		-- TODO: Make FindLowerKeyIndex return 0 on lower bounds?
		local keyIndexEnd = (editorChannel:FindLowerKeyIndex(endTime, i) or 0) + 1
		t = pathKeys:GetTime(keyIndexEnd)
		if t ~= nil then
			endTimeBoundary = math.max(endTimeBoundary, t)
		end
	end
	if startTimeBoundary == math.huge or endTimeBoundary == math.huge then
		return
	end
	return startTimeBoundary, endTimeBoundary
end
function gui.PFMTimelineGraph:ReloadGraphCurveSegment(i, keyIndex, rebuildCurve)
	if rebuildCurve == nil then
		rebuildCurve = true
	end
	local graphData = self.m_graphs[i]

	--[[local function updateSegment(keyIndex)
		local dp0 = graphData.curve.m_dataPoints[keyIndex +1]
		local dp1 = graphData.curve.m_dataPoints[keyIndex +2]
		if(dp0 == nil or dp1 == nil) then return end
		self.m_skipUpdateChannelValue = true
		self:InitializeCurveDataValues(dp0,dp1)
		self.m_skipUpdateChannelValue = nil
	end
	updateSegment(keyIndex -1)
	updateSegment(keyIndex)]]

	local dpStart = graphData.curve.m_dataPoints[keyIndex] or graphData.curve.m_dataPoints[keyIndex + 1]
	local dpEnd = graphData.curve.m_dataPoints[keyIndex + 2] or graphData.curve.m_dataPoints[keyIndex + 1]
	if dpStart ~= nil and dpEnd ~= nil then
		local editorKeys = dpStart:GetEditorKeys()

		local actor0, targetPath0, keyIndex0, curveData0 = dpStart:GetChannelValueData()
		local startTime = editorKeys:GetTime(dpStart:GetKeyIndex())
		local endTime = editorKeys:GetTime(dpEnd:GetKeyIndex())

		local curve = graphData.curve
		local editorChannel = curve:GetEditorChannel()

		local editorGraphCurve = editorChannel:GetGraphCurve()
		local numKeys = editorGraphCurve:GetKeyCount()
		local startTimeBoundary, endTimeBoundary =
			get_editor_channel_keyframe_time_boundaries(editorChannel, startTime, endTime)

		self:InitializeCurveSegmentAnimationData(actor0, targetPath0, graphData, startTimeBoundary, endTimeBoundary)
	end

	if rebuildCurve then
		self:RebuildGraphCurve(i, graphData, true)
	end
end
function gui.PFMTimelineGraph:UpdateChannelValue(data)
	if self.m_skipUpdateChannelValue then
		return
	end
	local udmChannel = data.udmChannel
	local graphData, graphIdx = self:FindGraphData(data.actor, udmChannel:GetTargetPath(), data.typeComponentIndex)
	if graphData == nil then
		return
	end
	local rebuildGraphCurves = false
	if graphData.curve:IsValid() then
		local editorKeys = graphData.curve:GetEditorKeys()
		if editorKeys == nil or graphData.numValues ~= editorKeys:GetTimeCount() then
			-- Number of keyframe keys has changed, we'll have to rebuild the entire curve
			self:RebuildGraphCurve(graphIdx, graphData)
		elseif data.fullUpdateRequired then
			rebuildGraphCurves = true
		elseif data.keyIndex ~= nil then
			-- We only have to rebuild the two curve segments connected to the key
			self:ReloadGraphCurveSegment(graphIdx, data.keyIndex)
			rebuildGraphCurves = true

			-- Also update key data point position
			if data.oldKeyIndex ~= nil then
				self:ReloadGraphCurveSegment(graphIdx, data.oldKeyIndex)
				rebuildGraphCurves = true
				graphData.curve:SwapDataPoints(data.oldKeyIndex, data.keyIndex)
				graphData.curve:UpdateDataPoints()
			else
				graphData.curve:UpdateDataPoint(data.keyIndex + 1)
			end
		elseif data.oldKeyIndex ~= nil then
			-- Key was deleted; Perform full update
			-- TODO: If multiple keys are deleted at once, only do this once instead of for every single key
			self:RebuildGraphCurve(graphIdx, graphData)
		end
	end
	if rebuildGraphCurves then
		local indices = self:FindGraphDataIndices(data.actor, udmChannel:GetTargetPath(), data.typeComponentIndex)
		for _, graphIdx in ipairs(indices) do
			self:RebuildGraphCurve(graphIdx, self.m_graphs[graphIdx], true)
		end
	end
end
function gui.PFMTimelineGraph:GetTimeAxisExtents()
	return self:GetWidth()
end
function gui.PFMTimelineGraph:GetDataAxisExtents()
	return self.m_dataAxisStrip:GetHeight()
end
function gui.PFMTimelineGraph:OnRemove()
	util.remove(self.m_cbUpdateFrameRate)
	util.remove(self.m_cbOnChannelValueChanged)
	util.remove(self.m_cbOnKeyframeUpdated)
	util.remove(self.m_cbDataAxisPropertiesChanged)
end
function gui.PFMTimelineGraph:FindGraphDataIndices(actor, targetPath)
	local uuid = tostring(actor:GetUniqueId())
	if self.m_channelPathToGraphIndices[uuid] == nil then
		return {}
	end
	return self.m_channelPathToGraphIndices[uuid][targetPath] or {}
end
function gui.PFMTimelineGraph:FindGraphData(actor, targetPath, typeComponentIndex)
	local indices = self:FindGraphDataIndices(actor, targetPath)
	for _, graphIdx in ipairs(indices) do
		if self.m_graphs[graphIdx].typeComponentIndex == typeComponentIndex then
			return self.m_graphs[graphIdx], graphIdx
		end
	end
end
function gui.PFMTimelineGraph:RemoveKeyframe(actor, targetPath, typeComponentIndex, keyIndex)
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()

	local graphData = self:FindGraphData(actor, targetPath, typeComponentIndex)
	if graphData == nil then
		return
	end
	local curve = graphData.curve
	local graphIdx = curve:GetCurveIndex()

	local editorChannel = curve:GetEditorChannel()
	local editorGraphCurve = editorChannel:GetGraphCurve()
	local pathKeys = editorGraphCurve:GetKey(typeComponentIndex)
	local panimaChannel = curve:GetPanimaChannel()

	self.m_skipOnChannelValueChangedCallback = true
	local t = pathKeys:GetTime(keyIndex)
	if t == nil then
		return
	end
	animManager:RemoveKeyframe(actor, targetPath, keyIndex, typeComponentIndex)
	self:RebuildGraphCurve(graphIdx, self.m_graphs[graphIdx])

	local startTime, endTime = get_editor_channel_keyframe_time_boundaries(editorChannel)
	if startTime ~= nil then
		if t + pfm.udm.EditorChannelData.TIME_EPSILON < startTime then
			-- The keyframe was the first keyframe in the animation. We have to remove all animation data in the range [keyframeTime,startTime)
			local idxStart, idxEnd = panimaChannel:FindIndexRangeInTimeRange(
				t - pfm.udm.EditorChannelData.TIME_EPSILON,
				startTime - pfm.udm.EditorChannelData.TIME_EPSILON
			)
			if idxStart ~= nil then
				panimaChannel:RemoveValueRange(idxStart, (idxEnd - idxStart) + 1)
			end
		end

		if t - pfm.udm.EditorChannelData.TIME_EPSILON > endTime then
			-- The keyframe was the last keyframe in the animation. We have to remove all animation data in the range (endTime,keyframeTime]
			local idxStart, idxEnd = panimaChannel:FindIndexRangeInTimeRange(
				endTime + pfm.udm.EditorChannelData.TIME_EPSILON,
				t + pfm.udm.EditorChannelData.TIME_EPSILON
			)
			if idxStart ~= nil then
				panimaChannel:RemoveValueRange(idxStart, (idxEnd - idxStart) + 1)
			end
		end
	end
	local valueIdx = panimaChannel:FindIndex(t)
	if valueIdx ~= nil then
		panimaChannel:RemoveValueRange(valueIdx, 1)
	end

	self:ReloadGraphCurveSegment(graphIdx, (keyIndex > 0) and (keyIndex - 1) or 0)
	self.m_skipOnChannelValueChangedCallback = nil
end
function gui.PFMTimelineGraph:RemoveDataPoint(dp)
	local actor, targetPath, keyIndex, curveData = dp:GetChannelValueData()
	self:RemoveKeyframe(actor, targetPath, dp:GetTypeComponentIndex(), keyIndex)
end
function gui.PFMTimelineGraph:KeyboardCallback(key, scanCode, state, mods)
	if key == input.KEY_DELETE then
		if state == input.STATE_PRESS then
			local dps = self:GetSelectedDataPoints(false, true)
			-- Need to delete in reverse order (with highest index first), otherwise the value indices could change while we're deleting
			table.sort(dps, function(a, b)
				return a:GetKeyIndex() > b:GetKeyIndex()
			end)
			for _, dp in ipairs(dps) do
				self:RemoveDataPoint(dp)
			end
		end
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_1 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_2 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_3 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_4 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_5 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_6 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_7 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	elseif key == input.KEY_8 then
		print("Not yet implemented!")
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMTimelineGraph:GetSelectedDataPoints(includeHandles, includePointsIfHandleSelected)
	if includeHandles == nil then
		includeHandles = true
	end
	includePointsIfHandleSelected = includePointsIfHandleSelected or false
	local dps = {}
	for _, graphData in ipairs(self.m_graphs) do
		if graphData.curve:IsValid() then
			local cdps = graphData.curve:GetDataPoints()
			for _, dp in ipairs(cdps) do
				if dp:IsValid() then
					if dp:IsSelected() or (includePointsIfHandleSelected and dp:IsHandleSelected()) then
						table.insert(dps, dp)
					end
					local tc = dp:GetTangentControl()
					if util.is_valid(tc) and includeHandles == true then
						local inC = tc:GetInControl()
						if inC:IsSelected() then
							table.insert(dps, inC)
						end

						local outC = tc:GetOutControl()
						if outC:IsSelected() then
							table.insert(dps, outC)
						end
					end
				end
			end
		end
	end
	return dps
end
function gui.PFMTimelineGraph:UpdateSelectedDataPointHandles()
	local dps = self:GetSelectedDataPoints(false, true)
	for _, dp in ipairs(dps) do
		dp:UpdateHandles()
	end
end
function gui.PFMTimelineGraph:SetCursorTrackerEnabled(enabled)
	if enabled then
		local timeAxis = self.m_timeline:GetTimeline():GetTimeAxis():GetAxis()
		local dataAxis = self.m_timeline:GetTimeline():GetDataAxis():GetAxis()
		self.m_cursorTracker = {
			tracker = gui.CursorTracker(),
			timeAxisStartOffset = timeAxis:GetStartOffset(),
			timeAxisZoomLevel = timeAxis:GetZoomLevel(),
			dataAxisStartOffset = dataAxis:GetStartOffset(),
			dataAxisZoomLevel = dataAxis:GetZoomLevel(),
		}
		self:EnableThinking()
	else
		self.m_cursorTracker = nil
		self:DisableThinking()
	end
end
function gui.PFMTimelineGraph:MouseCallback(button, state, mods)
	self:RequestFocus()

	local isCtrlDown = input.is_ctrl_key_down()
	local isAltDown = input.is_alt_key_down()
	local cursorMode = self:GetCursorMode()
	if button == input.MOUSE_BUTTON_LEFT then
		if cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_MOVE then
			local moveEnabled = (state == input.STATE_PRESS)
			for _, dp in ipairs(self:GetSelectedDataPoints()) do
				dp:SetMoveModeEnabled(moveEnabled)
			end
		elseif state == input.STATE_PRESS then
			self:SetCursorTrackerEnabled(true)
			if cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT then
				if util.is_valid(self.m_selectionRect) == false then
					self.m_selectionRect = gui.create("WISelectionRect", self.m_graphContainer)
					self.m_selectionRect:SetPos(self.m_graphContainer:GetCursorPos())
				end
			elseif cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_ZOOM then
				gui.set_cursor_input_mode(gui.CURSOR_MODE_HIDDEN)
			end
		else
			if cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT then
				if util.is_valid(self.m_selectionRect) then
					for _, graphData in ipairs(self.m_graphs) do
						if graphData.curve:IsValid() then
							local dps = graphData.curve:GetDataPoints()
							for _, dp in ipairs(dps) do
								if
									dp:UpdateSelection(self.m_selectionRect) == false
									and isCtrlDown == false
									and isAltDown == false
								then
									dp:SetSelected(false)
								end
							end
						end
					end
					-- TODO: Select or deselect all points on curve if no individual points are within the select bounds, but the curve is
				end
			elseif cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_ZOOM then
				gui.set_cursor_input_mode(gui.CURSOR_MODE_NORMAL)
			end

			self:SetCursorTrackerEnabled(false)
			util.remove(self.m_selectionRect)
		end
		return util.EVENT_REPLY_HANDLED
	elseif button == input.MOUSE_BUTTON_RIGHT then
		if self.m_rightClickZoom and state == input.STATE_RELEASE then
			self.m_rightClickZoom = false
			self:SetCursorTrackerEnabled(self.m_rightClickZoom)
			return util.EVENT_REPLY_HANDLED
		end
		local isCtrlDown = input.is_ctrl_key_down()
		local isAltDown = input.is_alt_key_down()
		if isCtrlDown then
			self.m_rightClickZoom = (state == input.STATE_PRESS)
			self:SetCursorTrackerEnabled(self.m_rightClickZoom)
			return util.EVENT_REPLY_HANDLED
		elseif isAltDown then
			print("Not yet implemented!")
		elseif state == input.STATE_PRESS then
			local pContext = gui.open_context_menu()
			if util.is_valid(pContext) == false then
				return
			end
			pContext:SetPos(input.get_cursor_pos())

			local schema = pfm.udm.get_schema()

			local function get_enum_set(name)
				local enums = schema:GetEnumSet(name)
				local indexToName = {}
				for k, v in pairs(enums) do
					local name = k
					local normName = ""
					for i = 1, #name do
						if name:sub(i, i) == name:sub(i, i):upper() then
							normName = normName .. "_" .. name:sub(i, i):lower()
						else
							normName = normName .. name:sub(i, i)
						end
					end
					indexToName[v + 1] = normName
				end
				return indexToName
			end

			pContext
				:AddItem(locale.get_text("pfm_fit_view_to_data"), function()
					if self:IsValid() then
						self:FitViewToDataRange()
					end
				end)
				:SetName("fit_view_to_data")

			local pm = tool.get_filmmaker()
			if pm:IsDeveloperModeEnabled() then
				pContext
					:AddItem("Copy graph editor channel data to clipboard", function()
						if self:IsValid() then
							for _, graphData in ipairs(self.m_graphs) do
								local curve = graphData.curve
								local editorChannel = curve:GetEditorChannel()
								util.set_clipboard_string(editorChannel:GetUdmData():ToAscii())
							end
						end
					end)
					:SetName("copy_editor_channel_data")

				pContext
					:AddItem("Copy panima channel data to clipboard", function()
						if self:IsValid() then
							for _, graphData in ipairs(self.m_graphs) do
								local curve = graphData.curve
								local panimaChannel = curve:GetPanimaChannel()

								local udmData, err = udm.create("PANIMAC", 1)
								if udmData == false then
									return false
								end

								local assetData = udmData:GetAssetData():GetData()
								panimaChannel:Save(assetData)

								util.set_clipboard_string(udmData:GetAssetData():ToAscii())
							end
						end
					end)
					:SetName("copy_panima_channel_data")
			end

			local pItem, pSubMenuInterp = pContext:AddSubMenu(locale.get_text("pfm_graph_editor_interpolation"))
			pItem:SetName("interpolation")
			local esInterpolation = get_enum_set("Interpolation")
			for val, name in ipairs(esInterpolation) do
				val = val - 1
				pSubMenuInterp:AddItem(locale.get_text("pfm_graph_editor_interpolation_" .. name), function()
					local timeline = self:GetTimeline()
					timeline:SetInterpolationMode(val)
				end)
			end
			pSubMenuInterp:Update()

			local pItem, pSubMenuInterp = pContext:AddSubMenu(locale.get_text("pfm_graph_editor_easing_mode"))
			pItem:SetName("easing_mode")
			local esEasing = get_enum_set("EasingMode")
			for val, name in ipairs(esEasing) do
				val = val - 1
				pSubMenuInterp:AddItem(locale.get_text("pfm_graph_editor_easing_mode_" .. name), function()
					local timeline = self:GetTimeline()
					timeline:SetEasingMode(val)
				end)
			end

			pSubMenuInterp
				:AddItem(locale.get_text("pfm_overview"), function()
					if self:IsValid() then
						local pm = tool.get_filmmaker()
						local webBrowser = pm:OpenWindow(pfm.WINDOW_WEB_BROWSER)
						pm:GoToWindow(pfm.WINDOW_WEB_BROWSER)
						if util.is_valid(webBrowser) then
							webBrowser:GetBrowser():SetUrl("https://easings.net/")
						end
					end
				end)
				:SetName("overview")

			pSubMenuInterp:Update()

			local pItem, pSubMenuHandleMode = pContext:AddSubMenu(locale.get_text("pfm_graph_editor_handle_type"))
			pItem:SetName("handle_type")
			local esHandleMode = get_enum_set("KeyframeHandleType")
			for val, name in ipairs(esHandleMode) do
				val = val - 1
				pSubMenuHandleMode
					:AddItem(locale.get_text("pfm_graph_editor_handle_type_" .. name), function()
						local timeline = self:GetTimeline()
						timeline:SetHandleType(val)
					end)
					:SetName(name)
			end
			pSubMenuHandleMode:Update()

			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	elseif button == input.MOUSE_BUTTON_MIDDLE then
		self.m_middleMouseDrag = (state == input.STATE_PRESS)
		self:SetCursorTrackerEnabled(self.m_middleMouseDrag)
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMTimelineGraph:ZoomAxes(am, updateDataAxis, updateTimeAxis, useCenterAsPivot, cursorPos)
	useCenterAsPivot = useCenterAsPivot or false
	local timeLine = self.m_timeline:GetTimeline()
	local dataAxis = timeLine:GetDataAxis():GetAxis()
	local timeAxis = timeLine:GetTimeAxis():GetAxis()
	local useCenterAsPivot = (isAltDown == false)

	cursorPos = cursorPos or input.get_cursor_pos()
	local pm = pfm.get_project_manager()
	if updateDataAxis then
		local elRef = self.m_dataAxisStrip
		local relCursorPos = cursorPos - elRef:GetAbsolutePos()

		local pivot
		if useCenterAsPivot == false then
			pivot = dataAxis:GetStartOffset()
				+ dataAxis:XDeltaToValue(elRef:GetHeight())
				- dataAxis:XDeltaToValue(relCursorPos.y)
		else
			pivot = dataAxis:GetStartOffset() + dataAxis:XDeltaToValue(elRef:GetHeight() / 2.0)
		end
		dataAxis:SetZoomLevel(dataAxis:GetZoomLevel() - (am / 20.0), pivot)
		timeLine:Update()
	end
	if updateTimeAxis then
		local elRef = self.m_timeline
		local relCursorPos = cursorPos - elRef:GetAbsolutePos()

		local pivot
		if useCenterAsPivot == false then
			pivot = timeAxis:GetStartOffset() + timeAxis:XDeltaToValue(relCursorPos.x)
		else
			pivot = timeAxis:GetStartOffset() + timeAxis:XDeltaToValue(elRef:GetWidth() / 2.0)
		end

		timeAxis:SetZoomLevel(timeAxis:GetZoomLevel() - (am / 20.0), pivot)
		timeLine:Update()
	end

	self:UpdateAxisRanges(
		timeAxis:GetStartOffset(),
		timeAxis:GetZoomLevel(),
		dataAxis:GetStartOffset(),
		dataAxis:GetZoomLevel()
	)
end
function gui.PFMTimelineGraph:OnThink()
	if self.m_cursorTracker == nil then
		return
	end
	local trackerData = self.m_cursorTracker
	local tracker = trackerData.tracker
	local dt = tracker:Update()
	if dt.x == 0 and dt.y == 0 then
		return
	end

	local dtPos = tracker:GetTotalDeltaPosition()
	local timeLine = self.m_timeline:GetTimeline()

	local cursorMode = self:GetCursorMode()
	if self.m_middleMouseDrag or cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_PAN then
		timeLine
			:GetTimeAxis()
			:GetAxis()
			:SetStartOffset(trackerData.timeAxisStartOffset - timeLine:GetTimeAxis():GetAxis():XDeltaToValue(dtPos).x)
		timeLine
			:GetDataAxis()
			:GetAxis()
			:SetStartOffset(trackerData.dataAxisStartOffset + timeLine:GetDataAxis():GetAxis():XDeltaToValue(dtPos).y)
		timeLine:Update()
	elseif self.m_rightClickZoom or cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_ZOOM then
		local dt = (dtPos.x + dtPos.y) / 20.0
		self:ZoomAxes(dt, true, true, true, tracker:GetStartPos())
		input.set_cursor_pos(tracker:GetStartPos())
		tracker:ResetCurPos()
	elseif cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT then
	elseif cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_MOVE then
	elseif cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SCALE then
	end
end
function gui.PFMTimelineGraph:ScrollCallback(x, y)
	local isCtrlDown = input.is_ctrl_key_down()
	local isAltDown = input.is_alt_key_down()
	local updateDataAxis = isCtrlDown or isAltDown
	local updateTimeAxis = isAltDown
	if updateDataAxis or updateTimeAxis then
		self:ZoomAxes(y, updateDataAxis, updateTimeAxis, isAltDown == false)
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMTimelineGraph:SetCursorMode(cursorMode)
	self.m_cursorMode = cursorMode
end
function gui.PFMTimelineGraph:GetCursorMode()
	return self.m_cursorMode
end
function gui.PFMTimelineGraph:SetTimeline(timeline)
	self.m_timeline = timeline
end
function gui.PFMTimelineGraph:GetTimeline()
	return self.m_timeline
end
function gui.PFMTimelineGraph:SetTimeAxis(timeAxis)
	self.m_timeAxis = timeAxis
end
function gui.PFMTimelineGraph:SetDataAxis(dataAxis)
	self.m_dataAxis = dataAxis
	self.m_dataAxisStrip:SetAxis(dataAxis:GetAxis())

	util.remove(self.m_cbDataAxisPropertiesChanged)
	self.m_cbDataAxisPropertiesChanged = dataAxis:GetAxis():AddCallback("OnPropertiesChanged", function()
		self.m_dataAxisStrip:Update()
	end)
end
function gui.PFMTimelineGraph:GetTimeAxis()
	return self.m_timeAxis
end
function gui.PFMTimelineGraph:GetDataAxis()
	return self.m_dataAxis
end
function gui.PFMTimelineGraph:UpdateGraphCurveAxisRanges(i)
	local graphData = self.m_graphs[i]
	local graph = graphData.curve
	if graph:IsValid() == false then
		return
	end
	local timeAxis = self:GetTimeAxis():GetAxis()
	local timeRange = { timeAxis:GetStartOffset(), timeAxis:XOffsetToValue(self:GetRight()) }
	graph:SetHorizontalRange(timeRange[1], timeRange[2])

	local dataAxis = self:GetDataAxis():GetAxis()
	local dataRange = { dataAxis:GetStartOffset(), dataAxis:XOffsetToValue(self:GetBottom()) }
	graph:SetVerticalRange(dataRange[1], dataRange[2])
end
function gui.PFMTimelineGraph:RebuildGraphCurves()
	for i = 1, #self.m_graphs do
		local graphData = self.m_graphs[i]
		if graphData.curve:IsValid() then
			self:RebuildGraphCurve(i, graphData)
		end
	end
end
function gui.PFMTimelineGraph:InterfaceTimeToDataTime(graphData, t)
	local animClip = graphData.animClip()
	if animClip == nil then
		return t
	end
	t = animClip:LocalizeOffset(t)
	t = graphData.filmClip:LocalizeOffset(t)
	return t
end
function gui.PFMTimelineGraph:DataTimeToInterfaceTime(graphData, t)
	local animClip = graphData.animClip()
	if animClip == nil then
		return t
	end
	t = animClip:GlobalizeOffset(t)
	t = graphData.filmClip:GlobalizeOffset(t)
	return t
end

local function calc_graph_curve_data_point_value(interpMethod, easingMode, pathKeys, keyIndex0, keyIndex1, time)
	assert(keyIndex1 == keyIndex0 + 1)

	local cp0Time = pathKeys:GetTime(keyIndex0)
	local cp0Val = pathKeys:GetValue(keyIndex0)

	local cp1Time = pathKeys:GetTime(keyIndex1)
	local cp1Val = pathKeys:GetValue(keyIndex1)

	local cp0OutTime = pathKeys:GetOutTime(keyIndex0)
	local cp0OutVal = pathKeys:GetOutDelta(keyIndex0)
	cp0OutTime = math.min(cp0Time + cp0OutTime, cp1Time - 0.0001)
	cp0OutVal = cp0Val + cp0OutVal

	local cp1InTime = pathKeys:GetInTime(keyIndex1)
	local cp1InVal = pathKeys:GetInDelta(keyIndex1)

	cp1InTime = math.max(cp1Time + cp1InTime, cp0Time + 0.0001)
	cp1InVal = cp1Val + cp1InVal

	local begin = cp0Val
	local change = cp1Val - cp0Val

	if interpMethod == pfm.udm.INTERPOLATION_CONSTANT then
		if time - cp1Time >= -pfm.udm.EditorChannelData.TIME_EPSILON then
			return cp1Val
		end
		return cp0Val
	end

	local normalizedTime = (time - cp0Time) / (cp1Time - cp0Time)
	if interpMethod == pfm.udm.INTERPOLATION_BEZIER then
		return math.calc_bezier_point(
			time,
			cp0Time,
			cp0Val,
			cp0OutTime,
			cp0OutVal,
			cp1InTime,
			cp1InVal,
			cp1Time,
			cp1Val
		)
	elseif interpMethod ~= pfm.udm.INTERPOLATION_LINEAR then
		local easingMethod = pfm.util.get_easing_method(interpMethod, easingMode)
		local duration = 1
		return easingMethod(normalizedTime, begin, change, duration)
	end

	-- Default: Linear interpolation
	return math.lerp(cp0Val, cp1Val, normalizedTime)
end

local function calc_graph_curve_data_points(interpMethod, easingMode, pathKeys, keyIndex0, keyIndex1)
	assert(keyIndex1 == keyIndex0 + 1)
	local timestamps = {}
	local dataValues = {}
	local t0 = pathKeys:GetTime(keyIndex0)
	local v0 = pathKeys:GetValue(keyIndex0)
	local t1 = pathKeys:GetTime(keyIndex1)
	local v1 = pathKeys:GetValue(keyIndex1)

	table.insert(timestamps, t0)
	table.insert(timestamps, t1)

	if interpMethod == pfm.udm.INTERPOLATION_CONSTANT then
		table.insert(timestamps, t1 - 0.001)
	elseif interpMethod == pfm.udm.INTERPOLATION_LINEAR then
		-- Linear interpolation is the default method; Do nothing
	else
		-- Spline interpolation
		local begin
		local duration = 1
		local change

		local calcPointOnCurve
		if interpMethod == pfm.udm.INTERPOLATION_BEZIER then
			calcPointOnCurve = function(
				t,
				normalizedTime,
				dt,
				cp0Time,
				cp0Val,
				cp0OutTime,
				cp0OutVal,
				cp1InTime,
				cp1InVal,
				cp1Time,
				cp1Val
			)
				return math.calc_bezier_point(
					t,
					cp0Time,
					cp0Val,
					cp0OutTime,
					cp0OutVal,
					cp1InTime,
					cp1InVal,
					cp1Time,
					cp1Val
				)
			end
		else
			local easingMethod = pfm.util.get_easing_method(interpMethod, easingMode)
			calcPointOnCurve = function(
				t,
				normalizedTime,
				dt,
				cp0Time,
				cp0Val,
				cp0OutTime,
				cp0OutVal,
				cp1InTime,
				cp1InVal,
				cp1Time,
				cp1Val
			)
				return easingMethod(normalizedTime, begin, change, duration)
			end
		end

		local cp0Time = pathKeys:GetTime(keyIndex0)
		local cp0Val = pathKeys:GetValue(keyIndex0)

		local cp1Time = pathKeys:GetTime(keyIndex1)
		local cp1Val = pathKeys:GetValue(keyIndex1)

		local cp0OutTime = pathKeys:GetOutTime(keyIndex0)
		local cp0OutVal = pathKeys:GetOutDelta(keyIndex0)
		cp0OutTime = math.min(cp0Time + cp0OutTime, cp1Time - 0.0001)
		cp0OutVal = cp0Val + cp0OutVal

		local cp1InTime = pathKeys:GetInTime(keyIndex1)
		local cp1InVal = pathKeys:GetInDelta(keyIndex1)

		cp1InTime = math.max(cp1Time + cp1InTime, cp0Time + 0.0001)
		cp1InVal = cp1Val + cp1InVal

		begin = cp0Val
		change = cp1Val - cp0Val

		local function denormalize_time(normalizedTime)
			return cp0Time + (cp1Time - cp0Time) * normalizedTime
		end
		local function calc_point(normalizedTime, dt)
			if normalizedTime == 0.0 then
				return Vector2(normalizedTime, cp0Val)
			elseif normalizedTime == 1.0 then
				return Vector2(normalizedTime, cp1Val)
			end
			local t = denormalize_time(normalizedTime)
			return Vector2(
				normalizedTime,
				calcPointOnCurve(
					t,
					normalizedTime,
					dt,
					cp0Time,
					cp0Val,
					cp0OutTime,
					cp0OutVal,
					cp1InTime,
					cp1InVal,
					cp1Time,
					cp1Val
				)
			)
		end

		--
		-- We want to take a bunch of data samples on the bezier curve
		-- to fill our animation channel with. The more samples we use, the more accurately it will match
		-- the path of the original curve, but at the cost of memory. To reduce the number of samples we need, we create
		-- a sparse distribution at straight curve segments, and a tight distribution at segments with steep angles.
		local minDevAngle = console.get_convar_float("pfm_animation_min_curve_sample_deviation_angle")
		local maxStepCount = console.get_convar_int("pfm_animation_max_curve_sample_count") -- Number of samples will never exceed this value
		local dt = 1.0 / (maxStepCount - 1)
		local timeValues = { calc_point(0.0, dt) }
		local startPoint = calc_point(0.0, dt)
		local endPoint = calc_point(1.0, dt)
		local prevPoint = startPoint
		local n = (endPoint - startPoint):GetNormal()
		local deviation = 0.0
		for i = 1, maxStepCount - 2 do
			local t = i * dt
			local point = calc_point(t, dt)
			local nToPoint = (point - prevPoint):GetNormal()
			local ang = math.deg(n:GetAngle(nToPoint))
			deviation = deviation + ang
			if deviation >= minDevAngle then -- Only create a sample for this point if it deviates from a straight line to the previous sample (i.e. if linear interpolation would be insufficient)
				table.insert(timeValues, point)
				n = nToPoint

				deviation = 0
			end

			prevPoint = point
		end

		for i, tv in ipairs(timeValues) do
			table.insert(timestamps, denormalize_time(tv.x))
		end
	end

	if #dataValues == 0 then
		for i = 1, #timestamps do
			dataValues[i] = calc_graph_curve_data_point_value(
				interpMethod,
				easingMode,
				pathKeys,
				keyIndex0,
				keyIndex1,
				timestamps[i]
			)
		end
	end
	return timestamps, dataValues
end

local function get_default_value(valueType)
	if udm.is_numeric_type(valueType) then
		return 0.0
	end
	return udm.get_class_type(valueType)()
end

local function set_value_component_value(value, valueType, typeComponentIndex, vc)
	if udm.is_numeric_type(valueType) then
		return vc
	end
	value:Set(typeComponentIndex, vc)
	return value
end

local function get_interpolation_mode(pathKeys, keyIndex, valueType)
	if valueType == udm.TYPE_BOOLEAN then
		return pfm.udm.INTERPOLATION_CONSTANT
	end
	return pathKeys:GetInterpolationMode(keyIndex)
end

local function calc_component_value_at_timestamp(editorChannel, t, typeComponentIndex, valueType)
	local editorGraphCurve = editorChannel:GetGraphCurve()
	local pathKeys = editorGraphCurve:GetKey(typeComponentIndex)
	if pathKeys == nil or pathKeys:GetTimeCount() == 0 then
		return
	end

	local keyIndex0 = editorChannel:FindLowerKeyIndex(t, typeComponentIndex)
	if keyIndex0 == nil then
		return pathKeys:GetValue(0)
	end

	local interpMethod = get_interpolation_mode(pathKeys, keyIndex0, valueType)
	local easingMode = pathKeys:GetEasingMode(typeComponentIndex)

	if keyIndex0 == pathKeys:GetTimeCount() - 1 then
		return pathKeys:GetValue(pathKeys:GetTimeCount() - 1)
	end
	local keyIndex1 = keyIndex0 + 1
	return calc_graph_curve_data_point_value(interpMethod, easingMode, pathKeys, keyIndex0, keyIndex1, t)
end
local function calc_value_at_timestamp(editorChannel, t, valueType)
	local v = channel_value_to_editor_value(get_default_value(valueType), valueType)
	local n = udm.get_numeric_component_count(channel_value_type_to_editor_value_type(valueType))
	for i = 0, n - 1 do
		local vc = calc_component_value_at_timestamp(editorChannel, t, i, valueType)
		if vc ~= nil then
			v = set_value_component_value(v, valueType, i, vc)
		end
	end
	return v
end

function gui.PFMTimelineGraph:InitializeCurveSegmentAnimationData(actor, targetPath, graphData, startTime, endTime)
	debug.start_profiling_task("pfm_animation_curve_update")
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()

	local curve = graphData.curve
	local editorChannel = curve:GetEditorChannel()
	if editorChannel == nil then
		debug.stop_profiling_task()
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()

	local animClip = curve:GetAnimationClip()
	local localStartTime = startTime
	local localEndTime = endTime

	local panimaChannel = curve:GetPanimaChannel()
	local anim, channel, animClip = animManager:FindAnimationChannel(actor, targetPath)

	local valueIndex0 = panimaChannel:FindIndex(localStartTime, pfm.udm.EditorChannelData.TIME_EPSILON)
	local valueIndex1 = panimaChannel:FindIndex(localEndTime, pfm.udm.EditorChannelData.TIME_EPSILON)
	local valueType = channel:GetValueType()
	local isQuatType = (valueType == udm.TYPE_QUATERNION) -- Some special considerations are required for quaternions
	if valueIndex0 == nil then
		-- Value doesn't matter and will get overwritten further below
		valueIndex0 = panimaChannel:AddValue(localStartTime, get_default_value(valueType))
	end
	if valueIndex1 == nil then
		-- Value doesn't matter and will get overwritten further below
		valueIndex1 = panimaChannel:AddValue(localEndTime, get_default_value(valueType))
	end

	if valueIndex0 == nil or valueIndex1 == nil then
		local key = (valueIndex0 == nil) and keyIndex0 or keyIndex1
		pfm.log(
			"Animation graph key "
				.. key
				.. " at timestamp "
				.. editorKeys:GetTime(key)
				.. " has no associated animation data value!",
			pfm.LOG_CATEGORY_PFM,
			pfm.LOG_SEVERITY_WARNING
		)
		-- return
	end

	-- Ensure that animation values at keyframe timestamps match the keyframe values
	--channel:SetValue(valueIndex0,keyframeValueToChannelValue(keyIndex0,valueIndex0))
	--channel:SetValue(valueIndex1,keyframeValueToChannelValue(keyIndex1,valueIndex1))
	--

	-- We have to delete all of the animation values for this curve segment, which may also
	-- affect other paths if this is a composite type (e.g. vec3).
	-- Each path may have its own set of timestamps for which we need to update the data, so
	-- we'll collect all of them.
	local numPaths = editorGraphCurve:GetKeyCount()
	local timestampData = {}
	local keyframesInTimeframePerKey = {}
	for i = 0, numPaths - 1 do
		local pathKeys = editorGraphCurve:GetKey(i)
		local idx = editorChannel:FindLowerKeyIndex(localStartTime, i)
		if idx == nil and pathKeys:GetTimeCount() > 0 then
			idx = 0
		end
		-- Collect timestamps for all keyframe sets that intersect our time range
		if idx ~= nil then
			local t0 = pathKeys:GetTime(idx)
			assert(t0 ~= nil)
			local t1 = pathKeys:GetTime(idx + 1)
			if t1 ~= nil then
				while t1 ~= nil do
					if t0 + pfm.udm.EditorChannelData.TIME_EPSILON >= localEndTime then
						break
					end
					if t1 > localStartTime and (t1 - localStartTime) > pfm.udm.EditorChannelData.TIME_EPSILON then
						-- Segment is in range
						keyframesInTimeframePerKey[i] = keyframesInTimeframePerKey[i] or {}
						table.insert(keyframesInTimeframePerKey[i], idx)

						local interpMethod = get_interpolation_mode(pathKeys, idx, valueType)
						local easingMode = pathKeys:GetEasingMode(idx)
						local segTimestamps, segDataValues =
							calc_graph_curve_data_points(interpMethod, easingMode, pathKeys, idx, idx + 1)
						for _, t in ipairs(segTimestamps) do
							if t - pfm.udm.EditorChannelData.TIME_EPSILON >= t1 then
								break
							end
							if
								t + pfm.udm.EditorChannelData.TIME_EPSILON >= localStartTime
								and t - pfm.udm.EditorChannelData.TIME_EPSILON <= localEndTime
							then
								table.insert(timestampData, t)
							end
						end
					end
					idx = idx + 1
					t0 = t1
					t1 = pathKeys:GetTime(idx + 1)
				end
			else
				keyframesInTimeframePerKey[i] = keyframesInTimeframePerKey[i] or {}
				table.insert(keyframesInTimeframePerKey[i], idx)
				table.insert(timestampData, t0)
			end
		end
	end

	-- Make sure our start and endpoints are included
	table.insert(timestampData, localStartTime)
	table.insert(timestampData, localEndTime)

	table.sort(timestampData)

	-- Merge duplicate timestamps
	local i = 1
	while i < #timestampData do
		local t0 = timestampData[i]
		local t1 = timestampData[i + 1]
		if math.abs(t1 - t0) <= pfm.udm.EditorChannelData.TIME_EPSILON then
			table.remove(timestampData, i + 1)
		else
			i = i + 1
		end
	end

	-- Create the space for all of the data values (this will also clear any previous values in this time range)
	local numValues = #timestampData

	local t = channel:GetTime(valueIndex0)
	while
		valueIndex0 > 0 and (math.abs(channel:GetTime(valueIndex0 - 1) - t) <= pfm.udm.EditorChannelData.TIME_EPSILON)
	do
		valueIndex0 = valueIndex0 - 1
	end
	while
		valueIndex1 < (channel:GetValueCount() - 1)
		and (math.abs(channel:GetTime(valueIndex1 + 1) - t) <= pfm.udm.EditorChannelData.TIME_EPSILON)
	do
		valueIndex1 = valueIndex1 + 1
	end

	local result, valueIndex1 =
		animManager:SetCurveRangeChannelValueCount(actor, targetPath, startTime, endTime, numValues, true)
	if result then
		-- Go through each timestamp and calculate actual time and data values
		local tmpVals = {}
		for i, td in ipairs(timestampData) do
			channel:SetTime(valueIndex0 + i - 1, td)
			local v = channel_value_to_editor_value(get_default_value(valueType), valueType)
			for typeComponentIndex, keyframeIndices in pairs(keyframesInTimeframePerKey) do
				local pathKeys = editorGraphCurve:GetKey(typeComponentIndex)
				local foundCurveInRange = false
				for _, keyIndex in ipairs(keyframeIndices) do
					local tEnd = pathKeys:GetTime(keyIndex + 1)
					if tEnd ~= nil then
						if
							td >= pathKeys:GetTime(keyIndex) - pfm.udm.EditorChannelData.TIME_EPSILON
							and td <= pathKeys:GetTime(keyIndex + 1) + pfm.udm.EditorChannelData.TIME_EPSILON
						then
							local interpMethod = get_interpolation_mode(pathKeys, keyIndex, valueType)
							local easingMode = pathKeys:GetEasingMode(keyIndex)
							v = set_value_component_value(
								v,
								valueType,
								typeComponentIndex,
								calc_graph_curve_data_point_value(
									interpMethod,
									easingMode,
									pathKeys,
									keyIndex,
									keyIndex + 1,
									td
								)
							)
							foundCurveInRange = true
							break
						end
						--else
						--	foundCurveInRange = false
						--	break
					end
				end
				if foundCurveInRange == false then
					-- No curve found, point has to be out of bounds of the curve, so we'll
					-- clamp the value to the value of the highest/lowest keyframe.
					local numKeyframes = pathKeys:GetTimeCount()
					if numKeyframes > 0 then
						if numKeyframes == 1 then
							v = set_value_component_value(v, valueType, typeComponentIndex, pathKeys:GetValue(0))
						else
							local lastKfTime = pathKeys:GetTime(pathKeys:GetTimeCount() - 1)
							if td >= lastKfTime - pfm.udm.EditorChannelData.TIME_EPSILON then
								v = set_value_component_value(
									v,
									valueType,
									typeComponentIndex,
									pathKeys:GetValue(numKeyframes - 1)
								)
							else
								v = set_value_component_value(v, valueType, typeComponentIndex, pathKeys:GetValue(0))
							end
						end
					end
				end
			end
			if isQuatType then
				tmpVals[valueIndex0 + i - 1] = v
			end
			channel:SetValue(valueIndex0 + i - 1, editor_value_to_channel_value(v, valueType))
		end

		local getChannelValue
		if isQuatType then
			getChannelValue = function(channel, j)
				local val = tmpVals[j]
				if val == nil then
					val = calc_value_at_timestamp(editorChannel, channel:GetTime(j), valueType)
					tmpVals[j] = val
				end
				return val
			end
		else
			getChannelValue = function(channel, j)
				return channel_value_to_editor_value(channel:GetValue(j), valueType)
			end
		end

		-- If either of the keyframes for this curve segment is the very first
		-- or final keyframe of the curve, we have to clamp all of the sample values beyond
		-- the boundary (up to the highest or lowest keyframe timestamp) to the value of the keyframe.

		-- Clamp postfix samples
		for i = 0, editorGraphCurve:GetKeyCount() - 1 do
			local pathKeys = editorGraphCurve:GetKey(i)
			local keyIndex = editorChannel:FindLowerKeyIndex(localEndTime, i)
			if keyIndex == nil and pathKeys:GetTimeCount() > 0 then
				keyIndex = 0
			end
			if keyIndex == pathKeys:GetTimeCount() - 1 then
				local valueIndex = panimaChannel:FindIndex(pathKeys:GetTime(keyIndex))
				if valueIndex ~= nil then
					local lastValue = udm.get_numeric_component(getChannelValue(channel, valueIndex), i)
					local n = channel:GetValueCount()
					for j = valueIndex + 1, n - 1 do
						local ct = channel:GetTime(j)
						if ct > localEndTime then
							break
						end
						local val = getChannelValue(channel, j)
						val = set_value_component_value(val, valueType, i, lastValue)
						channel:SetValue(j, editor_value_to_channel_value(val, valueType))
					end
				end
			end
		end

		-- Clamp prefix samples
		for i = 0, editorGraphCurve:GetKeyCount() - 1 do
			local pathKeys = editorGraphCurve:GetKey(i)
			local keyIndex = editorChannel:FindLowerKeyIndex(localStartTime, i)
			if keyIndex == nil and pathKeys:GetTimeCount() > 0 then
				keyIndex = 0
			end
			if keyIndex == 0 then
				local valueIndex = panimaChannel:FindIndex(pathKeys:GetTime(keyIndex))
				if valueIndex ~= nil then
					local firstValue = udm.get_numeric_component(getChannelValue(channel, valueIndex), i)
					for j = 0, valueIndex - 1 do
						local ct = channel:GetTime(j)
						if ct < localStartTime then
							break
						end
						local val = getChannelValue(channel, j)
						val = set_value_component_value(val, valueType, i, firstValue)
						channel:SetValue(j, editor_value_to_channel_value(val, valueType))
					end
				end
			end
		end
	end
	debug.stop_profiling_task()
end

local function calc_equivalence_euler_angles(ang)
	ang = ang:Copy()
	ang.p = math.rad(ang.p)
	ang.y = math.rad(ang.y)
	ang.r = math.rad(ang.r)

	ang.p = math.pi - ang.p
	ang.y = ang.y + math.pi
	ang.r = ang.r + math.pi

	ang.p = math.deg(ang.p)
	ang.y = math.deg(ang.y)
	ang.r = math.deg(ang.r)
	ang:Normalize()
	return ang
end

local function find_closest_equivalence_euler_angles(ang, angRef)
	ang = ang:Copy()
	ang:Normalize()
	if angRef ~= nil then
		angRef = angRef:Copy()
		angRef:Normalize()
	end
	local candidates = { ang }
	table.insert(candidates, calc_equivalence_euler_angles(ang))

	if angRef == nil then
		-- Pick the candidate with the lowest roll and/or pitch (if multiple candidates have the same roll).
		-- This is subjective, but should result with the candidate that is probably the desired one.
		local bestCandidates = {}
		local bestCandidateVal
		for i, c in ipairs(candidates) do
			local r = math.abs(c.r)
			if bestCandidateVal == nil or r <= bestCandidateVal then
				bestCandidateVal = r
				table.insert(bestCandidates, c)
			end
		end

		local bestCandidate
		bestCandidateVal = nil
		for i, c in ipairs(bestCandidates) do
			local p = math.abs(c.p)
			if bestCandidateVal == nil or p < bestCandidateVal then
				bestCandidateVal = p
				bestCandidate = i
			end
		end
		return bestCandidates[bestCandidate]
	end

	-- Find the candidate with the shortest path to the reference angles

	if math.abs(math.rad(angRef.p) - math.pi / 2.0) < 0.001 and math.abs(math.rad(ang.p) - math.pi / 2.0) < 0.001 then
		-- A third equivalence is possible: https://math.stackexchange.com/a/4356879/161967
		-- TODO: This case is untested
		local equi = ang:Copy()
		local diff = angRef.y - equi.y
		equi.y = angRef.y
		equi.r = equi.r - diff
		equi:Normalize()

		table.insert(candidates, equi)
	end

	local bestCandidate
	local bestCandidateDiff
	for i, c in ipairs(candidates) do
		local d = math.abs(math.get_angle_difference(c.p, angRef.p))
			+ math.abs(math.get_angle_difference(c.y, angRef.y))
			+ math.abs(math.get_angle_difference(c.r, angRef.r))
		if bestCandidateDiff == nil or d < bestCandidateDiff then
			bestCandidateDiff = d
			bestCandidate = i
		end
	end
	return candidates[bestCandidate]
end
function gui.PFMTimelineGraph:RebuildGraphCurve(i, graphData, updateCurveOnly)
	local animClip = graphData.animClip()
	local channel = graphData.channel()
	if animClip == nil or channel == nil then
		return
	end
	local times = channel:GetTimes()
	local values = channel:GetValues()

	local graphData = self.m_graphs[i]
	local curveValues = {}

	if graphData.editorChannel == nil then
		local targetPath = channel:GetTargetPath()
		local animClip = graphData.animClip()
		if animClip ~= nil then
			local editorData = animClip:GetEditorData()
			local channel = editorData:FindChannel(targetPath)
			graphData.editorChannel = channel
		end
	end

	-- Quaternions are not very user friendly, so when working with quaternions, we'll want to display them as euler angles in the interface instead.
	-- However, since euler angles are not unique and converting a quaternion to euler angles can have multiple results, we have to do some additional considerations
	-- to prevent unnatural rotation paths.
	local prevVal
	local minKeyframeTime
	local maxKeyframeTime
	if graphData.valueType == udm.TYPE_QUATERNION and #times > 0 and graphData.editorChannel ~= nil then
		prevVal = calc_value_at_timestamp(
			graphData.editorChannel,
			animClip:GlobalizeTimeOffset(times[1]),
			graphData.valueType
		)
		if prevVal ~= nil then
			prevVal = find_closest_equivalence_euler_angles(prevVal)
		else
			prevVal = channel_value_to_editor_value(get_default_value(valueType), valueType)
		end

		local editorGraphCurve = graphData.editorChannel:GetGraphCurve()
		local n = udm.get_numeric_component_count(channel_value_type_to_editor_value_type(graphData.valueType))
		for i = 0, n - 1 do
			local pathKeys = editorGraphCurve:GetKey(i)
			if pathKeys ~= nil and pathKeys:GetTimeCount() > 0 then
				local t0 = pathKeys:GetTime(0)
				local t1 = pathKeys:GetTime(pathKeys:GetTimeCount() - 1)

				if minKeyframeTime == nil then
					minKeyframeTime = t0
				else
					minKeyframeTime = math.min(minKeyframeTime, t0)
				end

				if maxKeyframeTime == nil then
					maxKeyframeTime = t1
				else
					maxKeyframeTime = math.max(maxKeyframeTime, t1)
				end
			end
		end
	end

	minKeyframeTime = (minKeyframeTime ~= nil) and self:DataTimeToInterfaceTime(graphData, minKeyframeTime) or nil
	maxKeyframeTime = (maxKeyframeTime ~= nil) and self:DataTimeToInterfaceTime(graphData, maxKeyframeTime) or nil
	for i = 1, #times do
		local t = self:DataTimeToInterfaceTime(graphData, times[i])
		local v = values[i]
		v = (graphData.valueTranslator ~= nil) and graphData.valueTranslator[1](v) or v
		v = channel_value_to_editor_value(v, graphData.valueType)
		if graphData.valueType == udm.TYPE_QUATERNION then
			-- If we're dealing with quaternion values:
			-- If the timestamp lies within two keyframes, we can calculate the correct euler angles directly.
			-- If the timestamp does *not* lie within two keyframes, we have to take the quaternion value and convert it to euler angles instead. This is not ideal,
			-- as the same quaternion orientation can be represented by multiple different euler angle configurations. In this case some assumptions have to be made
			-- about which euler angle configuration is the desired one. There is no objective solution and this may result in unexpected curve paths in some cases.
			if
				minKeyframeTime ~= nil
				and maxKeyframeTime ~= nil
				and t + pfm.udm.EditorChannelData.TIME_EPSILON >= minKeyframeTime
				and t - pfm.udm.EditorChannelData.TIME_EPSILON <= maxKeyframeTime
			then
				v = calc_value_at_timestamp(graphData.editorChannel, t, graphData.valueType)
			else
				v = find_closest_equivalence_euler_angles(v, prevVal)
			end
			prevVal = v
		end
		v = udm.get_numeric_component(v, graphData.typeComponentIndex)
		table.insert(curveValues, { t, v })
	end

	if updateCurveOnly then
		graphData.curve:UpdateCurveData(curveValues)
		return
	end

	self:InitializeBookmarks()
	graphData.curve:BuildCurve(curveValues, animClip, channel, i, graphData.editorChannel, graphData.typeComponentIndex)
	local editorKeys = graphData.curve:GetEditorKeys()
	graphData.numValues = (editorKeys ~= nil) and editorKeys:GetTimeCount() or 0
end
function gui.PFMTimelineGraph:InitializeBookmarks(graphData)
	if graphData == nil then
		for _, graphData in ipairs(self.m_graphs) do
			self:InitializeBookmarks(graphData)
		end
		return
	end
	local channel = graphData.channel()
	if channel == nil then
		return
	end
	local targetPath = channel:GetTargetPath()
	local animClip = graphData.animClip()
	if animClip ~= nil then
		local editorData = animClip:GetEditorData()
		local channel = editorData:FindChannel(targetPath)
		graphData.editorChannel = channel
		if channel ~= nil then
			local bms = channel:GetBookmarkSet()
			graphData.bookmarkSet = bms
			self.m_timeline:AddBookmarkSet(bms, animClip:GetTimeFrame())
		end
	end
end
function gui.PFMTimelineGraph:RemoveGraphCurve(i)
	local graphData = self.m_graphs[i]
	if graphData.bookmarkSet ~= nil then
		self.m_timeline:RemoveBookmarkSet(graphData.bookmarkSet)
	end
	util.remove(graphData.bookmarks)
	util.remove(graphData.curve)

	local graphIndices = self:FindGraphDataIndices(graphData.actor, graphData.targetPath, graphData.typeComponentIndex)
	for j, ci in ipairs(graphIndices) do
		if ci == i then
			table.remove(graphIndices, j)
			break
		end
	end
	if #graphIndices == 0 then
		local uuid = tostring(graphData.actor:GetUniqueId())
		local graphIndices = self.m_channelPathToGraphIndices[uuid]
		graphIndices[graphData.targetPath] = nil
		if table.is_empty(graphIndices) then
			self.m_channelPathToGraphIndices[uuid] = nil
		end
	end

	while #self.m_graphs > 0 and not util.is_valid(self.m_graphs[#self.m_graphs].curve) do
		table.remove(self.m_graphs, #self.m_graphs)
	end
end
function gui.PFMTimelineGraph:GetGraphCurve(i)
	return self.m_graphs[i]
end
function gui.PFMTimelineGraph:AddGraph(
	filmClip,
	track,
	actor,
	targetPath,
	colorCurve,
	fValueTranslator,
	valueType,
	typeComponentIndex
)
	if util.is_valid(self.m_graphContainer) == false then
		return
	end

	local graph = gui.create(
		"WIPFMTimelineCurve",
		self.m_graphContainer,
		0,
		0,
		self.m_graphContainer:GetWidth(),
		self.m_graphContainer:GetHeight(),
		0,
		0,
		1,
		1
	)
	graph:SetTimelineGraph(self)
	graph:SetColor(colorCurve)
	local animClip
	local function getAnimClip()
		animClip = animClip or track:FindActorAnimationClip(actor)
		return animClip
	end
	getAnimClip()
	local channel = (animClip ~= nil) and animClip:FindChannel(targetPath) or nil
	table.insert(self.m_graphs, {
		filmClip = filmClip,
		actor = actor,
		animClip = getAnimClip,
		channel = function()
			getAnimClip()
			channel = channel or ((animClip ~= nil) and animClip:FindChannel(targetPath) or nil)
			return channel
		end,
		curve = graph,
		valueTranslator = fValueTranslator,
		targetPath = targetPath,
		bookmarks = {},
		typeComponentIndex = typeComponentIndex or 0,
		valueType = valueType,
	})

	local uuid = tostring(actor:GetUniqueId())
	self.m_channelPathToGraphIndices[uuid] = self.m_channelPathToGraphIndices[uuid] or {}
	local graphIndices = self.m_channelPathToGraphIndices[uuid]
	graphIndices[targetPath] = graphIndices[targetPath] or {}
	table.insert(graphIndices[targetPath], #self.m_graphs)

	local idx = #self.m_graphs
	self:UpdateGraphCurveAxisRanges(idx)
	if channel ~= nil then
		self:RebuildGraphCurve(idx, self.m_graphs[idx])
	end
	return graph, idx
end
function gui.PFMTimelineGraph:GetGraphs()
	return self.m_graphs
end
function gui.PFMTimelineGraph:UpdateAxisRanges(startOffset, zoomLevel, timeStartOffset, timeZoomLevel)
	if util.is_valid(self.m_grid) then
		self.m_grid:SetStartOffsetX(startOffset)
		self.m_grid:SetZoomLevelX(zoomLevel)
		self.m_grid:SetStartOffsetY(timeStartOffset)
		self.m_grid:SetZoomLevelY(timeZoomLevel)
		self.m_grid:Update()
	end
	for i = 1, #self.m_graphs do
		self:UpdateGraphCurveAxisRanges(i)
	end
end
function gui.PFMTimelineGraph:GetTimeRange()
	local minTime = math.huge
	local maxTime = -math.huge
	for _, graph in ipairs(self.m_graphs) do
		if graph.curve:IsValid() then
			local editorKeys = graph.curve:GetEditorKeys()
			if editorKeys:GetTimeCount() > 0 then
				local t0 = editorKeys:GetTime(0)
				local t1 = editorKeys:GetTime(editorKeys:GetTimeCount() - 1)
				minTime = math.min(minTime, t0)
				maxTime = math.max(maxTime, t1)
			end
		end
	end
	if minTime == math.huge then
		return 0, 0
	end
	return minTime, maxTime
end
function gui.PFMTimelineGraph:GetDataRange()
	local minTime = math.huge
	local maxTime = -math.huge
	local minValue = math.huge
	local maxValue = -math.huge
	for _, graph in ipairs(self.m_graphs) do
		if graph.curve:IsValid() then
			local dataPoints = graph.curve:GetDataPoints()
			for _, dp in ipairs(dataPoints) do
				local t = dp:GetTime()
				local v = dp:GetValue()

				minTime = math.min(minTime, t)
				maxTime = math.max(maxTime, t)

				minValue = math.min(minValue, v)
				maxValue = math.max(maxValue, v)
			end
		end
	end
	if minTime == math.huge then
		return 0, 0, 0, 0
	end
	return minTime, maxTime, minValue, maxValue
end
function gui.PFMTimelineGraph:SetTimeRange(startTime, endTime, margin)
	self.m_timeline:SetTimeRange(startTime, endTime, margin, self.m_dataAxisStrip:GetRight())
end
function gui.PFMTimelineGraph:SetDataRange(startVal, endVal, margin)
	self.m_timeline:SetDataRange(startVal, endVal, margin)
end
function gui.PFMTimelineGraph:FitViewToDataRange()
	local minTime, maxTime, minVal, maxVal = self:GetDataRange()
	if math.abs(maxTime - minTime) < 0.001 then
		-- Time interval is 0, so we add an arbitrary amount of time
		minTime = maxTime - 0.5
		maxTime = maxTime + 0.5
	end
	if math.abs(maxVal - minVal) < 0.001 then
		-- Value delta is 0, so we add an arbitrary value
		minVal = maxVal - 5
		maxVal = maxVal + 5
	end
	self:SetTimeRange(minTime, maxTime, 20.0)
	self:SetDataRange(minVal, maxVal, 20.0)
end
function gui.PFMTimelineGraph:SetupControl(
	filmClip,
	actor,
	targetPath,
	item,
	color,
	fValueTranslator,
	valueType,
	typeComponentIndex
)
	local graph, graphIndex
	item:AddCallback("OnSelected", function()
		if util.is_valid(graph) then
			self:RemoveGraphCurve(graphIndex)
		end

		local track = filmClip:FindAnimationChannelTrack()
		if track == nil then
			return
		end
		graph, graphIndex =
			self:AddGraph(filmClip, track, actor, targetPath, color, fValueTranslator, valueType, typeComponentIndex)
	end)
	item:AddCallback("OnDeselected", function()
		if util.is_valid(graph) then
			self:RemoveGraphCurve(graphIndex)
		end
	end)
end
function gui.PFMTimelineGraph:AddKeyframe(time)
	if util.is_valid(self.m_timeline) == false then
		return
	end

	for _, graph in ipairs(self.m_graphs) do
		if graph.curve:IsValid() then
			local value = get_default_value(graph.valueType)
			local valueType = graph.valueType
			local channel = graph.curve:GetPanimaChannel()
			if channel ~= nil then
				local idx0, idx1, factor = channel:FindInterpolationIndices(self:InterfaceTimeToDataTime(graph, time))
				if idx0 ~= nil then
					local v0 = channel:GetValue(idx0)
					local v1 = channel:GetValue(idx1)
					value = udm.lerp(v0, v1, factor)
				end
			end

			pfm.get_project_manager():SetActorAnimationComponentProperty(
				graph.actor,
				graph.targetPath,
				self:InterfaceTimeToDataTime(graph, time),
				value,
				valueType,
				graph.typeComponentIndex
			)
		end
	end
end
function gui.PFMTimelineGraph:OnVisibilityChanged(visible)
	input.set_binding_layer_enabled("pfm_graph_editor", visible)
	input.update_effective_input_bindings()

	if visible == false or util.is_valid(self.m_timeline) == false then
		return
	end
	local timeline = self.m_timeline:GetTimeline()
	timeline:ClearBookmarks()
end
function gui.PFMTimelineGraph:GetPropertyList()
	return self.m_transformList
end
function gui.PFMTimelineGraph:AddControl(filmClip, actor, controlData, memberInfo, valueTranslator)
	local itemCtrl = self.m_transformList:AddItem(controlData.name, nil, nil, controlData.name)
	itemCtrl:SetName(controlData.path:replace("/", "_"))
	local function addChannel(item, fValueTranslator, color, typeComponentIndex)
		self:SetupControl(
			filmClip,
			actor,
			controlData.path,
			item,
			color or Color.Red,
			fValueTranslator,
			memberInfo.type,
			typeComponentIndex or 0
		)
	end
	if udm.is_numeric_type(memberInfo.type) then
		local valueTranslator
		if memberInfo.type == udm.TYPE_BOOLEAN then
			valueTranslator = {
				function(v)
					return v
				end,
				function(v)
					return (v >= 0.5) and true or false
				end,
			}
		end
		addChannel(itemCtrl, valueTranslator)

		--[[local log = channel:GetLog()
		local layers = log:GetLayers()
		local layer = layers:Get(1) -- TODO: Which layer(s) are the bookmarks refering to?
		if(layer ~= nil) then
			local bookmarks = log:GetBookmarks()
			for _,bookmark in ipairs(bookmarks:GetTable()) do
				self:AddKey(bookmark)
				-- Get from layer
			end
		end]]
	elseif udm.is_vector_type(memberInfo.type) then
		local n = udm.get_numeric_component_count(memberInfo.type)
		assert(n < 5)
		local type = udm.get_class_type(memberInfo.type)
		local vectorComponents = {
			{ "X", pfm.get_color_scheme_color("red") },
			{ "Y", pfm.get_color_scheme_color("green") },
			{ "Z", pfm.get_color_scheme_color("blue") },
			{ "W", pfm.get_color_scheme_color("pink") },
		}
		for i = 0, n - 1 do
			local vc = vectorComponents[i + 1]
			local item = itemCtrl:AddItem(vc[1])
			item:SetName(vc[1]:lower())
			addChannel(item, nil, vc[2], i)
		end
	elseif udm.is_matrix_type(memberInfo.type) then
		local nRows = udm.get_matrix_row_count(memberInfo.type)
		local nCols = udm.get_matrix_column_count(memberInfo.type)
		local type = udm.get_class_type(memberInfo.type)
		for i = 0, nRows - 1 do
			for j = 0, nCols - 1 do
				addChannel(itemCtrl:AddItem("M[" .. i .. "][" .. j .. "]"), {
					function(v)
						return v:Get(i, j)
					end,
					function(v, curVal)
						local r = curVal:Copy()
						r:Set(i, j, v)
						return r
					end,
				}, nil, i * nCols + j)
			end
		end
	elseif memberInfo.type == udm.TYPE_EULER_ANGLES then
		addChannel(itemCtrl:AddItem(locale.get_text("euler_pitch")), nil, pfm.get_color_scheme_color("red"), 0)
		addChannel(itemCtrl:AddItem(locale.get_text("euler_yaw")), nil, pfm.get_color_scheme_color("green"), 1)
		addChannel(itemCtrl:AddItem(locale.get_text("euler_roll")), nil, pfm.get_color_scheme_color("blue"), 2)
	elseif memberInfo.type == udm.TYPE_QUATERNION then
		addChannel(itemCtrl:AddItem(locale.get_text("euler_pitch")), nil, pfm.get_color_scheme_color("red"), 0)
		addChannel(itemCtrl:AddItem(locale.get_text("euler_yaw")), nil, pfm.get_color_scheme_color("green"), 1)
		addChannel(itemCtrl:AddItem(locale.get_text("euler_roll")), nil, pfm.get_color_scheme_color("blue"), 2)
	end
	if controlData.type == "flexController" then
		if controlData.dualChannel ~= true then
			local property = controlData.getProperty(component)
			local channel = track:FindFlexControllerChannel(property)
			if channel ~= nil then
				addChannel(channel, itemCtrl)

				local log = channel:GetLog()
				local layers = log:GetLayers()
				local layer = layers:Get(1) -- TODO: Which layer(s) are the bookmarks refering to?
				if layer ~= nil then
					local bookmarks = log:GetBookmarks()
					for _, bookmark in ipairs(bookmarks:GetTable()) do
						self:AddKey(bookmark)
						-- Get from layer
					end
					--[[local graphCurve = channel:GetGraphCurve()
					local keyTimes = graphCurve:GetKeyTimes()
					local keyValues = graphCurve:GetKeyValues()
					local n = math.min(#keyTimes,#keyValues)
					for i=1,n do
						local t = keyTimes:Get(i)
						local v = keyValues:Get(i)
						self:AddKey(t,v)
					end]]
				end
			end
		else
			local leftProperty = controlData.getLeftProperty(component)
			local leftChannel = track:FindFlexControllerChannel(leftProperty)
			if leftChannel ~= nil then
				addChannel(leftChannel, itemCtrl:AddItem(locale.get_text("left")))
			end

			local rightProperty = controlData.getRightProperty(component)
			local rightChannel = track:FindFlexControllerChannel(rightProperty)
			if rightChannel ~= nil then
				addChannel(rightChannel, itemCtrl:AddItem(locale.get_text("right")))
			end
		end
	elseif controlData.type == "bone" then
		local channel = track:FindBoneChannel(controlData.bone:GetTransform())
		-- TODO: Localization
		if channel ~= nil then
			addChannel(channel, itemCtrl:AddItem("Position X"), function(v)
				return v.x
			end)
			addChannel(channel, itemCtrl:AddItem("Position Y"), function(v)
				return v.y
			end)
			addChannel(channel, itemCtrl:AddItem("Position Z"), function(v)
				return v.z
			end)

			addChannel(channel, itemCtrl:AddItem("Rotation X"), function(v)
				return v:ToEulerAngles().p
			end)
			addChannel(channel, itemCtrl:AddItem("Rotation Y"), function(v)
				return v:ToEulerAngles().y
			end)
			addChannel(channel, itemCtrl:AddItem("Rotation Z"), function(v)
				return v:ToEulerAngles().r
			end)
		end
	end

	itemCtrl:AddCallback("OnSelected", function(elCtrl)
		for _, el in ipairs(elCtrl:GetItems()) do
			el:Select()
		end
	end)
	-- TODO: WHich layer?
	-- Log Type?
	--[[local layerType = logLayer:GetValues():GetValueType()
	--float log
	--local type = self:GetValues():GetValueType()
	if(layer ~= nil) then
		local label = locale.get_text("position")
		self:AddTransform(layer,itemCtrl,label .. " X",Color.Red,function(v) return v end)
		self:AddTransform(layer,itemCtrl,label .. " X",Color.Red,function(v) return v.x end)
		--Color(227,90,90)
		self:AddTransform(layer,itemCtrl,label .. " Y",Color.Lime,function(v) return v.y end)
		--Color(84,168,70)
		self:AddTransform(layer,itemCtrl,label .. " Z",Color.Blue,function(v) return v.z end)
		--Color(96,127,193)
	end

	self.m_transformList:Update()
	self.m_transformList:SizeToContents()
	self.m_transformList:SetWidth(204)]]
	return itemCtrl
end
--[[function gui.PFMTimelineGraph:Setup(actor,channelClip)
	local mdlC = actor:FindComponent("pfm_model")
	if(mdlC == nil or util.is_valid(self.m_boneList) == false) then return end

	for _,bone in ipairs(mdlC:GetBoneList():GetTable()) do
		bone = bone:GetTarget()
		local bonePosChannel
		local boneRotChannel
		for _,channel in ipairs(channelClip:GetChannels():GetTable()) do
			if(util.is_same_object(channel:GetToElement(),bone:GetTransform())) then
				if(channel:GetToAttribute() == "position") then bonePosChannel = channel end
				if(channel:GetToAttribute() == "rotation") then boneRotChannel = channel end
				if(bonePosChannel ~= nil and boneRotChannel ~= nil) then
					break
				end
			end
		end

		local itemBone = self.m_boneList:AddItem(bone:GetName())
		itemBone:AddCallback("OnSelected",function(elBone)
			for _,el in ipairs(elBone:GetItems()) do
				el:Select()
			end
		end)
		if(bonePosChannel ~= nil) then
			local log = bonePosChannel:GetLog()
			local layer = log:GetLayers():FindByName("vector3 log")
			if(layer ~= nil) then
				local label = locale.get_text("position")
				self:AddTransform(layer,itemBone,label .. " X",Color.Red,function(v) return v.x end)
				--Color(227,90,90)
				self:AddTransform(layer,itemBone,label .. " Y",Color.Lime,function(v) return v.y end)
				--Color(84,168,70)
				self:AddTransform(layer,itemBone,label .. " Z",Color.Blue,function(v) return v.z end)
				--Color(96,127,193)
			end
		end
		if(boneRotChannel ~= nil) then
			local log = boneRotChannel:GetLog()
			local layer = log:GetLayers():FindByName("quaternion log")
			if(layer ~= nil) then
				local label = locale.get_text("rotation")
				self:AddTransform(layer,itemBone,label .. " X",Color.Red,function(v) return v:ToEulerAngles().p end)
				self:AddTransform(layer,itemBone,label .. " Y",Color.Lime,function(v) return v:ToEulerAngles().y end)
				self:AddTransform(layer,itemBone,label .. " Z",Color.Blue,function(v) return v:ToEulerAngles().r end)
			end
		end
	end

	self.m_boneList:Update()
	self.m_boneList:SizeToContents()
	self.m_boneList:SetWidth(204)
end]]
gui.register("WIPFMTimelineGraph", gui.PFMTimelineGraph)
