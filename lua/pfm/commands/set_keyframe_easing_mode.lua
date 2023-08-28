--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Command = util.register_class("pfm.CommandSetKeyframeEasingMode", pfm.Command)
function Command:Initialize(filmClip, oldOffset, newOffset)
	pfm.Command.Initialize(self)
	local data = self:GetData()

	return true
end
function Command:DoExecute(data) end
function Command:DoUndo(data) end
pfm.register_command("set_keyframe_easing_mode", Command)
