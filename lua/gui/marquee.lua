--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/gui/hbox.lua")

util.register_class("gui.Marquee",gui.Base)

gui.get_delta_time = function()
	return time.frame_time()
end

function gui.Marquee:__init()
	gui.Base.__init(self)
end
function gui.Marquee:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(256,64)

	self.m_currentOffset = 0
	self.m_elementQueue = {}
	self:EnableThinking()
	self:SetMoveSpeed(100.0)
end
function gui.Marquee:OnThink()
	local moveSpeed = self:GetMoveSpeed()
	local dt = gui.get_delta_time()
	self:Move(moveSpeed *dt)
end
function gui.Marquee:AddElement(el)
	table.insert(self.m_elementQueue,el)
end
function gui.Marquee:SetMoveSpeed(speed) self.m_moveSpeed = speed end
function gui.Marquee:GetMoveSpeed() return self.m_moveSpeed end
function gui.Marquee:Move(offset)
	self.m_currentOffset = self.m_currentOffset +offset

	local w = self:GetWidth()
	local totalElementWidth = 0
	local firstEl
	while(#self.m_elementQueue > 0) do
		local el = self.m_elementQueue[#self.m_elementQueue]
		if(el == firstEl) then break end -- Prevent infinite recursion
		if(el:IsValid() == false) then
			table.remove(self.m_elementQueue,#self.m_elementQueue)
		else
			firstEl = firstEl or el
			if(el:GetLeft() > w) then
				table.remove(self.m_elementQueue,#self.m_elementQueue)
				table.insert(self.m_elementQueue,1)
			end
		end
	end
	for _,el in ipairs(self.m_elementQueue) do
		if(el:IsValid()) then
			totalElementWidth = totalElementWidth +el:GetWidth()
		end
	end
	
	--[[local x = self.m_currentOffset
	local w = self:GetWidth()
	for _,child in ipairs(self:GetChildren()) do
		x = x %w
		child:SetX(x)
		x = child:GetRight()
	end]]
end
function gui.Marquee:MoveLeft() self:Move(-1) end
function gui.Marquee:MoveRight() self:Move(1) end
gui.register("WIMarquee",gui.Marquee)

----------------

util.register_class("gui.Ticker",gui.Base)

function gui.Ticker:__init()
	gui.Base.__init(self)
end
function gui.Ticker:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(256,64)

	self.m_text = gui.create("WIText",self)
	self.m_text:AddStyleClass("input_field_text")
	--self:SetAutoSizeToContents(true)
	self:EnableThinking()

	self:SetText("")
	self:SetTickTime(0.4)
	self.m_tCurTickTime = self:GetTickTime()
	self.m_tickForward = false
end
function gui.Ticker:SetTickTime(t) self.m_tickTime = t end
function gui.Ticker:GetTickTime() return self.m_tickTime end
function gui.Ticker:SetText(text)
	self.m_displayText = text

	self.m_text:SetText(text)
	self.m_text:SizeToContents()
end
function gui.Ticker:MoveDisplayText()
	if(#self.m_displayText == 0) then return end
	if(self.m_tickForward) then
		local c = self.m_displayText:sub(#self.m_displayText)
		self.m_displayText = c .. self.m_displayText:sub(1,#self.m_displayText -1)
	else
		local c = self.m_displayText:sub(1,1)
		self.m_displayText = self.m_displayText:sub(2) .. c
	end

	self.m_text:SetText(self.m_displayText)
	self.m_text:SizeToContents()
	self.m_text:CenterToParentY()
end
function gui.Ticker:OnThink()
	self.m_tCurTickTime = self.m_tCurTickTime -gui.get_delta_time()
	if(self.m_tCurTickTime > 0) then return end
	self:MoveDisplayText()
	self.m_tCurTickTime = self.m_tCurTickTime +self:GetTickTime()
end
gui.register("WITicker",gui.Ticker)
