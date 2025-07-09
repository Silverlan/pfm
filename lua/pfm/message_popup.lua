-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/popup.lua")

pfm.impl = pfm.impl or {}
function pfm.create_popup_message(msg, duration, type, settings)
	local editor = tool.editor
	if util.is_valid(editor) == false then
		return
	end
	if util.is_valid(pfm.impl.popup) == false then
		pfm.impl.popup = gui.create("WIPFMPopup", editor)
	end
	if util.is_valid(pfm.impl.popup) == false then
		return
	end
	local el = pfm.impl.popup
	el:AddToQueue(msg, duration, type, settings)
	return el
end
