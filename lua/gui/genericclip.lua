--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/pfm/fonts.lua")
include("baseclip.lua")

util.register_class("gui.GenericClip", gui.BaseClip)

function gui.GenericClip:OnInitialize()
	gui.BaseClip.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:AddCallback("OnMousePressed", function()
		self:SetSelected(true)
	end)
end
function gui.GenericClip:UpdateClipData()
	self:SetClipData(self.m_clipData)
end
function gui.GenericClip:SetClipData(clipData)
	self.m_clipData = clipData
	self:SetText(clipData:GetName())
end
function gui.GenericClip:GetClipData()
	return self.m_clipData
end
gui.register("WIGenericClip", gui.GenericClip)
