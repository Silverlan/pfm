--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/info_box.lua")

util.register_class("gui.PFMPopup",gui.Base)

local ANIMATION_TIME = 0.8
function gui.PFMPopup:__init()
	gui.Base.__init(self)
end
function gui.PFMPopup:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(400,32)

	self.m_queue = {}
	self.m_first = true
	self:SetThinkingEnabled(true)
end
function gui.PFMPopup:OnRemove()
	util.remove(self.m_infoBox)
end
function gui.PFMPopup:OnThink()
	local t = time.real_time()
	if(self.m_infoStartTime == nil) then return end
	local function displayNext()
		if(#self.m_queue == 0) then
			util.remove(self.m_infoBox)
			self.m_infoStartTime = nil
			self.m_first = true
		else self:DisplayNextText() end
	end
	local el = self.m_infoBox
	if(util.is_valid(el) == false) then
		displayNext()
		return
	end
	local dt = t -self.m_infoStartTime
	local factor
	local startFadeOutTime = ANIMATION_TIME +(self.m_displayDuration or math.huge)
	if(dt >= startFadeOutTime) then
		dt = dt -startFadeOutTime
		factor = 1.0 -math.min(dt /ANIMATION_TIME,1.0)

		if(factor == 0.0) then
			displayNext()
			return
		end
	else
		factor = math.min(dt /ANIMATION_TIME,1.0)
	end
	factor = math.smooth_step(0,1,factor)

	local p = el:GetParent()
	local pos = p:GetWidth() -(el:GetWidth() *factor)
	el:SetX(pos)
end
function gui.PFMPopup:DisplayNextText()
	if(#self.m_queue == 0) then return end
	local infoBox = gui.create_info_box(tool.get_filmmaker(),self.m_queue[1][1],self.m_queue[1][3])
	infoBox:SetWidth(400)
	infoBox:SetMouseInputEnabled(true)
	infoBox:SetRemoveOnClose(true)
	infoBox:SizeToContents()

	util.remove(self.m_infoBox)
	self.m_infoBox = infoBox
	self.m_infoStartTime = time.real_time()
	self.m_displayDuration = self.m_queue[1][2]

	table.remove(self.m_queue,1)
end
function gui.PFMPopup:AddToQueue(text,duration,type)
	table.insert(self.m_queue,{text,(duration == nil) and 10.0 or duration,type or gui.InfoBox.TYPE_INFO})
	if(self.m_first) then
		self:DisplayNextText()
		self.m_first = false
	end
end
gui.register("WIPFMPopup",gui.PFMPopup)
