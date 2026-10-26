-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/selection/outline.lua")

util.register_class("gui.BaseClip", gui.Base)

function gui.BaseClip:OnInitialize()
	gui.Base.OnInitialize(self)

	local w = 128
	local h = 23
	self:ApplySize(w, h)

	self:SetAutoSizeToContents(true)

	local contents = gui.create_vbox(self)
		:AddStyleClass("clip__content-area")

	local header = gui.create_vbox(contents)
		:AddStyleClass("clip__header")
	self.m_text = gui.create("WIText", header)
		:AddStyleClass("clip__title")

	local body = gui.create_vbox(contents)
		:AddStyleClass("clip__body")
	self.m_body = body

	self:SetSelected(false)
end
function gui.BaseClip:SetText(text)
	if util.is_valid(self.m_text) == false then
		return
	end
	self.m_text:SetText(text)
end
function gui.BaseClip:IsSelected()
	return self.m_selected
end
function gui.BaseClip:SetSelected(selected)
	if selected == self:IsSelected() then
		return
	end
	self.m_selected = selected
	self:SetState(gui.STATE_SELECTED, selected)
	if selected then
		self:CallCallbacks("OnSelected")
	else
		self:CallCallbacks("OnDeselected")
	end
end
