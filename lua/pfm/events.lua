--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm = pfm or {}

local eventListenerHandler = util.CallbackHandler()
pfm.add_event_listener = function(name, fc)
	return eventListenerHandler:AddCallback(name, fc)
end
pfm.call_event_listeners = function(...)
	return eventListenerHandler:CallCallbacks(...)
end
