-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

pfm = pfm or {}

local eventListenerHandler = util.CallbackHandler()
pfm.add_event_listener = function(name, fc)
	return eventListenerHandler:AddCallback(name, fc)
end
pfm.call_event_listeners = function(...)
	return eventListenerHandler:CallCallbacks(...)
end
