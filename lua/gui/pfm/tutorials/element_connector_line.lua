--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.ElementConnectorLine",gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	local l0 = gui.create("WILine",self)
	local l1 = gui.create("WILine",self)
	local l2 = gui.create("WILine",self)
	local l3 = gui.create("WILine",self)
	local l4 = gui.create("WILine",self)
	self.m_lines = {l0,l1,l2,l3,l4}
	for _,l in ipairs(self.m_lines) do
		l:SetLineWidth(2)
		l:SetColor(Color(200,200,200))
	end

	self.m_elCallbacks = {}
end
function Element:Setup(src,tgt)
	util.remove(self.m_elCallbacks)
	self.m_elSrc = src
	self.m_elTgt = tgt

	table.insert(self.m_elCallbacks,src:AddCallback("SetSize",function() self:ScheduleUpdate() end))
	table.insert(self.m_elCallbacks,src:AddCallback("SetPos",function() self:ScheduleUpdate() end))
	table.insert(self.m_elCallbacks,tgt:AddCallback("SetSize",function() self:ScheduleUpdate() end))
	table.insert(self.m_elCallbacks,tgt:AddCallback("SetPos",function() self:ScheduleUpdate() end))
	self:ScheduleUpdate()
end
function Element:OnRemove()
	util.remove(self.m_elCallbacks)
end
function Element:OnUpdate()
	if(util.is_valid(self.m_elSrc) == false or util.is_valid(self.m_elTgt) == false) then return end
	local absSrc = self.m_elSrc:GetAbsolutePos()
	local absTgt = self.m_elTgt:GetAbsolutePos()
	local absSrcEnd = absSrc +self.m_elSrc:GetSize()
	local absTgtEnd = absTgt +self.m_elTgt:GetSize()

	local startPoint
	local endPoint
	local hwSrc = self.m_elSrc:GetHalfWidth()
	local hhSrc = self.m_elSrc:GetHalfHeight()
	local hwTgt = self.m_elTgt:GetHalfWidth()
	local hhTgt = self.m_elTgt:GetHalfHeight()

	startPoint = Vector2()
	endPoint = Vector2()
	local horizontal = true
	local invArrow = false
	if(absTgt.x > absSrcEnd.x) then
		-- Right
		startPoint = Vector2(absTgt.x,absTgt.y +hhTgt)
		endPoint = Vector2(absSrcEnd.x,absSrc.y +hhSrc)
		invArrow = true
	elseif(absTgtEnd.x < absSrc.x) then
		-- Left
		startPoint = Vector2(absSrc.x,absSrc.y +hhSrc)
		endPoint = Vector2(absTgtEnd.x,absTgt.y +hhTgt)
	elseif(absTgt.y > absSrcEnd.y) then
		-- Down
		startPoint = Vector2(absSrc.x +hwSrc,absSrcEnd.y)
		endPoint = Vector2(absTgt.x +hwTgt,absTgt.y)
		horizontal = false
	else
		-- Up
		startPoint = Vector2(absTgt.x +hwTgt,absTgtEnd.y)
		endPoint = Vector2(absSrc.x +hwSrc,absSrc.y)
		horizontal = false
		invArrow = true
	end

	local mid = (startPoint +endPoint) *0.5
	self.m_lines[1]:SetStartPos(Vector2(startPoint.x,startPoint.y))
	if(horizontal) then self.m_lines[1]:SetEndPos(Vector2(mid.x,startPoint.y))
	else self.m_lines[1]:SetEndPos(Vector2(startPoint.x,mid.y)) end
	self.m_lines[1]:SizeToContents()

	self.m_lines[2]:SetStartPos(self.m_lines[1]:GetEndPos())
	if(horizontal) then self.m_lines[2]:SetEndPos(Vector2(mid.x,endPoint.y))
	else self.m_lines[2]:SetEndPos(Vector2(endPoint.x,mid.y)) end
	self.m_lines[2]:SizeToContents()

	self.m_lines[3]:SetStartPos(self.m_lines[2]:GetEndPos())
	self.m_lines[3]:SetEndPos(Vector2(endPoint.x,endPoint.y))
	self.m_lines[3]:SizeToContents()

	if(horizontal) then
		local arrowPoint = invArrow and startPoint or endPoint
		local sign = invArrow and -1 or 1
		self.m_lines[4]:SetStartPos(Vector2(arrowPoint.x,arrowPoint.y))
		self.m_lines[4]:SetEndPos(Vector2(arrowPoint.x +20 *sign,arrowPoint.y +10))
		self.m_lines[4]:SizeToContents()

		self.m_lines[5]:SetStartPos(Vector2(arrowPoint.x,arrowPoint.y))
		self.m_lines[5]:SetEndPos(Vector2(arrowPoint.x +20 *sign,arrowPoint.y -10))
		self.m_lines[5]:SizeToContents()
	else
		local arrowPoint = invArrow and startPoint or endPoint
		local sign = invArrow and -1 or 1
		self.m_lines[4]:SetStartPos(Vector2(arrowPoint.x,arrowPoint.y))
		self.m_lines[4]:SetEndPos(Vector2(arrowPoint.x -10,arrowPoint.y -20 *sign))
		self.m_lines[4]:SizeToContents()

		self.m_lines[5]:SetStartPos(Vector2(arrowPoint.x,arrowPoint.y))
		self.m_lines[5]:SetEndPos(Vector2(arrowPoint.x +10,arrowPoint.y -20 *sign))
		self.m_lines[5]:SizeToContents()
	end
end
gui.register("WIElementConnectorLine",Element)
