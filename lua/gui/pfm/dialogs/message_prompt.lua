-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/gui/pfm/window.lua")

local PfmPrompt = util.register_class("gui.PfmPrompt", gui.PFMWindow)
PfmPrompt.BUTTON_NONE = 0
PfmPrompt.BUTTON_OK = 1
PfmPrompt.BUTTON_YES = bit.lshift(PfmPrompt.BUTTON_OK, 1)
PfmPrompt.BUTTON_NO = bit.lshift(PfmPrompt.BUTTON_YES, 1)
PfmPrompt.BUTTON_CANCEL = bit.lshift(PfmPrompt.BUTTON_NO, 1)

function PfmPrompt:OnInitialize()
	gui.PFMWindow.OnInitialize(self)

	self:SetWindowSize(Vector2i(202, 160))

	local contents = self:GetContents()

	gui.create("WIBase", contents, 0, 0, 1, 12) -- Gap

	local elMsg = gui.create("WIText", contents)
	elMsg:SetFont("pfm_medium")
	self.m_message = elMsg

	gui.create("WIBase", contents, 0, 0, 1, 12) -- Gap

	local userContents = gui.create("vbox", contents) -- Space for custom content
	self.m_userContents = userContents

	local boxButtons = gui.create("hbox", contents)
	self.m_boxButtons = boxButtons

	boxButtons:SetX(contents:GetWidth() - boxButtons:GetWidth())
end
function PfmPrompt:GetUserContents()
	return self.m_userContents
end
local buttonData = {
	[PfmPrompt.BUTTON_OK] = { text = locale.get_text("ok") },
	[PfmPrompt.BUTTON_CANCEL] = { text = locale.get_text("cancel") },
	[PfmPrompt.BUTTON_YES] = { text = locale.get_text("yes") },
	[PfmPrompt.BUTTON_NO] = { text = locale.get_text("no") },
}
function PfmPrompt:AddStandardButton(bt)
	self:AddButton(bt, buttonData[bt].text)
end
function PfmPrompt:AddButton(id, text)
	local elBt = gui.create("pfm_button", self.m_boxButtons)
	elBt:SetText(text)
	elBt:AddCallback("OnPressed", function()
		if self:CallCallbacks("OnButtonPressed", id) == util.EVENT_REPLY_HANDLED then
			return
		end
		self:GetFrame():Remove()
	end)
	elBt:SizeToContents()
	gui.create("WIBase", self.m_boxButtons, 0, 0, 8, 1) -- Gap
	self.m_boxButtons:ScheduleUpdate()

	self:ScheduleUpdate()
end
function PfmPrompt:AddStandardButtons(bts)
	local vals = math.get_power_of_2_values(bts)
	for i = #vals, 1, -1 do
		self:AddStandardButton(vals[i])
	end
end
function PfmPrompt:SetMessage(msg)
	self.m_message:SetWidth(512)
	self.m_message:SetAutoBreakMode(gui.Text.AUTO_BREAK_WHITESPACE)
	self.m_message:SetText(msg)
	self.m_message:SizeToContents()
	self:ScheduleUpdate()
end
function PfmPrompt:OnSizeChanged(w, h)
	gui.PFMWindow.OnSizeChanged(self, w, h)
end
function PfmPrompt:OnUpdate()
	gui.PFMWindow.OnUpdate(self)
	self.m_message:UpdateSubLines()
	local w = math.max(self.m_message:GetTextWidth(), self.m_boxButtons:GetWidth())

	self:SetWindowSize(Vector2i(w + 20, self.m_message:GetHeight() + self.m_userContents:GetHeight() + 95))
end
gui.register("pfm_prompt", PfmPrompt)

pfm.open_message_prompt = function(title, message, buttons, cb)
	local p = gui.create("pfm_prompt", tool.get_filmmaker())
	p:SetTitle(title)
	p:SetMessage(message)
	p:AddStandardButtons(buttons)

	if cb ~= nil then
		p:AddCallback("OnButtonPressed", function(p, bt)
			return cb(bt)
		end)
	end
	return p
end
