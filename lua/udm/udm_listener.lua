--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("fudm.Listener")
function fudm.Listener:__init()
end

function fudm.Listener:AddChangeListener(listener)
	local cb = util.Callback.Create(listener)
	self.m_listeners = self.m_listeners or {}
	table.insert(self.m_listeners,cb)
	return cb
end

function fudm.Listener:InvokeChangeListeners(...)
	if(self.m_listeners == nil) then return end
	local val = self:GetValue()

	local hasRemoved = false
	for i,listener in ipairs(self.m_listeners) do
		if(listener:IsValid()) then
			if(select(1,...) ~= nil) then listener:Call(...)
			else listener:Call(val) end
		else
			self.m_listeners[i] = nil
			hasRemoved = true
		end
	end

	if(hasRemoved) then
		for i=#self.m_listeners,1,-1 do
			if(self.m_listeners[i] == nil) then
				table.remove(self.m_listeners,i)
			end
		end
	end
end
