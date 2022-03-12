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
include("/gui/selectionrect.lua")
include("/graph_axis.lua")
include("key.lua")

util.register_class("gui.CursorTracker",util.CallbackHandler)
function gui.CursorTracker:__init()
	util.CallbackHandler.__init(self)
	self.m_startPos = input.get_cursor_pos()
	self.m_curPos = self.m_startPos:Copy()
end

function gui.CursorTracker:GetTotalDeltaPosition() return self.m_curPos -self.m_startPos end

function gui.CursorTracker:Update()
	local pos = input.get_cursor_pos()
	local dt = pos -self.m_curPos
	if(dt.x == 0 and dt.y == 0) then return dt end
	self.m_curPos = pos
	self:CallCallbacks("OnCursorMoved",dt)
	return dt
end

----------------

util.register_class("gui.PFMTimelineDataPoint",gui.Base)
function gui.PFMTimelineDataPoint:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(4,4)
	local el = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_elPoint = el
	el:GetColorProperty():Link(self:GetColorProperty())

	self.m_selected = false
	self:SetMouseInputEnabled(true)
end
function gui.PFMTimelineDataPoint:SetGraphData(timelineCurve,valueIndex)
	self.m_graphData = {
		timelineCurve = timelineCurve,
		valueIndex = valueIndex
	}
end
function gui.PFMTimelineDataPoint:IsSelected() return self.m_selected end
function gui.PFMTimelineDataPoint:SetSelected(selected)
	if(selected == self.m_selected) then return end
	self.m_selected = selected
	self:SetColor(selected and Color.Red or Color.White)
	self:CallCallbacks("OnSelectionChanged",selected)
end
function gui.PFMTimelineDataPoint:OnThink()
	if(self.m_cursorTracker == nil) then return end
	local dt = self.m_cursorTracker:Update()
	if(dt.x == 0 and dt.y == 0) then return end
	local newPos = self.m_moveModeStartPos +self.m_cursorTracker:GetTotalDeltaPosition()

	local graphData = self.m_graphData
	local timelineCurve = graphData.timelineCurve
	local timelineGraph = timelineCurve:GetTimelineGraph()
	local curveData = timelineGraph:GetGraphCurve(timelineCurve:GetCurveIndex())
	local pm = pfm.get_project_manager()
	local animManager = pm:GetAnimationManager()
	local animClip = curveData.animClip
	local actor = animClip:GetActor()
	local targetPath = curveData.targetPath

	local newValue = timelineCurve:GetCurve():CoordinatesToValues(newPos.x +self:GetWidth() /2.0,newPos.y +self:GetHeight() /2.0)
	newValue = {newValue.x,newValue.y}
	newValue[1] = math.snap_to_grid(newValue[1],1.0 /pm:GetFrameRate())
	if(curveData.valueTranslator ~= nil) then newValue[2] = curveData.valueTranslator[2](newValue[2]) end
	animManager:UpdateChannelValueByIndex(actor,targetPath,graphData.valueIndex,newValue[1],newValue[2])
end
function gui.PFMTimelineDataPoint:IsMoveModeEnabled() return self.m_cursorTracker ~= nil end
function gui.PFMTimelineDataPoint:SetMoveModeEnabled(enabled)
	if(enabled) then
		self.m_cursorTracker = gui.CursorTracker()
		self.m_moveModeStartPos = self:GetPos()
		self:EnableThinking()
	else
		self.m_cursorTracker = nil
		self.m_moveModeStartPos = nil
		self:DisableThinking()
	end
end
gui.register("WIPFMTimelineDataPoint",gui.PFMTimelineDataPoint)

----------------

