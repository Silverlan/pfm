--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("baseclip.lua")

util.register_class("gui.GenericClip",gui.BaseClip)

function gui.GenericClip:__init()
	gui.BaseClip.__init(self)
end
function gui.GenericClip:OnInitialize()
	gui.BaseClip.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMousePressed",function()
		self:SetSelected(true)
	end)
end
gui.register("WIGenericClip",gui.GenericClip)
