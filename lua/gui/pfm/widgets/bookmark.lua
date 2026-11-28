-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

gui.pfm = gui.pfm or {}
local Bookmark = util.register_class("gui.pfm.Bookmark", gui.Base)

function Bookmark:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:SetAutoSizeToContents(true)
	self.m_icon = gui.create("WITexturedRect", self)

	self:SetMouseInputEnabled(true)
	self.m_icon:AddStyleClass("bookmark")
end
function Bookmark:SetTimeline(timeline) self.m_timeline = timeline end
function Bookmark:GetTimeline() return self.m_timeline end
function Bookmark:SetBookmark(bm) self.m_bookmark = bm end
function Bookmark:GetBookmark() return self.m_bookmark end
function Bookmark:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT then
		--[[if state == input.STATE_PRESS then
			self.m_icon:SetState(gui.STATE_SELECTED, true)
		end]]
	elseif(button == input.MOUSE_BUTTON_RIGHT) then
		local pContext = gui.open_context_menu(self)
		if util.is_valid(pContext) then
			pContext
				:AddItem(locale.get_text("remove"), function()

				local bm = self:GetBookmark()
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
