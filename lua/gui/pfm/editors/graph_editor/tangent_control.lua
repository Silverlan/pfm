--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMTimelineTangentControl", gui.Base)
function gui.PFMTimelineTangentControl:OnInitialize()
	gui.Base.OnInitialize(self)

	local lineIn = gui.create("WILine", self:GetParent())
	lineIn:SetColor(Color.Red)
	lineIn:SetLineWidth(2)
	self.m_inLine = lineIn

	local ctrlIn = gui.create("WIPFMDataPointControl", self:GetParent())
	ctrlIn:SetColor(Color.Black)
	self.m_inCtrl = ctrlIn

	local lineOut = gui.create("WILine", self:GetParent())
	lineOut:SetColor(Color.Aqua)
	lineOut:SetLineWidth(2)
	self.m_outLine = lineOut

	local ctrlOut = gui.create("WIPFMDataPointControl", self:GetParent())
	ctrlOut:SetColor(Color.Black)
	self.m_outCtrl = ctrlOut

	self.m_inCtrl:AddCallback("OnMoved", function(ctrl, newPos)
		self:UpdateInControl(newPos)
	end)
	self.m_outCtrl:AddCallback("OnMoved", function(ctrl, newPos)
		self:UpdateOutControl(newPos)
	end)

	self.m_inCtrl:AddCallback("OnMoveStarted", function(ctrl, startData, startPos)
		self:CallCallbacks("OnInControlMoveStarted", ctrl, startPos)
	end)
	self.m_inCtrl:AddCallback("OnMoveComplete", function(ctrl, startData, startPos)
		self:CallCallbacks("OnInControlMoveComplete", ctrl, startPos)
	end)
	self.m_outCtrl:AddCallback("OnMoveStarted", function(ctrl, startData, startPos)
		self:CallCallbacks("OnOutControlMoveStarted", ctrl, startPos)
	end)
	self.m_outCtrl:AddCallback("OnMoveComplete", function(ctrl, startData, startPos)
		self:CallCallbacks("OnOutControlMoveComplete", ctrl, startPos)
	end)

	self.m_inLine:GetVisibilityProperty():Link(self:GetVisibilityProperty())
	self.m_inCtrl:GetVisibilityProperty():Link(self:GetVisibilityProperty())
	self.m_outLine:GetVisibilityProperty():Link(self:GetVisibilityProperty())
	self.m_outCtrl:GetVisibilityProperty():Link(self:GetVisibilityProperty())
end
function gui.PFMTimelineTangentControl:UpdateHandleType(handle, type)
	local colorScheme = pfm.get_color_scheme()
	local cpColor = colorScheme:GetColor("orange")

	local elLine
	local elCtrl
	local lineColor
	if handle == pfm.udm.EditorGraphCurveKeyData.HANDLE_IN then
		elLine = self.m_inLine
		elCtrl = self.m_inCtrl
	else
		elLine = self.m_outLine
		elCtrl = self.m_outCtrl
	end

	if type == pfm.udm.KEYFRAME_HANDLE_TYPE_ALIGNED then
		lineColor = colorScheme:GetColor("lightRed")
	elseif type == pfm.udm.KEYFRAME_HANDLE_TYPE_VECTOR then
		lineColor = colorScheme:GetColor("lightGreen")
	else
		lineColor = colorScheme:GetColor("black")
	end
	elLine:SetColor(lineColor)
	elCtrl:SetColor(cpColor)
end
function gui.PFMTimelineTangentControl:GetInControl()
	return self.m_inCtrl
end
function gui.PFMTimelineTangentControl:GetOutControl()
	return self.m_outCtrl
end
function gui.PFMTimelineTangentControl:UpdateInControl(newPos)
	self:CallCallbacks("OnInControlMoved", newPos)
end
function gui.PFMTimelineTangentControl:UpdateOutControl(newPos)
	self:CallCallbacks("OnOutControlMoved", newPos)
end
function gui.PFMTimelineTangentControl:OnUpdate()
	self:UpdateInOutLines(true, true)
end
function gui.PFMTimelineTangentControl:SetDataPoint(dp)
	self.m_dataPoint = dp
end
function gui.PFMTimelineTangentControl:UpdateInOutLines(updateIn, updateOut)
	if util.is_valid(self.m_dataPoint) == false then
		return
	end
	local pos = self:GetCenter()

	local curve = self.m_dataPoint:GetGraphCurve()

	local editorChannel = curve:GetEditorChannel()
	if editorChannel == nil then
		return
	end

	local editorGraphCurve = editorChannel:GetGraphCurve()
	local editorKeys = editorGraphCurve:GetKey(self.m_dataPoint:GetTypeComponentIndex())

	local keyIndex = self.m_dataPoint:GetKeyIndex()

	local graph = curve:GetTimelineGraph()
	local timeAxis = graph:GetTimeAxis()
	local dataAxis = graph:GetDataAxis()

	local basePos = self.m_dataPoint:GetCenter()
	if updateIn then
		local inTime = editorKeys:GetInTime(keyIndex)
		local inDelta = editorKeys:GetInDelta(keyIndex)

		inTime = timeAxis:GetAxis():ValueToXDelta(inTime)
		inDelta = -dataAxis:GetAxis():ValueToXDelta(inDelta)

		local inPos = basePos + Vector2(inTime, inDelta)
		self.m_inCtrl:SetPos(inPos)

		self.m_inLine:SetStartPos(inPos)
		self.m_inLine:SetEndPos(Vector2(pos.x, pos.y))
		self.m_inLine:SizeToContents()
	end

	if updateOut then
		local outTime = editorKeys:GetOutTime(keyIndex)
		local outDelta = editorKeys:GetOutDelta(keyIndex)

		outTime = timeAxis:GetAxis():ValueToXDelta(outTime)
		outDelta = -dataAxis:GetAxis():ValueToXDelta(outDelta)

		local outPos = basePos + Vector2(outTime, outDelta)
		self.m_outCtrl:SetPos(outPos)

		self.m_outLine:SetStartPos(outPos)
		self.m_outLine:SetEndPos(Vector2(pos.x, pos.y))
		self.m_outLine:SizeToContents()
	end
end
function gui.PFMTimelineTangentControl:OnRemove()
	util.remove({ self.m_inLine, self.m_outLine, self.m_inCtrl, self.m_outCtrl })
end
gui.register("WIPFMTimelineTangentControl", gui.PFMTimelineTangentControl)
