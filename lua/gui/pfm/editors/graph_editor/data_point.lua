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
	el:AddCallback("OnInControlMoveStarted", function(el, ctrl, startPos)
		self:OnHandleControlMoveStarted()
	end)
	el:AddCallback("OnOutControlMoveStarted", function(el, ctrl, startPos)
		self:OnHandleControlMoveStarted()
	end)
	el:AddCallback("OnInControlMoveComplete", function(el, ctrl, startPos)
		self:OnHandleControlMoveComplete()
	end)
	el:AddCallback("OnOutControlMoveComplete", function(el, ctrl, startPos)
		self:OnHandleControlMoveComplete()
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
function gui.PFMTimelineDataPoint:OnHandleControlMoveComplete()
	if self.m_handleMoveData == nil then
		return
	end

	local curve = self:GetGraphCurve()
	local editorChannel = curve:GetEditorChannel()
	if editorChannel == nil then
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(self:GetTypeComponentIndex())
	local keyIndex = self:GetKeyIndex()
	local deltaIn = editorKeys:GetHandleDelta(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
	local timeIn = editorKeys:GetHandleTimeOffset(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN)
	local deltaOut = editorKeys:GetHandleDelta(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)
	local timeOut = editorKeys:GetHandleTimeOffset(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT)

	local cmd = pfm.create_command("composition")
	self:CreateHandleMoveCommand(
		cmd,
		pfm.udm.EditorGraphCurveKeyData.HANDLE_IN,
		self.m_handleMoveData.timeIn,
		timeIn,
		self.m_handleMoveData.deltaIn,
		deltaIn
	)
	self:CreateHandleMoveCommand(
		cmd,
		pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT,
		self.m_handleMoveData.timeOut,
		timeOut,
		self.m_handleMoveData.deltaOut,
		deltaOut
	)
	cmd:Execute()
	pfm.undoredo.push("move_keyframe_handles", cmd)()

	self.m_handleMoveData = nil
end
function gui.PFMTimelineDataPoint:OnHandleControlMoveStarted()
	self.m_handleMoveData = nil
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	if actor == nil then
		return
	end

	local curve = self:GetGraphCurve()
	local editorChannel = curve:GetEditorChannel()
	if editorChannel == nil then
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(self:GetTypeComponentIndex())

	local keyIndex = self:GetKeyIndex()
	self.m_handleMoveData = {
		deltaIn = editorKeys:GetHandleDelta(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN),
		timeIn = editorKeys:GetHandleTimeOffset(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_IN),
		deltaOut = editorKeys:GetHandleDelta(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT),
		timeOut = editorKeys:GetHandleTimeOffset(keyIndex, pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT),
	}
end
function gui.PFMTimelineDataPoint:CreateHandleMoveCommand(cmd, handle, oldTime, time, oldDelta, delta)
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	if actor == nil then
		return
	end
	local curve = self:GetGraphCurve()
	local editorChannel = curve:GetEditorChannel()
	local baseIndex = self:GetTypeComponentIndex()
	local timestamp = self:GetTime()
	cmd:AddSubCommand(
		"move_keyframe_handle",
		tostring(actor:GetUniqueId()),
		targetPath,
		timestamp,
		baseIndex,
		handle,
		oldTime,
		time,
		oldDelta,
		delta
	)
end
function gui.PFMTimelineDataPoint:OnHandleMoved(newPos, inHandle)
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	if actor == nil then
		return
	end
	local editorKeys, keyIndex, time, delta = self:GetKeyTimeDelta(newPos)
	local timestamp = editorKeys:GetTime(keyIndex)
	local baseIndex = self:GetTypeComponentIndex()
	local handle = inHandle and pfm.udm.EditorGraphCurveKeyData.HANDLE_IN or pfm.udm.EditorGraphCurveKeyData.HANDLE_OUT
	local cmd = pfm.create_command("composition")
	self:CreateHandleMoveCommand(cmd, handle, time, time, delta, delta)
	cmd:Execute()
end
function gui.PFMTimelineDataPoint:OnRemove()
	util.remove(self.m_tangentControl)
end
function gui.PFMTimelineDataPoint:SetGraphData(timelineCurve, keyframeInfo)
	self.m_graphData = {
		timelineCurve = timelineCurve,
		keyframeInfo = keyframeInfo,
	}
end
function gui.PFMTimelineDataPoint:GetKeyIndex()
	return self.m_graphData.keyframeInfo:GetIndex()
end
function gui.PFMTimelineDataPoint:GetKeyframeInfo()
	return self.m_graphData.keyframeInfo
end
function gui.PFMTimelineDataPoint:SetKeyIndex(index)
	-- TODO: Remove
	-- self.m_graphData.keyIndex = index
end
function gui.PFMTimelineDataPoint:GetTime()
	local editorKeys, keyIndex = self:GetEditorKeys()
	return editorKeys:GetTime(keyIndex)
end
function gui.PFMTimelineDataPoint:GetValue()
	local editorKeys, keyIndex = self:GetEditorKeys()
	return editorKeys:GetValue(keyIndex)
end
function gui.PFMTimelineDataPoint:GetValueType()
	local editorKeys, keyIndex = self:GetEditorKeys()
	return editorKeys:GetValueArrayValueType()
end
function gui.PFMTimelineDataPoint:ChangeDataValue(t, v)
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	if actor == nil then
		return
	end

	local kfInfo = self:GetKeyframeInfo()
	local keyIndex = kfInfo:GetIndex()
	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	local editorKeys, keyIndex = self:GetEditorKeys()

	local baseIndex = self:GetTypeComponentIndex()
	local cmd =
		pfm.create_command("keyframe_property_composition", tostring(actor:GetUniqueId()), targetPath, baseIndex)
	if t ~= nil then
		local timestamp = editorKeys:GetTime(keyIndex)
		local oldTime = timestamp
		local newTime = t
		cmd:AddSubCommand(
			"set_keyframe_time",
			tostring(actor:GetUniqueId()),
			targetPath,
			timestamp,
			oldTime,
			newTime,
			baseIndex
		)
	end
	if v ~= nil then
		local t = editorKeys:GetTime(keyIndex)
		local oldValue = editorKeys:GetValue(keyIndex)
		cmd:AddSubCommand(
			"set_keyframe_value",
			tostring(actor:GetUniqueId()),
			targetPath,
			t,
			udm.get_numeric_component(oldValue, baseIndex),
			v,
			baseIndex
		)
	end
	pfm.undoredo.push("move_keyframe", cmd)()
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
function gui.PFMTimelineDataPoint:MoveToPosition(cmd, time, value, curTime, curVal)
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()

	local actor, targetPath, keyIndex, curveData = self:GetChannelValueData()
	local newValue = Vector2(time, value)
	newValue = { newValue.x, newValue.y }
	newValue[1] = math.snap_to_gridf(newValue[1], 1.0 / pm:GetFrameRate()) -- TODO: Only if snap-to-grid is enabled
	newValue[2] = math.round(newValue[2] * 100.0) / 100.0 -- TODO: Make round precision dependent on animation property

	local panimaChannel = timelineCurve:GetPanimaChannel()
	local baseIndex = self:GetTypeComponentIndex()
	if curveData.valueTranslator ~= nil then
		newValue[2] = curveData.valueTranslator[2](newValue[2], curVal)
	end

	if t ~= nil then
		local curTime, curVal =
			animManager:GetChannelValueByKeyframeIndex(actor, targetPath, panimaChannel, keyIndex, baseIndex)
		--[[local timestamp = editorKeys:GetTime(keyIndex)
		local oldTime = timestamp
		local newTime = t
		local baseIndex = self:GetTypeComponentIndex()

		]]
	end

	keyIndex = self:GetKeyIndex()
	local graphCurve = curveData.editorChannel:GetGraphCurve()
	local keyData = graphCurve:GetKey(baseIndex)
	curVal = curVal or keyData:GetValue(keyIndex)
	curTime = curTime or keyData:GetTime(keyIndex)
	local valueType = keyData:GetValueArrayValueType()
	local uuid = tostring(actor:GetUniqueId())
	cmd:AddSubCommand("set_keyframe_data", uuid, targetPath, curTime, time, curVal, value, baseIndex)
end
function gui.PFMTimelineDataPoint:MoveToCoordinates(x, y)
	--[[local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local v = timelineCurve:GetCurve():CoordinatesToValues(x + self:GetWidth() / 2.0, y + self:GetHeight() / 2.0)
	self:MoveToPosition(v.x, v.y)]]
end
function gui.PFMTimelineDataPoint:OnMoved(newPos)
	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	self.m_movePos = timelineCurve
		:GetCurve()
		:CoordinatesToValues(newPos.x + self:GetWidth() / 2.0, newPos.y + self:GetHeight() / 2.0)
	self:SetMoveDirty(true)
end
function gui.PFMTimelineDataPoint:GetMovePos()
	return self.m_movePos
end
function gui.PFMTimelineDataPoint:SetMoveDirty(dirty)
	dirty = dirty or false
	self.m_moveDirty = dirty
	if dirty == true then
		local graphData = self.m_graphData
		local timelineCurve = graphData.timelineCurve
		if timelineCurve:IsValid() then
			timelineCurve:SetMoveDirty()
		end
	end
end
function gui.PFMTimelineDataPoint:IsMoveDirty()
	return self.m_moveDirty or false
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
function gui.PFMTimelineDataPoint:OnMoveStarted(startData)
	startData.startTime = self:GetTime()
	startData.startValue = self:GetValue()
	self.m_movePos = nil
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

util.register_class("gui.PFMTimelineDataPointReference")
function gui.PFMTimelineDataPointReference:__init(dp)
	local actor, targetPath, keyIndex, curveData = dp:GetChannelValueData()
	self.m_actor = actor:GetUniqueId()
	self.m_targetPath = targetPath
	self.m_time = dp:GetTime()
	self.m_value = dp:GetValue()
	self.m_valueType = dp:GetValueType()
	self.m_typeComponentIndex = dp:GetTypeComponentIndex()
end

function gui.PFMTimelineDataPointReference:GetActorUuid()
	return self.m_actor
end

function gui.PFMTimelineDataPointReference:GetPropertyPath()
	return self.m_targetPath
end

function gui.PFMTimelineDataPointReference:GetTime()
	return self.m_time
end

function gui.PFMTimelineDataPointReference:GetValue()
	return self.m_value
end

function gui.PFMTimelineDataPointReference:GetValueType()
	return self.m_valueType
end

function gui.PFMTimelineDataPointReference:GetTypeComponentIndex()
	return self.m_typeComponentIndex
end
