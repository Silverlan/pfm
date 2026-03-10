-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

gui.pfm = gui.pfm or {}
local Bookmark = util.register_class("gui.pfm.Bookmark", gui.Base)

function Bookmark:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:SetSize(7, 16)
	self.m_icon = gui.create("WITexturedRect", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_icon:SetMaterial("gui/pfm/timeline/bookmark")
	self.m_icon:GetColorProperty():Link(self:GetColorProperty())

	self:SetMouseInputEnabled(true)
end
function Bookmark:SetTimeline(timeline) self.m_timeline = timeline end
function Bookmark:GetTimeline() return self.m_timeline end
function Bookmark:SetBookmark(bm)
	self.m_bookmark = bm
end
function Bookmark:GetBookmark()
	return self.m_bookmark
end
function Bookmark:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		if state == input.STATE_PRESS then
			if util.is_valid(self.m_icon) then
				self.m_icon:SetMaterial("gui/pfm/timeline/bookmark_selected")
			end
		end
	elseif(button == input.MOUSE_BUTTON_RIGHT) then
		local pContext = gui.open_context_menu(self)
		if util.is_valid(pContext) then
			pContext
				:AddItem(locale.get_text("remove"), function()

				local bm = self:GetBookmark()
				print(bm)
				print(bm:GetParent())
				print(bm:GetParent():GetParent())
				local cmd = pfm.create_command(
					"delete_bookmark",
					bm:GetParent():GetParent(),
					bm:GetParent():GetName(),
					bm:GetTime()
				)
				pfm.undoredo.push("delete_bookmark", cmd)()
			end)
			pContext:Update()
			return util.EVENT_REPLY_HANDLED
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("pfm_bookmark", Bookmark)
