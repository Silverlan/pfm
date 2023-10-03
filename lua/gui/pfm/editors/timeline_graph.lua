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
include("key.lua")
include("easing.lua")

util.register_class("gui.PFMTimelineGraph", gui.Base)

include("graph_editor")

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
		local startTimeBoundary, endTimeBoundary = editorChannel:GetKeyframeTimeBoundaries(startTime, endTime)

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
	self:ClearKeyframeListeners()
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
function gui.PFMTimelineGraph:FindGraphCurve(actor, targetPath, typeComponentIndex)
	local graphData = self:FindGraphData(actor, targetPath, typeComponentIndex)
	if graphData == nil then
		return
	end
	return graphData.curve
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
function gui.PFMTimelineGraph:GetFilmClip()
	return self.m_filmClip
end
function gui.PFMTimelineGraph:Setup(filmClip)
	self:ClearKeyframeListeners()
	self.m_filmClip = filmClip
	self:InitializeKeyframeListeners(filmClip)
end
function gui.PFMTimelineGraph:KeyboardCallback(key, scanCode, state, mods)
	if key == input.KEY_DELETE then
		if state == input.STATE_PRESS then
			local dps = self:GetSelectedDataPoints(false, true)
			local cmd = pfm.create_command("composition")
			for _, dp in ipairs(dps) do
				local actor, targetPath, keyIndex, curveData = dp:GetChannelValueData()
				if actor ~= nil then
					local baseIndex = dp:GetTypeComponentIndex()

					local editorChannel = curveData.curve:GetEditorChannel()
					if editorChannel == nil then
						return
					end

					local editorGraphCurve = editorChannel:GetGraphCurve()
					local editorKeys = editorGraphCurve:GetKey(baseIndex)
					local keyIndex = dp:GetKeyIndex()
					local time = editorKeys:GetTime(keyIndex)
					cmd:AddSubCommand("delete_keyframe", tostring(actor:GetUniqueId()), targetPath, time, baseIndex)
				end
			end
			pfm.undoredo.push("delete_keyframes", cmd)()
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
function gui.PFMTimelineGraph:SetDataPointMoveModeEnabled(dataPoints, enabled, moveThreshold)
	local filmClip = self:GetFilmClip()
	if enabled then
		self.m_dataPointMoveInfo = {}
		local pm = pfm.get_project_manager()
		local animManager = pm:GetAnimationManager()
		local curves = {}
		for _, dp in ipairs(dataPoints) do
			local timelineCurve = dp:GetGraphCurve()
			local timelineGraph = timelineCurve:GetTimelineGraph()
			local curveIndex = timelineCurve:GetCurveIndex()
			curves[curveIndex] = curves[curveIndex] or {}
			table.insert(curves[curveIndex], dp)
		end
		self.m_dataPointMoveInfo.curves = {}
		local curveInfo = {}
		for curveIndex, elDps in pairs(curves) do
			local curveData = self.m_graphs[curveIndex]
			local curve = curveData.curve
			local editorChannel = curve:GetEditorChannel()

			local animClip = editorChannel:GetAnimationClip()
			local actor = editorChannel:GetActor()
			local propertyPath = editorChannel:GetTargetPath()
			local typeComponentIndex = curveData.typeComponentIndex
			local keyData = editorChannel:GetGraphCurve():GetKey(typeComponentIndex)
			local channel = animClip:FindChannel(propertyPath)

			local udmData, err = udm.create()
			local data = udmData:GetAssetData():GetData()
			pfm.util.AffixedAnimationData(data, animManager, actor, propertyPath, channel, keyData, typeComponentIndex)
			curveInfo[curveIndex] = {
				udmData = udmData,
				curve = curve,
			}

			curve:SetMoveModeEnabled(enabled, filmClip, moveThreshold, data, elDps) -- TODO: Disable on disable
		end
		self.m_dataPointMoveInfo.curveInfo = curveInfo
		for curveIndex, _ in pairs(curveInfo) do
			table.insert(self.m_dataPointMoveInfo.curves, curveIndex)
		end
	else
		local cmd = pfm.create_command("composition")
		for _, curveInfo in ipairs(self.m_dataPointMoveInfo.curveInfo) do
			if curveInfo.curve:IsValid() then
				curveInfo.curve:SetMoveModeEnabled(false, cmd)
			end
		end
		pfm.undoredo.push("move_keyframes", cmd)()
	end
