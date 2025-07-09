-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

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
