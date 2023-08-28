--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMTimelineCurve", gui.Base)
function gui.PFMTimelineCurve:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)
	local curve = gui.create("WICurve", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_curve = curve

	self.m_dataPoints = {}

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
	return self.m_channel
end
function gui.PFMTimelineCurve:GetPanimaChannel()
	return self.m_panimaChannel
end
function gui.PFMTimelineCurve:GetAnimationClip()
	return self.m_animClip
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
			el:SetGraphData(self, kfInfo)

			el:AddCallback("OnMouseEvent", function(el, button, state, mods)
				if self.m_timelineGraph:GetCursorMode() ~= gui.PFMTimelineGraph.CURSOR_MODE_SELECT then
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
function gui.PFMTimelineCurve:InitializeCurve(editorChannel, typeComponentIndex, curveIndex)
	self:ClearKeyframes()

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
function gui.PFMTimelineCurvefUpdateCurveValue(i, xVal, yVal)
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
