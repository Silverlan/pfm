-- SPDX-FileCopyrightText: (c) 2026 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}

local EventBus = util.register_class("pfm.EventBus")

local ListenerGroup = util.register_class("pfm.EventBus.ListenerGroup")
function ListenerGroup:__init(eventBus)
	self.m_eventBus = eventBus
end
function ListenerGroup:Remove() self.m_eventBus:RemoveListenerGroup(self) end
function ListenerGroup:AddListener(name, fc) self.m_eventBus:AddListener(self, name, fc) end

function EventBus:__init()
	self.m_listeners = {}
end

function EventBus:AddListenerGroup()
	return ListenerGroup(self)
end

function EventBus:RemoveListenerGroup(group)
	if(self.m_listeners[name] == nil) then return end
    local i = 1
    while i <= #self.m_listeners[name] do
        local listener = self.m_listeners[name][i]
        if(listener.group == group) then
            table.remove(self.m_listeners[name], i)
        else
            i = i +1
        end
    end
    if(#self.m_listeners[name] == 0) then self.m_listeners[name] = nil end
end

function EventBus:AddListener(group, name, fc)
	self.m_listeners[name] = self.m_listeners[name] or {}
	table.insert(self.m_listeners[name], {
		fn = fc,
		group = group
	})
end

function EventBus:Emit(name, ...)
	if(self.m_listeners[name] == nil) then return end
    for _, listener in ipairs(self.m_listeners[name]) do
        listener.fn(...)
    end
end