util.register_class("gui.PFMTimelineCurve",gui.Base)
function gui.PFMTimelineCurve:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,64)
	local curve = gui.create("WICurve",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_curve = curve

	self.m_dataPoints = {}

	curve:GetColorProperty():Link(self:GetColorProperty())
end
function gui.PFMTimelineCurve:GetTimelineGraph() return self.m_timelineGraph end
function gui.PFMTimelineCurve:SetTimelineGraph(graph) self.m_timelineGraph = graph end
function gui.PFMTimelineCurve:GetCurveIndex() return self.m_curveIndex end
function gui.PFMTimelineCurve:GetCurve() return self.m_curve end
function gui.PFMTimelineCurve:BuildCurve(curveValues,channel,curveIndex)
	self.m_channel = channel
	self.m_curveIndex = curveIndex
	self.m_curve:BuildCurve(curveValues)

	util.remove(self.m_dataPoints)
	self.m_dataPoints = {}
	for i,tp in ipairs(curveValues) do
		local el = gui.create("WIPFMTimelineDataPoint",self)
		el:SetGraphData(self,i -1)
		el:AddCallback("OnMouseEvent",function(wrapper,button,state,mods)
			if(self.m_timelineGraph:GetCursorMode() ~= gui.PFMTimelineGraph.CURSOR_MODE_SELECT) then return util.EVENT_REPLY_UNHANDLED end
			if(button == input.MOUSE_BUTTON_LEFT) then
				if(state == input.STATE_PRESS) then
					if(util.is_valid(self.m_selectedDataPoint)) then self.m_selectedDataPoint:SetSelected(false) end
					el:SetSelected(true)
					self.m_selectedDataPoint = el
				end
				return util.EVENT_REPLY_HANDLED
			end
			wrapper:StartEditMode(false)
		end)
		--[[el:AddCallback("OnSelectionChanged",function(el,selected)

		end)]]
		self.m_selectedDataPoint = el

		table.insert(self.m_dataPoints,el)
	end
	self:UpdateDataPoints()
end
function gui.PFMTimelineCurve:UpdateDataPoint(i)
	local el = self.m_dataPoints[i]
	if(el:IsValid() == false) then return end
	-- TODO: Apply value translator function if it was defined
	local t = self.m_channel:GetTime(i -1)
	local v = self.m_channel:GetValue(i -1)
	local valueTranslator = self:GetTimelineGraph():GetGraphCurve(self:GetCurveIndex()).valueTranslator
	if(valueTranslator ~= nil) then v = valueTranslator[1](v) end
	local pos = self.m_curve:ValueToUiCoordinates(t,v)
	el:SetPos(pos -el:GetSize() /2.0)
end
function gui.PFMTimelineCurve:UpdateDataPoints()
	if(self.m_channel == nil) then return end
	for i=1,#self.m_dataPoints do
		self:UpdateDataPoint(i)
	end
end
function gui.PFMTimelineCurve:GetDataPoint(idx) return self.m_dataPoints[idx +1] end
function gui.PFMTimelineCurve:GetDataPoints() return self.m_dataPoints end
function gui.PFMTimelineCurve:UpdateCurveValue(i,xVal,yVal)
	self.m_curve:UpdateCurveValue(i,xVal,yVal)
	self:UpdateDataPoints(i +1)
end
function gui.PFMTimelineCurve:SetHorizontalRange(...)
	self.m_curve:SetHorizontalRange(...)
	self:UpdateDataPoints()
end
function gui.PFMTimelineCurve:SetVerticalRange(...)
	self.m_curve:SetVerticalRange(...)
	self:UpdateDataPoints()
end
gui.register("WIPFMTimelineCurve",gui.PFMTimelineCurve)

----------------

util.register_class("gui.PFMTimelineGraph",gui.Base)

gui.PFMTimelineGraph.CURSOR_MODE_SELECT = 0
gui.PFMTimelineGraph.CURSOR_MODE_MOVE = 1
gui.PFMTimelineGraph.CURSOR_MODE_PAN = 2
gui.PFMTimelineGraph.CURSOR_MODE_SCALE = 3
gui.PFMTimelineGraph.CURSOR_MODE_ZOOM = 4
function gui.PFMTimelineGraph:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512,256)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(128,128,128))

	self.m_grid = gui.create("WIGrid",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)

	self.m_graphContainer = gui.create("WIBase",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	
	local listContainer = gui.create("WIRect",self,0,0,204,self:GetHeight(),0,0,0,1)
	listContainer:SetColor(Color(38,38,38))

	self.m_scrollContainer = gui.create("WIScrollContainer",listContainer,0,0,listContainer:GetWidth(),listContainer:GetHeight(),0,0,1,1)

	self.m_transformList = gui.create("WIPFMTreeView",self.m_scrollContainer,0,0,self.m_scrollContainer:GetWidth(),self.m_scrollContainer:GetHeight())
	self.m_transformList:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)

	self.m_keys = {}

	self.m_graphs = {}
	self.m_channelPathToGraphIndex = {}
	self.m_timeAxis = util.GraphAxis()
	self.m_dataAxis = util.GraphAxis()

	self:SetCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SELECT)
	gui.set_mouse_selection_enabled(self,true)

	local animManager = pfm.get_project_manager():GetAnimationManager()
	self.m_cbOnChannelValueChanged = animManager:AddCallback("OnChannelValueChanged",function(actor,anim,channel,udmChannel,idx,oldIdx)
		local i = self.m_channelPathToGraphIndex[udmChannel:GetTargetPath()]
		if(i == nil) then return end
		local graphData = self.m_graphs[i]
		if(graphData.curve:IsValid()) then
			if(udmChannel:GetValueCount() == graphData.numValues) then
				if(idx ~= oldIdx) then
					-- If the index has changed, we have to do a bunch of reshuffling
					local dp0 = graphData.curve.m_dataPoints[oldIdx +1]
					local dp1 = graphData.curve.m_dataPoints[idx +1]
					graphData.curve.m_dataPoints[oldIdx +1] = dp1
					graphData.curve.m_dataPoints[idx +1] = dp0

					local graphData0 = dp0.m_graphData
					local graphData1 = dp1.m_graphData
					dp0.m_graphData = graphData1
					dp1.m_graphData = graphData0
				end

				local function updateCurveValue(idx)
					local t = udmChannel:GetTime(idx)
					local v = udmChannel:GetValue(idx)

					if(graphData.valueTranslator ~= nil) then v = graphData.valueTranslator[1](v) end
					graphData.curve:UpdateCurveValue(idx,t,v)
				end
				updateCurveValue(idx)

				if(idx ~= oldIdx) then
					updateCurveValue(oldIdx)
					for i=1,#graphData.curve.m_dataPoints do
						graphData.curve:UpdateDataPoint(i)
					end
				end
			else
				-- Value has been added or removed; Complete graph update is required
				self:RebuildGraphCurve(i,udmChannel)
			end
		end
	end)
