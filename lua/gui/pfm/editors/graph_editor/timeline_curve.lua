-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.PFMTimelineCurve", gui.Base)
function gui.PFMTimelineCurve:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	local curve = gui.create("WICurve", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_curve = curve

	self.m_dataPoints = {}
	self:SetDataPointsSelectable(true)

	curve:GetColorProperty():Link(self:GetColorProperty())
end
function gui.PFMTimelineCurve:GetTimelineGraph()
	return self.m_timelineGraph
end
function gui.PFMTimelineCurve:SetTimelineGraph(graph)
	self.m_timelineGraph = graph
end
function gui.PFMTimelineCurve:GetTypeComponentIndex()
	return self.m_typeComponentIndex
end
function gui.PFMTimelineCurve:GetCurveIndex()
	return self.m_curveIndex
end
function gui.PFMTimelineCurve:GetCurve()
	return self.m_curve
end
function gui.PFMTimelineCurve:GetChannel()
	if self.m_editorChannel == nil then
		return
	end
	local animClip = self.m_editorChannel:GetAnimationClip()
	if animClip == nil then
		return
	end
	return animClip:GetChannel(self.m_editorChannel:GetTargetPath())
end
function gui.PFMTimelineCurve:GetPanimaChannel()
	local animClip = self:GetAnimationClip()
	if animClip == nil then
		return
	end
	return animClip:GetPanimaAnimation():FindChannel(self.m_editorChannel:GetTargetPath())
end
function gui.PFMTimelineCurve:GetAnimationClip()
	return (self.m_editorChannel ~= nil) and self.m_editorChannel:FindAnimationClip() or nil
end
function gui.PFMTimelineCurve:GetEditorChannel()
	return self.m_editorChannel
end
function gui.PFMTimelineCurve:GetEditorKeys()
	local editorChannel = self:GetEditorChannel()
	if editorChannel == nil then
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()
	return editorGraphCurve:GetKey(self:GetTypeComponentIndex())
end
function gui.PFMTimelineCurve:UpdateCurveData(curveValues)
	self.m_curve:BuildCurve(curveValues)
end
function gui.PFMTimelineCurve:ClearKeyframes()
	util.remove(self.m_dataPoints)
	self.m_dataPoints = {}
end
function gui.PFMTimelineCurve:SetDataPointsSelectable(selectable)
	self.m_dataPointsSelectable = selectable
end
function gui.PFMTimelineCurve:AreDataPointsSelectable()
	return self.m_dataPointsSelectable
end
function gui.PFMTimelineCurve:UpdateKeyframes()
	local editorChannel = self:GetEditorChannel()
	if editorChannel == nil then
		self:ClearKeyframes()
		return
	end
	local typeComponentIndex = self:GetTypeComponentIndex()
	local editorGraphCurve = (editorChannel ~= nil) and editorChannel:GetGraphCurve() or nil
	local editorKeys = (editorGraphCurve ~= nil) and editorGraphCurve:GetKey(typeComponentIndex) or nil
	local numKeys = (editorKeys ~= nil) and editorKeys:GetKeyframeCount() or 0
	local curKeyframeInfos = {}
	if editorKeys ~= nil then
		for _, kfInfo in ipairs(editorKeys:GetKeyframeInfos()) do
			curKeyframeInfos[kfInfo] = true
		end
	end

	-- Clear all obsolete datapoints
	local newDatapoints = {}
	local kfInfoToDataPoint = {}
	for _, elDp in ipairs(self.m_dataPoints) do
		if elDp:IsValid() then
			local kfInfo = elDp:GetKeyframeInfo()
			if curKeyframeInfos[kfInfo] == true then
				table.insert(newDatapoints, elDp)
				kfInfoToDataPoint[kfInfo] = elDp
			else
				elDp:Remove()
			end
		end
	end
	self.m_dataPoints = newDatapoints
	for i = 0, numKeys - 1 do
		local kfInfo = editorKeys:GetKeyframeInfo(i)
		if kfInfoToDataPoint[kfInfo] == nil then
			local el = gui.create("WIPFMTimelineDataPoint", self)
			el:SetSelectable(self:AreDataPointsSelectable())
			el:SetGraphData(self, kfInfo)

			el:AddCallback("OnMouseEvent", function(el, button, state, mods)
				if self.m_timelineGraph:GetCursorMode() ~= gui.PFMTimelineGraphBase.CURSOR_MODE_SELECT then
					return util.EVENT_REPLY_UNHANDLED
				end
				if button == input.MOUSE_BUTTON_LEFT then
					if state == input.STATE_PRESS then
						if util.is_valid(self.m_selectedDataPoint) then
							self.m_selectedDataPoint:SetSelected(false)
						end
						el:SetSelected(true)
						self.m_selectedDataPoint = el
					end
					self:GetTimelineGraph():SetDataPointMoveModeEnabled({ el }, state == input.STATE_PRESS, 5)
					return util.EVENT_REPLY_HANDLED
				end
			end)
			self.m_selectedDataPoint = el
			table.insert(self.m_dataPoints, el)
		end
	end
	self:UpdateDataPoints()
end
function gui.PFMTimelineCurve:GetTargetPath()
	return self.m_editorChannel:GetTargetPath()
end
function gui.PFMTimelineCurve:SetMoveModeEnabled(enabled, ...)
	if enabled then
		local filmClip, moveThreshold, animData, elDps = ...

		local dataPointInfo = {}
		for _, dp in ipairs(elDps) do
			dp:SetMoveModeEnabled(enabled, moveThreshold)
			table.insert(dataPointInfo, {
				filmClip = pfm.reference(filmClip),
				keyIndex = dp:GetKeyIndex(),
				time = dp:GetTime(),
				value = dp:GetValue(),
				dpRef = gui.PFMTimelineDataPointReference(dp),
				dataPoint = dp,
			})
		end

		self.m_moveModeInfo = {
			animData = animData,
			dataPointInfo = dataPointInfo,
		}
	elseif self.m_moveModeInfo ~= nil then
		local cmd = ...

		local animClip = self:GetAnimationClip()
		local actor = animClip:GetActor()
		local res, subCmd = cmd:AddSubCommand(
			"move_keyframes",
			actor,
			self.m_editorChannel:GetTargetPath(),
			self:GetTypeComponentIndex(),
			self.m_moveModeInfo.animData
		)

		for _, dpInfo in ipairs(self.m_moveModeInfo.dataPointInfo) do
			local elDp = dpInfo.dataPoint
			if elDp:IsValid() then
				local oldTime = dpInfo.time
				local oldVal = dpInfo.value
				local posMove = elDp:GetMovePos()
				if posMove ~= nil then
					elDp:MoveToPosition(subCmd, posMove.x, posMove.y, oldTime, oldVal)
				end

				elDp:SetMoveDirty(false)
				elDp:SetMoveModeEnabled(enabled)
			end
		end
	end
end
function gui.PFMTimelineCurve:SetMoveDirty()
	self.m_moveDirty = true
	self:SetThinkingEnabled(true)
end
function gui.PFMTimelineCurve:OnThink()
	self:UpdateDataPointMove()
end
function gui.PFMTimelineCurve:UpdateDataPointMove()
	if self.m_moveDirty ~= true then
		return
	end
	self.m_moveDirty = nil
	self:SetThinkingEnabled(false)

	if self.m_moveModeInfo == nil then
		return
	end
	local animClip = self:GetAnimationClip()
	local actor = animClip:GetActor()
	local cmd = pfm.create_command(
		"move_keyframes",
		actor,
		self.m_editorChannel:GetTargetPath(),
		self:GetTypeComponentIndex(),
		self.m_moveModeInfo.animData
	)
	for _, dpInfo in ipairs(self.m_moveModeInfo.dataPointInfo) do
		local elDp = dpInfo.dataPoint
		if elDp:IsValid() then
			local posMove = elDp:GetMovePos()
			elDp:MoveToPosition(cmd, posMove.x, posMove.y)

			elDp:SetMoveDirty(false)
		end
	end
	cmd:Execute()
end
function gui.PFMTimelineCurve:InitializeCurve(editorChannel, typeComponentIndex, curveIndex)
	if util.is_same_object(editorChannel, self.m_editorChannel) == false then
		self:ClearKeyframes()
	end

	self.m_editorChannel = editorChannel
	self.m_typeComponentIndex = typeComponentIndex
	self.m_curveIndex = curveIndex

	self:UpdateKeyframes()
end
function gui.PFMTimelineCurve:BuildCurve(curveValues, animClip, channel, curveIndex, editorChannel, typeComponentIndex)
	self.m_channel = channel
	self.m_animClip = animClip
	-- self.m_panimaChannel = panima.Channel(channel:GetUdmData():Get("times"), channel:GetUdmData():Get("values"))
	self.m_editorChannel = editorChannel
	self.m_curveIndex = curveIndex
	self.m_typeComponentIndex = typeComponentIndex
	self:UpdateCurveData(curveValues)
end

function gui.PFMTimelineCurve:UpdateDataPoint(i)
	local el
	if type(i) == "number" then
		el = self.m_dataPoints[i]
	else
		el = i
	end
	if util.is_valid(el) == false then
		return
	end
	local keyIndex = el:GetKeyIndex()
	local editorGraphCurve = self.m_editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(self:GetTypeComponentIndex())

	local t = self:DataTimeToInterfaceTime(editorKeys:GetTime(keyIndex))
	local v = editorKeys:GetValue(keyIndex)
	local valueTranslator = self:GetTimelineGraph():GetGraphCurve(self:GetCurveIndex()).valueTranslator
	if valueTranslator ~= nil then
		v = valueTranslator[1](v)
	end
	local pos = self.m_curve:ValueToUiCoordinates(t, v)
	el:SetPos(pos - el:GetSize() / 2.0)
	el:Update()

	if el:IsSelected() then
		el:UpdateTextFields()
	end
end
function gui.PFMTimelineCurve:UpdateDataPoints()
	if self.m_editorChannel == nil then
		return
	end
	for i = 1, #self.m_dataPoints do
		self:UpdateDataPoint(i)
	end
end
function gui.PFMTimelineCurve:SwapDataPoints(idx0, idx1)
	local dp0 = self.m_dataPoints[idx0 + 1]
	local dp1 = self.m_dataPoints[idx1 + 1]
	dp0:SetKeyIndex(idx1)
	dp1:SetKeyIndex(idx0)
	self.m_dataPoints[idx0 + 1] = dp1
	self.m_dataPoints[idx1 + 1] = dp0
end
function gui.PFMTimelineCurve:GetDataPoint(idx)
	return self.m_dataPoints[idx + 1]
end
function gui.PFMTimelineCurve:GetDataPoints()
	return self.m_dataPoints
end
function gui.PFMTimelineCurve:FindDataPointByKeyframeInfo(kfInfo)
	for _, dp in ipairs(self.m_dataPoints) do
		if dp:IsValid() and util.is_same_object(dp:GetKeyframeInfo(), kfInfo) then
			return dp
		end
	end
end
function gui.PFMTimelineCurve:FindDataPoint(t)
	for _, dp in ipairs(self.m_dataPoints) do
		if dp:IsValid() then
			local dt = math.abs(dp:GetTime() - t)
			if dt <= pfm.udm.EditorChannelData.TIME_EPSILON then
				return dp
			end
		end
	end
end
function gui.PFMTimelineCurve:UpdateCurveValue(i, xVal, yVal)
	self.m_curve:UpdateCurveValue(i, xVal, yVal)
	self:UpdateDataPoints(i + 1)
end
function gui.PFMTimelineCurve:SetHorizontalRange(...)
	self.m_curve:SetHorizontalRange(...)
	self:UpdateDataPoints()
end
function gui.PFMTimelineCurve:SetVerticalRange(...)
	self.m_curve:SetVerticalRange(...)
	self:UpdateDataPoints()
end
function gui.PFMTimelineCurve:InterfaceTimeToDataTime(t)
	local tg = self:GetTimelineGraph()
	local graphData = tg:GetGraphCurve(self:GetCurveIndex())
	return tg:InterfaceTimeToDataTime(graphData, t)
end
function gui.PFMTimelineCurve:DataTimeToInterfaceTime(t)
	local tg = self:GetTimelineGraph()
	local graphData = tg:GetGraphCurve(self:GetCurveIndex())
	return tg:DataTimeToInterfaceTime(graphData, t)
end
gui.register("WIPFMTimelineCurve", gui.PFMTimelineCurve)
