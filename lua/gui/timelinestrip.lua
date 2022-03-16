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
function gui.TimelineStrip:RebuildRenderCommandBuffer()
	if(self.m_shader == nil) then return end
	local pcb = prosper.PreparedCommandBuffer()
	if(self.m_shader:Record(pcb,self:GetLineCount(),self:GetAxis():GetStrideXTest(self:GetPrimAxisExtents(self)) *self:GetAxis():GetZoomLevelMultiplier(),self:GetColor(),self.m_yMultiplier,self:IsHorizontal()) == false) then pcb = nil end
	self:SetRenderCommandBuffer(pcb)
end
function gui.TimelineStrip:SetAxis(axis) self.m_axis = axis end
function gui.TimelineStrip:GetAxis() return self.m_axis end
function gui.TimelineStrip:SetHorizontal(horizontal)
	gui.BaseTimelineGrid.SetHorizontal(self,horizontal)
	if(util.is_valid(self.m_line) == false) then return end
	self.m_line:ClearAnchor()
	self.m_line:SetPos(0,0)
	if(not horizontal) then
		self.m_line:SetSize(1,self:GetHeight())
		self.m_line:SetAnchor(0,0,0,1)
	else
		self.m_line:SetSize(self:GetWidth(),1)
		self.m_line:SetAnchor(0,0,1,0)
	end
end
function gui.TimelineStrip:SetFlipped(flipped)
	if(flipped) then
		self:SetYMultiplier(1.0)
		if(util.is_valid(self.m_line)) then
			if(self:IsVertical()) then
				self.m_line:SetX(0)
				self.m_line:SetAnchor(0,0,0,1)
			else
				self.m_line:SetY(0)
				self.m_line:SetAnchor(0,0,1,0)
			end
		end
	else
		self:SetYMultiplier(-1.0)
		if(util.is_valid(self.m_line)) then
			if(self:IsVertical()) then
				self.m_line:SetX(self:GetRight() -1)
				self.m_line:SetAnchor(1,0,1,1)
			else
				self.m_line:SetY(self:GetBottom() -1)
				self.m_line:SetAnchor(0,1,1,1)
			end
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
function gui.LabelledTimelineStrip:GetTimeLineStrip() return self.m_strip end
function gui.LabelledTimelineStrip:OnSizeChanged(w,h)
	self:ScheduleUpdate()
end
function gui.LabelledTimelineStrip:IsHorizontal() return self.m_strip:IsHorizontal() end
function gui.LabelledTimelineStrip:IsVertical() return self.m_strip:IsVertical() end
function gui.LabelledTimelineStrip:SetHorizontal(horizontal)
	self.m_strip:SetHorizontal(horizontal)
	self:SetPrimAxisExtents(self.m_strip,self:GetPrimAxisExtents(self))
	self:SetSecAxisExtents(self.m_strip,6)
end
function gui.LabelledTimelineStrip:SetFlipped(flipped)
	self.m_flipped = flipped
	if(util.is_valid(self.m_strip)) then
		self.m_strip:SetFlipped(flipped)
		self:SetPrimAxisOffset(self.m_strip,0)
		if(flipped) then self:SetSecAxisOffset(self.m_strip,0)
		else self:SetSecAxisOffset(self.m_strip,self:GetSecAxisExtents(self) -self:GetSecAxisExtents(self.m_strip)) end
	end
	for _,el in ipairs(self.m_textElements) do
		if(el:IsValid()) then
			self:SetSecAxisOffset(el,self:GetLabelYPos(el))
		end
	end
end
function gui.LabelledTimelineStrip:GetLabelYPos(el)
	if(self.m_flipped == true) then return 5 end
	return self:GetSecAxisExtents(self) -self:GetSecAxisExtents(el) -7
end
function gui.LabelledTimelineStrip:SetAxis(axis)
	if(util.is_valid(self.m_strip) == false) then return end
	self.m_strip:SetAxis(axis)
end
function gui.LabelledTimelineStrip:GetAxis()
	if(util.is_valid(self.m_strip) == false) then return end
	return self.m_strip:GetAxis()
