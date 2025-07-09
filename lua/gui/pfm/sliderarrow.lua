-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.PFMSliderArrow", gui.Base)

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(12, 20)

	local elIcon = gui.create("WITexturedRect", self)
	elIcon:SetMaterial("gui/pfm/arrow_left")
	elIcon:SetSize(5, 7)
	elIcon:CenterToParent()
	self.m_elIcon = elIcon

	self:SetMouseInputEnabled(true)
	self:AddStyleClass("input_field_overlay")
end
function Element:SetArrowType(type)
	self.m_elIcon:SetMaterial("gui/pfm/arrow_" .. type)
end
function Element:MouseCallback(button, state, mods)
	if button == input.MOUSE_BUTTON_LEFT and state == input.STATE_PRESS then
		self:CallCallbacks("OnClicked")
		return util.EVENT_REPLY_HANDLED
	end
end
gui.register("WIPFMSliderArrow", Element)
