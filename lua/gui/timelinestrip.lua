--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("basetimelinegrid.lua")
include("/shaders/pfm/pfm_timeline.lua")
include("/pfm/fonts.lua")
include("/graph_axis.lua")

util.register_class("gui.TimelineStrip",gui.BaseTimelineGrid)

function gui.TimelineStrip:__init()
	gui.BaseTimelineGrid.__init(self)
end
function gui.TimelineStrip:OnInitialize()
	gui.BaseTimelineGrid.OnInitialize(self)

	self.m_line = gui.create("WIRect",self,0,0,self:GetWidth(),1,0,0,1,0)
	self.m_line:GetColorProperty():Link(self:GetColorProperty())
	self.m_axis = util.GraphAxis()

	self:SetColor(Color.Black)
	self:SetFlipped(false)
	self:SetShader("pfm_timeline")
end
function gui.TimelineStrip:SetAxis(axis) self.m_axis = axis end
function gui.TimelineStrip:GetAxis() return self.m_axis end
function gui.TimelineStrip:SetFlipped(flipped)
	if(flipped) then
		self:SetYMultiplier(1.0)
		if(util.is_valid(self.m_line)) then
			self.m_line:SetY(0)
			self.m_line:SetAnchor(0,0,1,0)
		end
	else
		self:SetYMultiplier(-1.0)
		if(util.is_valid(self.m_line)) then
			self.m_line:SetY(self:GetBottom() -1)
			self.m_line:SetAnchor(0,1,1,1)
		end
	end
end
gui.register("WITimelineStrip",gui.TimelineStrip)

-------------

util.register_class("gui.LabelledTimelineStrip",gui.Base)

function gui.LabelledTimelineStrip:__init()
	gui.Base.__init(self)
end
function gui.LabelledTimelineStrip:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,16)
	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(80,80,80))
	
	self.m_strip = gui.create("WITimelineStrip",self,0,0,self:GetWidth(),6)
	self.m_strip:AddCallback("OnTimelinePropertiesChanged",function()
		self:CallCallbacks("OnTimelinePropertiesChanged")
	end)
	self.m_textElements = {}

	self:SetFlipped(false)
end
function gui.LabelledTimelineStrip:OnSizeChanged(w,h)
	self:ScheduleUpdate()
end
function gui.LabelledTimelineStrip:SetFlipped(flipped)
	self.m_flipped = flipped
	if(util.is_valid(self.m_strip)) then
		self.m_strip:SetFlipped(flipped)
		if(flipped) then self.m_strip:SetY(0)
		else self.m_strip:SetY(self:GetHeight() -self.m_strip:GetHeight()) end
	end
	for _,el in ipairs(self.m_textElements) do
		if(el:IsValid()) then
			el:SetY(self:GetLabelYPos(el))
		end
	end
end
function gui.LabelledTimelineStrip:GetLabelYPos(el)
	if(self.m_flipped == true) then return 5 end
	return self:GetHeight() -el:GetHeight() -7
end
function gui.LabelledTimelineStrip:SetAxis(axis)
	if(util.is_valid(self.m_strip) == false) then return end
	self.m_strip:SetAxis(axis)
end
function gui.LabelledTimelineStrip:GetAxis()
	if(util.is_valid(self.m_strip) == false) then return end
	return self.m_strip:GetAxis()
end
function gui.LabelledTimelineStrip:OnUpdate()
	if(util.is_valid(self.m_strip) == false) then return end
	local axis = self:GetAxis()
	local stridePerUnit = axis:GetStridePerUnit()
	if(stridePerUnit == 0.0) then
		error("Illegal timeline stride: ",stridePerUnit)
	end
	-- We have to move the strip around if the start offset isn't a whole number, so we
	-- just add a stride to its width
	self.m_strip:SetWidth(self:GetWidth() +stridePerUnit *2)

	local numTextElements = math.ceil(self:GetWidth() /stridePerUnit) +1
	local multiplier = axis:GetZoomLevelMultiplier()
	local startOffset = axis:GetStartOffset() /multiplier
	local startIndex = math.floor(startOffset)
	local xStartOffset = (startIndex -startOffset) *stridePerUnit
	self.m_strip:SetX(-((startOffset *stridePerUnit) %stridePerUnit))
	self.m_strip:Update()

	if(numTextElements > 0) then
		for i=0,(numTextElements -1) do
			local pText = self.m_textElements[i +1]
			if(util.is_valid(pText) == false) then
				pText = gui.create("WIText",self)
				pText:SetFont("pfm_small")
				pText:SetColor(Color.Black)

				self.m_textElements[i +1] = pText
			end
			pText:SetVisible(true)
			pText:SetText(tostring((startIndex +i) *multiplier))
			pText:SizeToContents()
			pText:SetPos(xStartOffset +i *stridePerUnit -pText:GetWidth() *0.5,self:GetLabelYPos(pText))
		end
	end
	if((numTextElements +1) <= #self.m_textElements) then
		for i=numTextElements +1,#self.m_textElements do
			local el = self.m_textElements[i]
			if(el:IsValid()) then el:SetVisible(false) end
		end
	end
end
gui.register("WILabelledTimelineStrip",gui.LabelledTimelineStrip)