end
function gui.PFMTimelineGraph:OnRemove()
	util.remove(self.m_cbOnChannelValueChanged)
end
function gui.PFMTimelineGraph:OnMouseEvent(button,state,mods)
	local cursorMode = self:GetCursorMode()
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_MOVE) then
			local moveEnabled = (state == input.STATE_PRESS)
			for _,graphData in ipairs(self.m_graphs) do
				if(graphData.curve:IsValid()) then
					local dps = graphData.curve:GetDataPoints()
					for _,dp in ipairs(dps) do
						if(dp:IsValid() and dp:IsSelected()) then
							dp:SetMoveModeEnabled(moveEnabled)
						end
					end
				end
			end
		elseif(state == input.STATE_PRESS) then
			local timeAxis = self.m_timeline:GetTimeline():GetTimeAxis():GetAxis()
			local dataAxis = self.m_timeline:GetTimeline():GetDataAxis():GetAxis()
			self.m_cursorTracker = {
				tracker = gui.CursorTracker(),
				timeAxisStartOffset = timeAxis:GetStartOffset(),
				timeAxisZoomLevel = timeAxis:GetZoomLevel(),
				dataAxisStartOffset = dataAxis:GetStartOffset(),
				dataAxisZoomLevel = dataAxis:GetZoomLevel()
			}
			self:EnableThinking()

			if(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT) then
				if(util.is_valid(self.m_selectionRect) == false) then
					self.m_selectionRect = gui.create("WISelectionRect",self.m_graphContainer)
					self.m_selectionRect:SetPos(self.m_graphContainer:GetCursorPos())
				end
			end
		else
			if(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT) then
				if(util.is_valid(self.m_selectionRect)) then
					local isCtrlDown = input.get_key_state(input.KEY_LEFT_CONTROL) ~= input.STATE_RELEASE or
						input.get_key_state(input.KEY_RIGHT_CONTROL) ~= input.STATE_RELEASE
					local isAltDown = input.get_key_state(input.KEY_LEFT_ALT) ~= input.STATE_RELEASE or
						input.get_key_state(input.KEY_RIGHT_ALT) ~= input.STATE_RELEASE
					for _,graphData in ipairs(self.m_graphs) do
						if(graphData.curve:IsValid()) then
							local dps = graphData.curve:GetDataPoints()
							for _,dp in ipairs(dps) do
								if(self.m_selectionRect:IsElementInBounds(dp)) then
									if(isAltDown) then dp:SetSelected(false)
									else dp:SetSelected(true) end
								elseif(isCtrlDown == false and isAltDown == false) then dp:SetSelected(false) end
							end
						end
					end
					-- TODO: Select or deselect all points on curve if no individual points are within the select bounds, but the curve is
				end
			end

			self.m_cursorTracker = nil
			util.remove(self.m_selectionRect)
			self:DisableThinking()
		end
		return util.EVENT_REPLY_HANDLED
	end
	return util.EVENT_REPLY_UNHANDLED
