--[[
    Copyright (C) 2020  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/popup.lua")

pfm.impl = pfm.impl or {}
function pfm.create_popup_message(msg)
	local filmmaker = tool.get_filmmaker()
	if(util.is_valid(filmmaker) == false) then return end
	if(util.is_valid(pfm.impl.popup) == false) then pfm.impl.popup = gui.create("WIPFMPopup",filmmaker) end
	if(util.is_valid(pfm.impl.popup) == false) then return end
	local el = pfm.impl.popup
	el:SetText(msg)
	el:SetX(filmmaker:GetWidth() -el:GetWidth())
end
