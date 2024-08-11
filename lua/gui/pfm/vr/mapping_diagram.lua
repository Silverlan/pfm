--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/vbox.lua")

local Element = util.register_class("gui.PfmVrMappingDiagram", gui.Base)
-- Note: These should correspond to the openvr enums
Element.BUTTON_SYSTEM = 0
Element.BUTTON_APPLICATION_MENU = 1 -- "B"
Element.BUTTON_GRIP = 2 -- Grip
Element.BUTTON_DPAD_LEFT = 3
Element.BUTTON_DPAD_UP = 4
Element.BUTTON_DPAD_RIGHT = 5
Element.BUTTON_DPAD_DOWN = 6
Element.BUTTON_A = 7 -- "A"

Element.BUTTON_PROXIMITY_SENSOR = 31

Element.BUTTON_AXIS_0 = 32
Element.BUTTON_AXIS_1 = 33
Element.BUTTON_AXIS_2 = 34
Element.BUTTON_AXIS_3 = 35
Element.BUTTON_AXIS_4 = 36

Element.BUTTON_STEAMVR_TOUCHPAD = 32 -- Thumbstick
Element.BUTTON_STEAMVR_TRIGGER = 33 -- Trigger

function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64, 64)

	local vb = gui.create("WIVBox", self)

	local el = gui.create("WITexturedRect", vb)
	el:SetMaterial("vr/oculus_button_mapping_diagram")
	el:SetSize(512, 512)

	local textContainer = gui.create("WIRect", vb)
	textContainer:SetSize(512, 32)
	textContainer:SetColor(Color.Black)
	textContainer:SetAutoSizeToContents(false, true)
	self.m_textContainer = textContainer

	local textVbox = gui.create("WIVBox", textContainer)
	self.m_textVbox = textVbox

	self.m_textElements = {}
	local function add_text(i)
		local elText = gui.create("WIText", textVbox)
		elText:SetText(i .. ": -")
		elText:SizeToContents()
		elText:SetColor(Color.White)
		self.m_textElements[i] = elText
	end

	gui.create("WIBase", textVbox, 0, 0, 1, 5) -- Gap
	for i = 1, 7 do
		add_text(i)
	end
	gui.create("WIBase", textVbox, 0, 0, 1, 5) -- Gap
	self:ScheduleUpdate()
end
local buttonToIndex = {
	[Element.BUTTON_STEAMVR_TRIGGER] = 0,
	[Element.BUTTON_APPLICATION_MENU] = 4,
	[Element.BUTTON_A] = 3,
	[Element.BUTTON_STEAMVR_TOUCHPAD] = 1,
	[Element.BUTTON_GRIP] = 6,
}
function Element:SetButtonMapping(button, text)
	if buttonToIndex[button] == nil then
		return
	end
	local buttonIdx = buttonToIndex[button]
	local el = self.m_textElements[buttonIdx + 1]
	el:SetText((buttonIdx + 1) .. ": " .. text)
	el:SizeToContents()
end
function Element:OnUpdate()
	self:SetSize(self.m_textContainer:GetWidth(), self.m_textContainer:GetBottom())
end
gui.register("WIPFMVRMappingDiagram", Element)
