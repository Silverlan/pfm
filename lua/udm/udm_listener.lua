--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("udm.Listener")
function udm.Listener:__init()
end

function udm.Listener:AddChangeListener(listener)
	local cb = util.Callback.Create(listener)
	self.m_listeners = self.m_listeners or {}
	table.insert(self.m_listeners,cb)
	return cb
end

function udm.Listener:InvokeChangeListeners(...)
	if(self.m_listeners == nil) then return end
	local val = self:GetValue()
	local numListeners = #self.m_listeners
	local i = 1
	while(i <= numListeners) do
		local listener = self.m_listeners[i]
		if(listener:IsValid()) then
			if(select(1,...) ~= nil) then listener:Call(...)
			else listener:Call(val) end
			i = i +1
		else
			table.remove(self.m_listeners,i)
			numListeners = numListeners -1
		end
	end
end
