--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}

util.register_class("pfm.History",util.CallbackHandler)
function pfm.History:__init()
	util.CallbackHandler.__init(self)
	self:Clear()
end

function pfm.History:__len()
	return #self.m_history
end

function pfm.History:Get(index)
	return self.m_history[index or self:GetCurrentPosition()]
end

function pfm.History:Add(item)
	while(#self > self.m_currentPosition) do
		table.remove(self.m_history,#self)
	end
	table.insert(self.m_history,item)
	self:CallCallbacks("OnItemAdded",item,#self)
	self:SetCurrentPosition(#self)
end

function pfm.History:SetCurrentPosition(index)
	index = math.clamp(index,1,#self)
	self.m_currentPosition = index
	local item = self:Get()
	self:CallCallbacks("OnPositionChanged",item,index)
	return item
end

function pfm.History:GoBack()
	if(self.m_currentPosition <= 1) then return end
	self:SetCurrentPosition(self:GetCurrentPosition() -1)
	return self:Get()
end

function pfm.History:GoForward()
	if(self.m_currentPosition >= #self.m_history) then return end
	self:SetCurrentPosition(self:GetCurrentPosition() +1)
	return self:Get()
end

function pfm.History:GetCurrentPosition() return self.m_currentPosition end

function pfm.History:Clear()
	self.m_history = {}
	self:SetCurrentPosition(1)
end
