--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.ModalOverlay",gui.Base)
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self.m_bgEls = {}
	for i=1,4 do
		local el = gui.create("WIRect",self)
		el:SetColor(Color(5,5,5,200))
		table.insert(self.m_bgEls,el)
	end

	self:SetSize(64,64)
	self.m_elCallbacks = {}

	self:SetMouseInputEnabled(true)
end
function Element:MouseCallback(button,state,mods)
	if(util.is_valid(self.m_elTarget)) then
		local pos = self.m_elTarget:GetAbsolutePos()
		local sz = self.m_elTarget:GetSize()
		local posCursor = input.get_cursor_pos()
		if(posCursor.x >= pos.x and posCursor.y >= pos.y and posCursor.x < (pos.x +sz.x) and posCursor.y < (pos.y +sz.y)) then
			return util.EVENT_REPLY_UNHANDLED
		end
	end
	return util.EVENT_REPLY_HANDLED
end
function Element:SetTarget(el)
	self.m_elTarget = el
	util.remove(self.m_elCallbacks)
	table.insert(self.m_elCallbacks,el:AddCallback("SetSize",function() self:ScheduleUpdate() end))
	table.insert(self.m_elCallbacks,el:AddCallback("SetPos",function() self:ScheduleUpdate() end))
	self:ScheduleUpdate()
end
function Element:OnRemove()
	util.remove(self.m_elCallbacks)
end
function Element:OnUpdate()
	if(util.is_valid(self.m_elTarget) == false) then
		self.m_bgEls[1]:SetWidth(self:GetWidth())
		self.m_bgEls[1]:SetHeight(self:GetHeight())
		for i=2,4 do
			self.m_bgEls[i]:SetSize(0,0)
		end
		return
	end
	local absPos = self.m_elTarget:GetAbsolutePos()
	self.m_bgEls[1]:SetWidth(self:GetWidth())
	self.m_bgEls[1]:SetHeight(absPos.y)

	self.m_bgEls[2]:SetY(self.m_bgEls[1]:GetBottom())
	self.m_bgEls[2]:SetWidth(absPos.x)
	self.m_bgEls[2]:SetHeight(self.m_elTarget:GetHeight())

	self.m_bgEls[3]:SetX(absPos.x +self.m_elTarget:GetWidth())
	self.m_bgEls[3]:SetY(self.m_bgEls[1]:GetBottom())
	self.m_bgEls[3]:SetWidth(self:GetWidth() -self.m_bgEls[3]:GetX())
	self.m_bgEls[3]:SetHeight(self.m_elTarget:GetHeight())

	self.m_bgEls[4]:SetWidth(self:GetWidth())
	self.m_bgEls[4]:SetHeight(self:GetHeight() -absPos.y +self.m_elTarget:GetHeight())
	self.m_bgEls[4]:SetY(self.m_bgEls[3]:GetBottom())
end
gui.register("WIModalOverlay",Element)
