-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.PFMBookmark", gui.Base)

function gui.PFMBookmark:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:SetSize(7, 16)
	self.m_icon = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_icon:SetMaterial("gui/pfm/timeline_bookmark")
	self.m_icon:GetColorProperty():Link(self:GetColorProperty())

	self:SetMouseInputEnabled(true)
end
function gui.PFMBookmark:SetBookmark(bm)
	self.m_bookmark = bm
end
function gui.PFMBookmark:GetBookmark()
	return self.m_bookmark
end
function gui.PFMBookmark:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			if util.is_valid(self.m_icon) then
				self.m_icon:SetMaterial("gui/pfm/timeline_bookmark_selected")
			end
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("pfm_bookmark", gui.PFMBookmark)