end
function gui.PFMTimelineGraph:OnThink()
	if(self.m_cursorTracker == nil) then return end
	local trackerData = self.m_cursorTracker
	local tracker = trackerData.tracker
	local dt = tracker:Update()
	if(dt.x == 0 and dt.y == 0) then return end

	local dtPos = tracker:GetTotalDeltaPosition()
	local timeLine = self.m_timeline:GetTimeline()

	local cursorMode = self:GetCursorMode()
	if(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SELECT) then

	elseif(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_MOVE) then

	elseif(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_PAN) then
		timeLine:GetTimeAxis():GetAxis():SetStartOffset(trackerData.timeAxisStartOffset -timeLine:GetTimeAxis():GetAxis():XDeltaToValue(dtPos).x)
		timeLine:GetDataAxis():GetAxis():SetStartOffset(trackerData.dataAxisStartOffset +timeLine:GetDataAxis():GetAxis():XDeltaToValue(dtPos).y)
		timeLine:Update()
	elseif(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_SCALE) then
	elseif(cursorMode == gui.PFMTimelineGraph.CURSOR_MODE_ZOOM) then
		timeLine:GetTimeAxis():GetAxis():SetZoomLevel(trackerData.timeAxisZoomLevel +dtPos.x /10.0)
		timeLine:GetDataAxis():GetAxis():SetZoomLevel(trackerData.dataAxisZoomLevel +dtPos.y /10.0)
		timeLine:Update()
	end
end
function gui.PFMTimelineGraph:SetCursorMode(cursorMode) self.m_cursorMode = cursorMode end
function gui.PFMTimelineGraph:GetCursorMode() return self.m_cursorMode end
function gui.PFMTimelineGraph:SetTimeline(timeline) self.m_timeline = timeline end
function gui.PFMTimelineGraph:SetTimeAxis(timeAxis) self.m_timeAxis = timeAxis end
function gui.PFMTimelineGraph:SetDataAxis(dataAxis) self.m_dataAxis = dataAxis end
function gui.PFMTimelineGraph:GetTimeAxis() return self.m_timeAxis end
function gui.PFMTimelineGraph:GetDataAxis() return self.m_dataAxis end
function gui.PFMTimelineGraph:UpdateGraphCurveAxisRanges(i)
	local graphData = self.m_graphs[i]
	local graph = graphData.curve
	if(graph:IsValid() == false) then return end
	local timeAxis = self:GetTimeAxis():GetAxis()
	local timeRange = {timeAxis:GetStartOffset(),timeAxis:XOffsetToValue(self:GetRight())}
	graph:SetHorizontalRange(timeRange[1],timeRange[2])

	local dataAxis = self:GetDataAxis():GetAxis()
	local dataRange = {dataAxis:GetStartOffset(),dataAxis:XOffsetToValue(self:GetRight())}
	graph:SetVerticalRange(dataRange[1],dataRange[2])
