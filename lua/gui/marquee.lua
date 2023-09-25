--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")
include("/gui/hbox.lua")

util.register_class("gui.Marquee", gui.Base)

gui.get_delta_time = function()
	return time.frame_time()
end

function gui.Marquee:__init()
	gui.Base.__init(self)
end
function gui.Marquee:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(256, 64)

	self.m_contents = gui.create("WIBase", self)

	self.m_currentOffset = 0
	self.m_lastMove = time.real_time()
	self.m_elements = {}
	self:EnableThinking()
	self:SetMoveSpeed(100.0)
end
function gui.Marquee:OnThink()
	local dt = time.real_time() - self.m_lastMove
	local stepDt = 0.2
	if dt < stepDt then
		return
	end
	dt = stepDt
	self.m_lastMove = time.real_time()

	local moveSpeed = self:GetMoveSpeed()
	self:Move(moveSpeed * dt)
end
function gui.Marquee:AddElement(el)
	el:SetParent(self.m_contents)
	local prevElement = self.m_elements[#self.m_elements]
	local offset = util.is_valid(prevElement) and prevElement:GetRight() or 0
	el:SetX(offset)
	table.insert(self.m_elements, el)
end
function gui.Marquee:Clear()
	util.remove(self.m_elements)
	self.m_elements = {}
end
function gui.Marquee:OnUpdate()
	self.m_contents:SizeToContents()
	self.m_contents:SetHeight(self:GetHeight())
end
function gui.Marquee:SetMoveSpeed(speed)
	self.m_moveSpeed = speed
end
function gui.Marquee:GetMoveSpeed()
	return self.m_moveSpeed
end
function gui.Marquee:GetElements()
	return self.m_elements
end
function gui.Marquee:Reset()
	self.m_contents:SetX(0)
end
function gui.Marquee:Rearrange()
	local offset = 0
	for _, el in ipairs(self.m_elements) do
		if el:IsValid() then
			el:SetX(offset)
			offset = offset + el:GetWidth()
		end
	end
end
function gui.Marquee:Move(offset)
	if #self.m_elements == 0 then
		return
	end
	self.m_currentOffset = self.m_currentOffset + offset

	local w = self:GetWidth()
	local totalElementWidth = 0
	local firstEl
	self.m_contents:SetX(self.m_contents:GetX() + offset)

	if offset < 0 then
		local veryFirstElement
		while true do
			local elFirst = self.m_elements[1]
			if veryFirstElement == nil then
				veryFirstElement = elFirst
			elseif util.is_same_object(elFirst, veryFirstElement) then
				-- Prevent infinite loop
				break
			end
			local x = self.m_contents:GetX() + elFirst:GetX()
			if x + elFirst:GetWidth() <= 0 then
				table.remove(self.m_elements, 1)
				table.insert(self.m_elements, elFirst)

				self:Rearrange()
				self.m_contents:SetX(self.m_contents:GetX() + elFirst:GetWidth())
			else
				break
			end
		end
	else
		local veryLastElement
		while true do
			local elLast = self.m_elements[#self.m_elements]
			if veryLastElement == nil then
				veryLastElement = elLast
			elseif util.is_same_object(elLast, veryLastElement) then
				-- Prevent infinite loop
				break
			end
			local x = self.m_contents:GetX() + elLast:GetX()
			if x >= self:GetWidth() then
				table.remove(self.m_elements, #self.m_elements)
				table.insert(self.m_elements, 1, elLast)

				self:Rearrange()
				self.m_contents:SetX(self.m_contents:GetX() - elLast:GetWidth())
			else
				break
			end
		end
	end
end
function gui.Marquee:MoveLeft()
	self:Move(-1)
end
function gui.Marquee:MoveRight()
	self:Move(1)
end
gui.register("WIMarquee", gui.Marquee)

----------------

util.register_class("gui.Ticker", gui.Base)

function gui.Ticker:__init()
	gui.Base.__init(self)
end
function gui.Ticker:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(256, 64)

	self.m_text = gui.create("WIText", self)
	self.m_text:AddStyleClass("input_field_text")
	--self:SetAutoSizeToContents(true)
	self:EnableThinking()

	self:SetText("")
	self:SetTickTime(0.4)
	self.m_tCurTickTime = self:GetTickTime()
	self.m_tickForward = false
end
function gui.Ticker:SetTickTime(t)
	self.m_tickTime = t
end
function gui.Ticker:GetTickTime()
	return self.m_tickTime
end
function gui.Ticker:SetText(text)
	self.m_displayText = text

	self.m_text:SetText(text)
	self.m_text:SizeToContents()
end
function gui.Ticker:MoveDisplayText()
	if #self.m_displayText == 0 then
		return
	end
	if self.m_tickForward then
		local c = self.m_displayText:sub(#self.m_displayText)
		self.m_displayText = c .. self.m_displayText:sub(1, #self.m_displayText - 1)
	else
		local c = self.m_displayText:sub(1, 1)
		self.m_displayText = self.m_displayText:sub(2) .. c
	end

	self.m_text:SetText(self.m_displayText)
	self.m_text:SizeToContents()
	self.m_text:CenterToParentY()
end
function gui.Ticker:OnThink()
	self.m_tCurTickTime = self.m_tCurTickTime - gui.get_delta_time()
	if self.m_tCurTickTime > 0 then
		return
	end
	self:MoveDisplayText()
	self.m_tCurTickTime = self.m_tCurTickTime + self:GetTickTime()
end
gui.register("WITicker", gui.Ticker)
