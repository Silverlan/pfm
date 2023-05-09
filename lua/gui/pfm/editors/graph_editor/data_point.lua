--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("data_point_control.lua")

util.register_class("gui.PFMTimelineDataPoint", gui.PFMDataPointControl)
function gui.PFMTimelineDataPoint:OnInitialize()
	gui.PFMDataPointControl.OnInitialize(self)
end
function gui.PFMTimelineDataPoint:OnSelectionChanged(selected)
	if selected then
		self:InitializeHandleControl()
	end
	self:UpdateTextFields()
end
function gui.PFMTimelineDataPoint:GetTangentControl()
	return self.m_tangentControl
end
function gui.PFMTimelineDataPoint:UpdateHandles()
	if util.is_valid(self.m_tangentControl) == false then
		return
	end
	self.m_tangentControl:UpdateInOutLines(true, true)
	self:UpdateHandleType(pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
	self:UpdateHandleType(pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
end
function gui.PFMTimelineDataPoint:UpdateHandleType(handle)
	if util.is_valid(self.m_tangentControl) == false then
		return
	end
	local editorKeys = self:GetEditorKeys()
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		self.m_tangentControl:UpdateHandleType(handle, editorKeys:GetInHandleType(self:GetKeyIndex()))
	else
		self.m_tangentControl:UpdateHandleType(handle, editorKeys:GetOutHandleType(self:GetKeyIndex()))
	end
end
function gui.PFMTimelineDataPoint:GetEditorKeys()
	local curve = self:GetGraphCurve()
	local graph = curve:GetTimelineGraph()

	local editorChannel = curve:GetEditorChannel()
	if editorChannel == nil then
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(self:GetTypeComponentIndex())
	return editorKeys, self:GetKeyIndex()
end
function gui.PFMTimelineDataPoint:ReloadGraphCurveSegment()
	local curve = self:GetGraphCurve()
	local timelineGraph = curve:GetTimelineGraph()
	timelineGraph:ReloadGraphCurveSegment(curve:GetCurveIndex(), self:GetKeyIndex())
end
function gui.PFMTimelineDataPoint:IsHandleSelected()
	if util.is_valid(self.m_tangentControl) == false then
		return false
	end
	return self.m_tangentControl:GetInControl():IsSelected() or self.m_tangentControl:GetOutControl():IsSelected()
end
function gui.PFMTimelineDataPoint:OnUpdate()
	if util.is_valid(self.m_tangentControl) == false then
		return
	end
	self.m_tangentControl:SetPos(self:GetCenter())
	self.m_tangentControl:Update()
end
function gui.PFMTimelineDataPoint:InitializeHandleControl()
	if util.is_valid(self.m_tangentControl) then
		return
	end
	local el = gui.create("WIPFMTimelineTangentControl", self:GetParent())
	el:SetDataPoint(self)

	el:AddCallback("OnInControlMoved", function(el, newPos)
		self:OnHandleMoved(newPos, true)
	end)
	el:AddCallback("OnOutControlMoved", function(el, newPos)
		self:OnHandleMoved(newPos, false)
	end)

	local onMouseEvent = function(el, button, state, mods)
		if button == input.MOUSE_BUTTON_LEFT then
			if state == input.STATE_PRESS then
				el:SetSelected(true)
			end
			el:SetMoveModeEnabled(state == input.STATE_PRESS, 5)
			return util.EVENT_REPLY_HANDLED
		end
	end
	el:GetInControl():AddCallback("OnMouseEvent", onMouseEvent)
	el:GetOutControl():AddCallback("OnMouseEvent", onMouseEvent)

	self.m_tangentControl = el

	self:UpdateHandleType(pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
	self:UpdateHandleType(pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)

	self:Update()
end
function gui.PFMTimelineDataPoint:GetKeyTimeDelta(pos)
	local curve = self:GetGraphCurve()
	local graph = curve:GetTimelineGraph()
	local timeAxis = graph:GetTimeAxis()
	local dataAxis = graph:GetDataAxis()

	local editorChannel = curve:GetEditorChannel()
	if editorChannel == nil then
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(self:GetTypeComponentIndex())

	local keyIndex = self:GetKeyIndex()
	local val = pos - self:GetCenter()
	local time = timeAxis:GetAxis():XDeltaToValue(val.x)
	local delta = -dataAxis:GetAxis():XDeltaToValue(val.y)
	return editorKeys, keyIndex, time, delta
end
function gui.PFMTimelineDataPoint:OnHandleMoved(newPos, inHandle)
	local editorKeys, keyIndex, time, delta = self:GetKeyTimeDelta(newPos)
	local handle = inHandle and pfm.udm.EditorGraphCurveKeyData.HANDLE_IN or pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	if editorKeys:GetHandleType(keyIndex) == pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR then
		editorKeys:SetHandleType(keyIndex, handle, pfm.udm.KEYFRAME_HANDLE_TYPE_FREE)
	end
	local affectedKeys = editorKeys:SetHandleData(keyIndex, handle, time, delta)

	local curve = self:GetGraphCurve()
	local timelineGraph = curve:GetTimelineGraph()
	for _, af in ipairs(affectedKeys) do
		timelineGraph:ReloadGraphCurveSegment(curve:GetCurveIndex(), af[1])
	end

	curve:GetTimelineGraph():UpdateSelectedDataPointHandles()
end
function gui.PFMTimelineDataPoint:OnRemove()
	util.remove(self.m_tangentControl)
end
function gui.PFMTimelineDataPoint:SetGraphData(timelineCurve, keyIndex)
	self.m_graphData = {
		timelineCurve = timelineCurve,
		keyIndex = keyIndex,
	}
end
function gui.PFMTimelineDataPoint:GetKeyIndex()
	return self.m_graphData.keyIndex
end
function gui.PFMTimelineDataPoint:SetKeyIndex(index)
	self.m_graphData.keyIndex = index
end
function gui.PFMTimelineDataPoint:GetTime()
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	local editorKeys = timelineCurve:GetEditorKeys()
	return editorKeys:GetTime(keyIndex)
end
function gui.PFMTimelineDataPoint:GetValue()
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	local editorKeys = timelineCurve:GetEditorKeys()
	return editorKeys:GetValue(keyIndex)
end
function gui.PFMTimelineDataPoint:ChangeDataValue(t, v)
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve

	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	local panimaChannel = timelineCurve:GetPanimaChannel()
	if v ~= nil and curveData.valueTranslator ~= nil then
		local curTime, curVal = animManager:GetChannelValueByKeyframeIndex(
			actor,
			targetPath,
			panimaChannel,
			keyIndex,
			self:GetTypeComponentIndex()
		)
		v = curveData.valueTranslator[2](v, curVal)
	end

	if t == nil then
		t = self:GetTime()
		local graphData = self.m_graphData
		local timelineCurve = graphData.timelineCurve
		local timelineGraph = timelineCurve:GetTimelineGraph()
		local curveData = timelineGraph:GetGraphCurve(timelineCurve:GetCurveIndex())
		t = timelineGraph:DataTimeToInterfaceTime(curveData, t)
	end
	v = v or self:GetValue()
	pm:UpdateKeyframe(actor, targetPath, panimaChannel, keyIndex, t, v, self:GetTypeComponentIndex())
end
function gui.PFMTimelineDataPoint:UpdateTextFields()
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local pm = pfm.get_project_manager()
	local curValue = timelineCurve
		:GetCurve()
		:CoordinatesToValues(self:GetX() + self:GetWidth() / 2.0, self:GetY() + self:GetHeight() / 2.0)
	curValue = { curValue.x, curValue.y }
	curValue[2] = math.round(curValue[2] * 100.0) / 100.0 -- TODO: Make round precision dependent on animation property
	timelineCurve
		:GetTimelineGraph()
		:GetTimeline()
		:SetDataValue(util.round_string(pm:TimeOffsetToFrameOffset(curValue[1]), 2), util.round_string(curValue[2], 2))
end
function gui.PFMTimelineDataPoint:GetGraphCurve()
	return self.m_graphData.timelineCurve
end
function gui.PFMTimelineDataPoint:OnMoved(newPos)
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()

	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	-- TODO: Merge this with PFMTimelineDataPoint:UpdateTextFields()
	local newValue = timelineCurve
		:GetCurve()
		:CoordinatesToValues(newPos.x + self:GetWidth() / 2.0, newPos.y + self:GetHeight() / 2.0)
	newValue = { newValue.x, newValue.y }
	newValue[1] = math.snap_to_gridf(newValue[1], 1.0 / pm:GetFrameRate()) -- TODO: Only if snap-to-grid is enabled
	newValue[2] = math.round(newValue[2] * 100.0) / 100.0 -- TODO: Make round precision dependent on animation property

	local panimaChannel = timelineCurve:GetPanimaChannel()
	if curveData.valueTranslator ~= nil then
		local curTime, curVal = animManager:GetChannelValueByKeyframeIndex(
			actor,
			targetPath,
			panimaChannel,
			keyIndex,
			self:GetTypeComponentIndex()
		)
		newValue[2] = curveData.valueTranslator[2](newValue[2], curVal)
	end

	pm:UpdateKeyframe(
		actor,
		targetPath,
		panimaChannel,
		keyIndex,
		newValue[1],
		newValue[2],
		self:GetTypeComponentIndex()
	)
end
function gui.PFMTimelineDataPoint:GetChannelValueData()
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local timelineGraph = timelineCurve:GetTimelineGraph()
	local curveData = timelineGraph:GetGraphCurve(timelineCurve:GetCurveIndex())
	local animClip = curveData.animClip()
	local actor = animClip:GetActor()
	local targetPath = curveData.targetPath
	return actor, targetPath, graphData.keyIndex, curveData
end
function gui.PFMTimelineDataPoint:SetSelected(selected, keepTangentControlSelection)
	keepTangentControlSelection = keepTangentControlSelection or false
	if selected == false and keepTangentControlSelection == false then
		util.remove(self.m_tangentControl)
	end
	gui.PFMDataPointControl.SetSelected(self, selected)
end
function gui.PFMTimelineDataPoint:GetTypeComponentIndex()
	return self.m_graphData.timelineCurve:GetTypeComponentIndex()
end
function gui.PFMTimelineDataPoint:UpdateSelection(elSelectionRect)
	if elSelectionRect:IsElementInBounds(self) then
		if util.is_valid(self.m_tangentControl) then
			self.m_tangentControl:GetInControl():SetSelected(false)
			self.m_tangentControl:GetOutControl():SetSelected(false)
		end
		self:SetSelected(not input.is_alt_key_down(), true)
		return true
	end
	if util.is_valid(self.m_tangentControl) == false then
		return false
	end
	local inCtrl = self.m_tangentControl:GetInControl()
	local hasSelection = false
	if elSelectionRect:IsElementInBounds(inCtrl) then
		self:SetSelected(false, true)
		inCtrl:SetSelected(not input.is_alt_key_down())
		hasSelection = true
	end

	local outCtrl = self.m_tangentControl:GetOutControl()
	if elSelectionRect:IsElementInBounds(outCtrl) then
		self:SetSelected(false, true)
		outCtrl:SetSelected(not input.is_alt_key_down())
		hasSelection = true
	end
	return hasSelection
end
gui.register("WIPFMTimelineDataPoint", gui.PFMTimelineDataPoint)