end
function gui.LabelledTimelineStrip:SetDataAxisInverted(inverted) self.m_dataAxisInverted = inverted end
function gui.LabelledTimelineStrip:IsDataAxisInverted() return self.m_dataAxisInverted or false end
function gui.LabelledTimelineStrip:OnUpdate()
	if(util.is_valid(self.m_strip) == false) then return end
	local axis = self:GetAxis()
	local stridePerUnit = axis:GetStridePerUnit()
	if(stridePerUnit == 0.0) then
		error("Illegal timeline stride: ",stridePerUnit)
	end
	-- We have to move the strip around if the start offset isn't a whole number, so we
	-- just add a stride to its width
	local multiplier = axis:GetZoomLevelMultiplier()
	self:SetPrimAxisExtents(self.m_strip,self:GetPrimAxisExtents(self) +(stridePerUnit *multiplier) *2)

	local numTextElements = math.ceil(self:GetPrimAxisExtents(self) /stridePerUnit /multiplier) +1
	local startOffset = axis:GetStartOffset()
	local startIndex = math.floor(startOffset /multiplier)
	local xStartOffset = (startIndex *multiplier -startOffset) *stridePerUnit
	self:SetPrimAxisOffset(self.m_strip,-((startOffset *stridePerUnit) %(stridePerUnit *multiplier)))
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
			local offset = xStartOffset +i *stridePerUnit *multiplier
			local textOffset = self:GetPrimAxisExtents(pText) *0.5
			if(self:IsDataAxisInverted()) then
				offset = offset +textOffset
				offset = self:GetPrimAxisExtents(self) -offset
			else
				offset = offset -textOffset
			end
			self:SetPrimAxisOffset(pText,offset)
			self:SetSecAxisOffset(pText,self:GetLabelYPos(pText))
		end
	end
	if((numTextElements +1) <= #self.m_textElements) then
		for i=numTextElements +1,#self.m_textElements do
			local el = self.m_textElements[i]
			if(el:IsValid()) then el:SetVisible(false) end
		end
	end

	if(self.m_debugMarkers ~= nil) then
		for _,dbgMarker in ipairs(self.m_debugMarkers) do
			local el = dbgMarker[1]
			local v = dbgMarker[2]
			local offset = axis:ValueToXOffset(v)
			if(self:IsDataAxisInverted()) then offset = self:GetHeight() -offset end
			self:SetSecAxisExtents(el,10000)
			self:SetPrimAxisExtents(el,1)
			self:SetPrimAxisOffset(el,offset)
		end
	end
end
function gui.LabelledTimelineStrip:AddDebugMarkers()
	if(self.m_debugMarkers ~= nil) then return end
	self.m_debugMarkers = {}
	for _,v in ipairs({0,-1,1}) do
		local el = gui.create("WIRect",self)
		el:SetColor(Color.Red)
		table.insert(self.m_debugMarkers,{el,v})
	end
end
function gui.LabelledTimelineStrip:SetPrimAxisExtents(...) return self.m_strip:SetPrimAxisExtents(...) end
function gui.LabelledTimelineStrip:GetPrimAxisExtents(...) return self.m_strip:GetPrimAxisExtents(...) end
function gui.LabelledTimelineStrip:SetSecAxisExtents(...) return self.m_strip:SetSecAxisExtents(...) end
function gui.LabelledTimelineStrip:GetSecAxisExtents(...) return self.m_strip:GetSecAxisExtents(...) end
function gui.LabelledTimelineStrip:SetPrimAxisOffset(...) return self.m_strip:SetPrimAxisOffset(...) end
function gui.LabelledTimelineStrip:GetPrimAxisOffset(...) return self.m_strip:GetPrimAxisOffset(...) end
function gui.LabelledTimelineStrip:SetSecAxisOffset(...) return self.m_strip:SetSecAxisOffset(...) end
function gui.LabelledTimelineStrip:GetSecAxisOffset(...) return self.m_strip:GetSecAxisOffset(...) end
gui.register("WILabelledTimelineStrip",gui.LabelledTimelineStrip)
