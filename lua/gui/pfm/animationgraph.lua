--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/curve.lua")

util.register_class("gui.PFMAnimationGraph",gui.Base)

function gui.PFMAnimationGraph:__init()
	gui.Base.__init(self)
end
function gui.PFMAnimationGraph:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(512,256)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(128,128,128))

	local listContainer = gui.create("WIRect",self,0,0,204,self:GetHeight(),0,0,0,1)
	listContainer:SetColor(Color(38,38,38))

	local scrollContainer = gui.create("WIScrollContainer",listContainer,0,0,listContainer:GetWidth(),listContainer:GetHeight(),0,0,1,1)

	self.m_boneList = gui.create("WITreeList",scrollContainer,0,0,scrollContainer:GetWidth(),scrollContainer:GetHeight(),0,0,1,0)
	self.m_boneList:SetSelectableMode(gui.Table.SELECTABLE_MODE_MULTI)

	self.m_graph = gui.create("WICurve",self,scrollContainer:GetRight(),0,self:GetWidth() -scrollContainer:GetRight(),self:GetHeight(),0,0,1,1)
end
function gui.PFMAnimationGraph:SetupGraph(layer,colorCurve,fValueTranslator)
	if(util.is_valid(self.m_graph) == false) then return end

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

	local xRange = {3.3,5.9}
	if(minVal == math.huge) then
		minVal = 0.0
		maxVal = 0.0
	end
	local yRange = {minVal,maxVal}

	self.m_graph:SetHorizontalRange(xRange[1],xRange[2])
	self.m_graph:SetVerticalRange(yRange[1],yRange[2])

	self.m_graph:BuildCurve(curveValues)
	self.m_graph:SetColor(colorCurve)
end
function gui.PFMAnimationGraph:Setup(actor,channelClip)
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

		local itemBone = self.m_boneList:AddItem(bone:GetName(),function(elTree)

		end)
		if(bonePosChannel ~= nil) then
			local log = bonePosChannel:GetLog()
			local layer = log:GetLayers():FindByName("vector3 log")
			if(layer ~= nil) then
				itemBone:AddItem("Position X"):AddCallback("OnSelected",function()
					self:SetupGraph(layer,Color.Red,function(v) return v.x end)
				end)
				--Color(227,90,90)
				itemBone:AddItem("Position Y"):AddCallback("OnSelected",function()
					self:SetupGraph(layer,Color.Lime,function(v) return v.y end)
				end)
				--Color(84,168,70)
				itemBone:AddItem("Position Z"):AddCallback("OnSelected",function()
					self:SetupGraph(layer,Color.Blue,function(v) return v.z end)
				end)
				--Color(96,127,193)
			end
		end
		if(boneRotChannel ~= nil) then
			local log = boneRotChannel:GetLog()
			local layer = log:GetLayers():FindByName("quaternion log")
			if(layer ~= nil) then
				itemBone:AddItem("Rotation X"):AddCallback("OnSelected",function()
					self:SetupGraph(layer,Color.Red,function(v) return v:ToEulerAngles().p end)
				end)
				itemBone:AddItem("Rotation Y"):AddCallback("OnSelected",function()
					self:SetupGraph(layer,Color.Lime,function(v) return v:ToEulerAngles().y end)
				end)
				itemBone:AddItem("Rotation Z"):AddCallback("OnSelected",function()
					self:SetupGraph(layer,Color.Blue,function(v) return v:ToEulerAngles().r end)
				end)
			end
		end
	end

	self.m_boneList:Update()
	self.m_boneList:SizeToContents()
	self.m_boneList:SetWidth(204)
end
gui.register("WIPFMAnimationGraph",gui.PFMAnimationGraph)
