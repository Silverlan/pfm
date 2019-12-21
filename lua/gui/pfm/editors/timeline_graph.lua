--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/curve.lua")
include("/gui/pfm/treeview.lua")
include("/gui/pfm/grid.lua")

util.register_class("gui.PFMTimelineGraph",gui.Base)

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

	self.m_boneList = gui.create("WIPFMTreeView",self.m_scrollContainer,0,0,self.m_scrollContainer:GetWidth(),self.m_scrollContainer:GetHeight())
	self.m_boneList:SetSelectable(gui.Table.SELECTABLE_MODE_MULTI)

	self.m_graphs = {}
	self.m_timeRange = {0,0}
end
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
		v = fValueTranslator(v)
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
	graph:SetHorizontalRange(self.m_timeRange[1],self.m_timeRange[2])
	graph:SetVerticalRange(yRange[1],yRange[2])

	graph:BuildCurve(curveValues)
	graph:SetColor(colorCurve)
	table.insert(self.m_graphs,graph)
	return graph
end
function gui.PFMTimelineGraph:AddBoneTransform(layer,itemBone,name,color,fValueTranslator)
	local graph
	local item = itemBone:AddItem(name)
	item:AddCallback("OnSelected",function()
		if(util.is_valid(graph)) then graph:Remove() end
		graph = self:AddGraph(layer,color,fValueTranslator)
	end)
	item:AddCallback("OnDeselected",function()
		if(util.is_valid(graph)) then graph:Remove() end
	end)
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
function gui.PFMTimelineGraph:Setup(actor,channelClip)
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
				self:AddBoneTransform(layer,itemBone,label .. " X",Color.Red,function(v) return v.x end)
				--Color(227,90,90)
				self:AddBoneTransform(layer,itemBone,label .. " Y",Color.Lime,function(v) return v.y end)
				--Color(84,168,70)
				self:AddBoneTransform(layer,itemBone,label .. " Z",Color.Blue,function(v) return v.z end)
				--Color(96,127,193)
			end
		end
		if(boneRotChannel ~= nil) then
			local log = boneRotChannel:GetLog()
			local layer = log:GetLayers():FindByName("quaternion log")
			if(layer ~= nil) then
				local label = locale.get_text("rotation")
				self:AddBoneTransform(layer,itemBone,label .. " X",Color.Red,function(v) return v:ToEulerAngles().p end)
				self:AddBoneTransform(layer,itemBone,label .. " Y",Color.Lime,function(v) return v:ToEulerAngles().y end)
				self:AddBoneTransform(layer,itemBone,label .. " Z",Color.Blue,function(v) return v:ToEulerAngles().r end)
			end
		end
	end

	self.m_boneList:Update()
	self.m_boneList:SizeToContents()
	self.m_boneList:SetWidth(204)
end
gui.register("WIPFMTimelineGraph",gui.PFMTimelineGraph)