end
function gui.PFMTimelineGraph:RebuildGraphCurve(i,channel)
	local times = channel:GetTimes()
	local values = channel:GetValues()

	local graphData = self.m_graphs[i]
	local curveValues = {}
	for i=1,#times do
		local t = times[i]
		local v = values[i]
		v = (graphData.valueTranslator ~= nil) and graphData.valueTranslator[1](v) or v
		table.insert(curveValues,{t,v})
	end
	graphData.curve:BuildCurve(curveValues,channel,i)
end
function gui.PFMTimelineGraph:RemoveGraphCurve(i)
	local graphData = self.m_graphs[i]
	util.remove(graphData.curve)
	self.m_channelPathToGraphIndex[graphData.targetPath] = nil
	while(#self.m_graphs > 0 and util.is_valid(self.m_graphs[#self.m_graphs].curve)) do
		table.remove(self.m_graphs,#self.m_graphs)
	end
end
function gui.PFMTimelineGraph:GetGraphCurve(i) return self.m_graphs[i] end
function gui.PFMTimelineGraph:AddGraph(animClip,channel,colorCurve,fValueTranslator)
	if(util.is_valid(self.m_graphContainer) == false) then return end

	local graph = gui.create("WIPFMTimelineCurve",self.m_graphContainer,0,0,self.m_graphContainer:GetWidth(),self.m_graphContainer:GetHeight(),0,0,1,1)
	graph:SetTimelineGraph(self)
	graph:SetColor(colorCurve)
	local targetPath = channel:GetTargetPath()
	table.insert(self.m_graphs,{
		animClip = animClip,
		curve = graph,
		valueTranslator = fValueTranslator,
		numValues = channel:GetValueCount(),
		targetPath = targetPath
	})
	self.m_channelPathToGraphIndex[targetPath] = #self.m_graphs

	local idx = #self.m_graphs
	self:UpdateGraphCurveAxisRanges(idx)
	self:RebuildGraphCurve(idx,channel)
	return graph,idx
end
function gui.PFMTimelineGraph:SetTimeRange(startTime,endTime,startOffset,zoomLevel)
	if(util.is_valid(self.m_grid)) then
		self.m_grid:SetStartOffset(startOffset)
		self.m_grid:SetZoomLevel(zoomLevel)
	end
	self.m_timeRange = {startTime,endTime}
	for _,graphData in ipairs(self.m_graphs) do
		local graph = graphData.curve
		if(graph:IsValid()) then
			graph:SetHorizontalRange(startTime,endTime)
		end
	end
end
function gui.PFMTimelineGraph:SetDataRange(startValue,endValue,startOffset,zoomLevel)
	self.m_dataRange = {startValue,endValue}
	for _,graphData in ipairs(self.m_graphs) do
		local graph = graphData.curve
		if(graph:IsValid()) then
			graph:SetVerticalRange(startValue,endValue)
		end
	end
end
function gui.PFMTimelineGraph:SetupControl(animClip,channel,item,color,fValueTranslator)
	local graph,graphIndex
	item:AddCallback("OnSelected",function()
		if(util.is_valid(graph)) then self:RemoveGraphCurve(graphIndex) end
		graph,graphIndex = self:AddGraph(animClip,channel,color,fValueTranslator)
	end)
	item:AddCallback("OnDeselected",function()
		if(util.is_valid(graph)) then self:RemoveGraphCurve(graphIndex) end
	end)
end
function gui.PFMTimelineGraph:AddKey(time,value)
	if(util.is_valid(self.m_timeline) == false) then return end
	local timeline = self.m_timeline:GetTimeline()
	timeline:AddBookmark(time)
	-- TODO: Add actual key!!
	--[[local key = gui.create("WIPFMGraphKey",self)
	self:GetTimeAxis():AttachElementToValue(key,time)
	self:GetDataAxis():AttachElementToValue(key,value)
	table.insert(self.m_keys,key)]]
end
function gui.PFMTimelineGraph:OnVisibilityChanged(visible)
	if(visible == false or util.is_valid(self.m_timeline) == false) then return end
	local timeline = self.m_timeline:GetTimeline()
	timeline:ClearBookmarks()
end
function gui.PFMTimelineGraph:AddControl(filmClip,actor,controlData,memberInfo)
	local track = filmClip:FindAnimationChannelTrack()
	if(track == nil) then return end
	local itemCtrl = self.m_transformList:AddItem(controlData.name)
	local function addChannel(channel,item,fValueTranslator)
		local log = channel:GetLog()
		local layers = log:GetLayers():GetTable()
		for _,layer in ipairs(layers) do
			local type = layer:GetValues():GetValueType()
			if(type == udm.TYPE_INT32) then
				-- TODO
			elseif(type == udm.TYPE_FLOAT) then
				self:SetupControl(layer,item,Color.Red,fValueTranslator)
			elseif(type == udm.TYPE_VECTOR3) then
				self:SetupControl(layer,item,Color.Red,fValueTranslator)
			elseif(type == udm.TYPE_QUATERNION) then
				self:SetupControl(layer,item,Color.Red,fValueTranslator)
			end
		end
	end
	if(udm.is_numeric_type(memberInfo.type)) then
		local animClip = track:FindActorAnimationClip(actor)
		if(animClip ~= nil) then
			local channel = animClip:FindChannel(controlData.path)
			if(channel ~= nil) then
				local valueTranslator
				if(memberInfo.type == udm.TYPE_BOOLEAN) then
					valueTranslator = {
						function(v) return v and 1.0 or 0.0 end,
						function(v) return (v >= 0.5) and true or false end
					}
				end
				self:SetupControl(animClip,channel,itemCtrl,Color.Red,valueTranslator)
			end
		end

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
	end
	if(controlData.type == "flexController") then
		if(controlData.dualChannel ~= true) then
			local property = controlData.getProperty(component)
			local channel = track:FindFlexControllerChannel(property)
			if(channel ~= nil) then
				addChannel(channel,itemCtrl)

				local log = channel:GetLog()
				local layers = log:GetLayers()
				local layer = layers:Get(1) -- TODO: Which layer(s) are the bookmarks refering to?
				if(layer ~= nil) then
					local bookmarks = log:GetBookmarks()
					for _,bookmark in ipairs(bookmarks:GetTable()) do
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
			if(leftChannel ~= nil) then addChannel(leftChannel,itemCtrl:AddItem(locale.get_text("left"))) end

			local rightProperty = controlData.getRightProperty(component)
			local rightChannel = track:FindFlexControllerChannel(rightProperty)
			if(rightChannel ~= nil) then addChannel(rightChannel,itemCtrl:AddItem(locale.get_text("right"))) end
		end
	elseif(controlData.type == "bone") then
		local channel = track:FindBoneChannel(controlData.bone:GetTransform())
		-- TODO: Localization
		if(channel ~= nil) then
			addChannel(channel,itemCtrl:AddItem("Position X"),function(v) return v.x end)
			addChannel(channel,itemCtrl:AddItem("Position Y"),function(v) return v.y end)
			addChannel(channel,itemCtrl:AddItem("Position Z"),function(v) return v.z end)

			addChannel(channel,itemCtrl:AddItem("Rotation X"),function(v) return v:ToEulerAngles().p end)
			addChannel(channel,itemCtrl:AddItem("Rotation Y"),function(v) return v:ToEulerAngles().y end)
			addChannel(channel,itemCtrl:AddItem("Rotation Z"),function(v) return v:ToEulerAngles().r end)
		end
	end

	itemCtrl:AddCallback("OnSelected",function(elCtrl)
		for _,el in ipairs(elCtrl:GetItems()) do
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
gui.register("WIPFMTimelineGraph",gui.PFMTimelineGraph)
