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
include("/graph_axis.lua")
include("key.lua")

util.register_class("gui.PFMTimelineGraph",gui.Base)

gui.PFMTimelineGraph.CURSOR_MODE_SELECT = 0
gui.PFMTimelineGraph.CURSOR_MODE_MOVE = 1
gui.PFMTimelineGraph.CURSOR_MODE_PAN = 2
gui.PFMTimelineGraph.CURSOR_MODE_SCALE = 3
gui.PFMTimelineGraph.CURSOR_MODE_ZOOM = 4
function gui.PFMTimelineGraph:__init()
	gui.Base.__init(self)
end
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
	self.m_timeAxis = util.GraphAxis()
	self.m_dataAxis = util.GraphAxis()

	self:SetCursorMode(gui.PFMTimelineGraph.CURSOR_MODE_SELECT)
	gui.set_mouse_selection_enabled(self,true)
end
function gui.PFMTimelineGraph:SetCursorMode(cursorMode) self.m_cursorMode = cursorMode end
function gui.PFMTimelineGraph:GetCursorMode() return self.m_cursorMode end
function gui.PFMTimelineGraph:SetTimeline(timeline) self.m_timeline = timeline end
function gui.PFMTimelineGraph:SetTimeAxis(timeAxis) self.m_timeAxis = timeAxis end
function gui.PFMTimelineGraph:SetDataAxis(dataAxis) self.m_dataAxis = dataAxis end
function gui.PFMTimelineGraph:GetTimeAxis() return self.m_timeAxis end
function gui.PFMTimelineGraph:GetDataAxis() return self.m_dataAxis end
function gui.PFMTimelineGraph:AddGraph(layer,colorCurve,fValueTranslator)
	if(util.is_valid(self.m_graphContainer) == false) then return end
	local times = layer:GetTimes()
	local values = layer:GetValues()

	local curveValues = {}
	local minVal = math.huge
	local maxVal = -math.huge
	for i=1,#times do
		local t = times:Get(i)
		local v = values:Get(i)
		v = (fValueTranslator ~= nil) and fValueTranslator(v) or v
		minVal = math.min(minVal,v)
		maxVal = math.max(maxVal,v)
		table.insert(curveValues,{t,v})
	end

	if(minVal == math.huge) then
		minVal = 0.0
		maxVal = 0.0
	end
	local yRange = {minVal,maxVal}

	local graph = gui.create("WICurve",self.m_graphContainer,0,0,self.m_graphContainer:GetWidth(),self.m_graphContainer:GetHeight(),0,0,1,1)
	
	local timeAxis = self:GetTimeAxis():GetAxis()
	local timeRange = {timeAxis:GetStartOffset(),timeAxis:XOffsetToValue(self:GetRight())}
	graph:SetHorizontalRange(timeRange[1],timeRange[2])

	local dataAxis = self:GetDataAxis():GetAxis()
	local dataRange = {dataAxis:GetStartOffset(),dataAxis:XOffsetToValue(self:GetRight())}
	graph:SetVerticalRange(dataRange[1],dataRange[2])

	graph:BuildCurve(curveValues)
	graph:SetColor(colorCurve)
	table.insert(self.m_graphs,graph)
	return graph
end
function gui.PFMTimelineGraph:SetTimeRange(startTime,endTime,startOffset,zoomLevel)
	if(util.is_valid(self.m_grid)) then
		self.m_grid:SetStartOffset(startOffset)
		self.m_grid:SetZoomLevel(zoomLevel)
	end
	self.m_timeRange = {startTime,endTime}
	for _,graph in ipairs(self.m_graphs) do
		if(graph:IsValid()) then
			graph:SetHorizontalRange(startTime,endTime)
		end
	end
end
function gui.PFMTimelineGraph:SetupControl(layer,item,color,fValueTranslator)
	local graph
	item:AddCallback("OnSelected",function()
		if(util.is_valid(graph)) then graph:Remove() end
		graph = self:AddGraph(layer,color,fValueTranslator)
	end)
	item:AddCallback("OnDeselected",function()
		if(util.is_valid(graph)) then graph:Remove() end
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
function gui.PFMTimelineGraph:AddControl(filmClip,controlData)
	local track = filmClip:FindAnimationChannelTrack()
	local itemCtrl = self.m_transformList:AddItem(controlData.name)
	local function addChannel(channel,item,fValueTranslator)
		local log = channel:GetLog()
		local layers = log:GetLayers():GetTable()
		for _,layer in ipairs(layers) do
			local type = layer:GetValues():GetValueType()
			if(type == util.VAR_TYPE_INT32) then
				-- TODO
			elseif(type == util.VAR_TYPE_FLOAT) then
				self:SetupControl(layer,item,Color.Red,fValueTranslator)
			elseif(type == util.VAR_TYPE_VECTOR) then
				self:SetupControl(layer,item,Color.Red,fValueTranslator)
			elseif(type == util.VAR_TYPE_QUATERNION) then
				self:SetupControl(layer,item,Color.Red,fValueTranslator)
			end
		end
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