end
function gui.PFMTimelineGraph:MouseCallback(button, state, mods)
	self:RequestFocus()

	local isCtrlDown = input.is_ctrl_key_down()
	local isAltDown = input.is_alt_key_down()
	local isShiftDown = input.is_shift_key_down()
	local cursorMode = self:GetCursorMode()
	if self:IsInDrawingMode() and state == input.STATE_RELEASE then
		self:EndCanvasDrawing()
		return util.EVENT_REPLY_HANDLED
	end
	if isShiftDown and cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT then
		if state == input.STATE_PRESS then
			if #self.m_graphs == 1 then
				local graphData = self.m_graphs[1]
				local curve = graphData.curve
				self:StartCanvasDrawing(
					curve:GetEditorChannel():GetAnimationClip():GetActor(),
					graphData.targetPath,
					graphData.typeComponentIndex
				)
			end
		end
		return util.EVENT_REPLY_HANDLED
	end
	if button == input.MOUSE_BUTTON_LEFT then
		if cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_MOVE then
			local moveEnabled = (state == input.STATE_PRESS)
			local dataPoints = self:GetSelectedDataPoints()
			self:SetDataPointMoveModeEnabled(dataPoints, moveEnabled)
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

			pContext
				:AddItem(locale.get_text("pfm_generate_keyframes"), function()
					if self:IsValid() then
						self:ApplyCurveFitting()
					end
				end)
				:SetName("apply_curve_fitting")

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
function gui.PFMTimelineGraph:ApplyCurveFittingToRange(actorUuid, propertyPath, baseIndex, channel, tStart, tEnd)
	local keyframes = channel:CalculateCurveFittingKeyframes(tStart, tEnd)
	if keyframes == nil then
		return
	end
	local panimaChannel = channel:GetPanimaChannel()
	local cmd = pfm.create_command("keyframe_property_composition", actorUuid, propertyPath, baseIndex)
	cmd:AddSubCommand(
		"apply_curve_fitting",
		actorUuid,
		propertyPath,
		keyframes,
		panimaChannel:GetValueType(),
		baseIndex
	)
	pfm.undoredo.push("apply_curve_fitting", cmd)()
end
function gui.PFMTimelineGraph:ApplyCurveFitting()
	for _, graphData in ipairs(self.m_graphs) do
		local curve = graphData.curve
		local editorChannel = curve:GetEditorChannel()

		local animClip = editorChannel:GetAnimationClip()
		local actor = editorChannel:GetActor()
		local propertyPath = editorChannel:GetTargetPath()
		local typeComponentIndex = graphData.typeComponentIndex
		local channel = animClip:FindChannel(propertyPath)
		if channel:GetValueCount() > 0 then
			local tStartAnim = channel:GetTime(0)
			local tEndAnim = channel:GetTime(channel:GetTimeCount() - 1)
			local keyData = editorChannel:GetGraphCurve():GetKey(typeComponentIndex)
			if keyData ~= nil then
				local tStartKf = keyData:GetTime(0)
				local tEndKf = keyData:GetTime(keyData:GetTimeCount() - 1)

				self:ApplyCurveFittingToRange(actor, propertyPath, typeComponentIndex, channel, tStartAnim, tStartKf)
				self:ApplyCurveFittingToRange(actor, propertyPath, typeComponentIndex, channel, tEndKf, tEndAnim)
			else
				-- No keyframes exist, just apply curve fitting to entire range
				self:ApplyCurveFittingToRange(actor, propertyPath, typeComponentIndex, channel, tStartAnim, tEndAnim)
			end
		end
	end
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

function gui.PFMTimelineGraph:ReloadGraphCurve(targetPath)
	for i, graphData in ipairs(self.m_graphs) do
		if graphData.targetPath == targetPath then
			self:RebuildGraphCurve(i, graphData)
		end
	end
end

function gui.PFMTimelineGraph:RebuildGraphCurve(i, graphData, updateCurveOnly)
	local animClip = graphData.animClip()
	local channel = graphData.channel()
	if animClip == nil or channel == nil then
		return
	end
	if graphData.editorChannel == nil then
		local targetPath = channel:GetTargetPath()
		local animClip = graphData.animClip()
		if animClip ~= nil then
			local editorData = animClip:GetEditorData()
			local channel = editorData:FindChannel(targetPath)
			graphData.editorChannel = channel
		end
	end
	graphData.curve:InitializeCurve(graphData.editorChannel, graphData.typeComponentIndex, i)

	local editorChannel = graphData.curve:GetEditorChannel()
	if editorChannel == nil then
		return
	end
	local curve = editorChannel:GetGraphCurve()
	local curveValues = curve:CalcUiCurveValues(graphData.typeComponentIndex, function(t)
		return self:DataTimeToInterfaceTime(graphData, t)
	end, (graphData.valueTranslator ~= nil) and graphData.valueTranslator[1] or nil)
	graphData.curve:UpdateCurveData(curveValues)

	--[[
	self.m_editorChannel = editorChannel
	self.m_typeComponentIndex = typeComponentIndex
	self.m_curveIndex = curveIndex
]]

	--[[
function gui.PFMTimelineCurve:UpdateCurveData(curveValues)
	self.m_curve:BuildCurve(curveValues)
end
]]

	--function pfm.udm.EditorGraphCurve:CalcUiCurveValues(typeComponentIndex, translateTime, valueTranslator)

	--[[if updateCurveOnly then
		graphData.curve:UpdateCurveData(curveValues)
		return
	end

	self:InitializeBookmarks()
	graphData.curve:BuildCurve(curveValues, animClip, channel, i, graphData.editorChannel, graphData.typeComponentIndex)
	local editorKeys = graphData.curve:GetEditorKeys()
	graphData.numValues = (editorKeys ~= nil) and editorKeys:GetTimeCount() or 0]]
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
function gui.PFMTimelineGraph:ReloadGraphView()
	local list = self:GetPropertyList()
	local selected = {}
	for el, b in pairs(list:GetSelectedElements()) do
		if el:IsValid() then
			table.insert(selected, el)
		end
	end
	for _, el in ipairs(selected) do
		-- TODO: This is not a good way to handle it
		el:SetSelected(false)
		el:SetSelected(true)
	end
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
