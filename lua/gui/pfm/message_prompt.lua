--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("window.lua")

local PfmPrompt = util.register_class("gui.PfmPrompt",gui.PFMWindow)
PfmPrompt.BUTTON_OK = 1
PfmPrompt.BUTTON_YES = bit.lshift(PfmPrompt.BUTTON_OK,1)
PfmPrompt.BUTTON_NO = bit.lshift(PfmPrompt.BUTTON_YES,1)
PfmPrompt.BUTTON_CANCEL = bit.lshift(PfmPrompt.BUTTON_NO,1)

function PfmPrompt:OnInitialize()
	gui.PFMWindow.OnInitialize(self)

	self:SetWindowSize(Vector2i(202,160))

	local contents = self:GetContents()

	gui.create("WIBase",contents,0,0,1,12) -- Gap

	local elMsg = gui.create("WIText",contents)
	elMsg:SetFont("pfm_medium")
	elMsg:SetColor(Color(200,200,200))
	self.m_message = elMsg

	gui.create("WIBase",contents,0,0,1,12) -- Gap

	local boxButtons = gui.create("WIHBox",contents)
	self.m_boxButtons = boxButtons

	boxButtons:SetX(contents:GetWidth() -boxButtons:GetWidth())
end
local buttonData = {
	[PfmPrompt.BUTTON_OK] = {text = "ok"},
	[PfmPrompt.BUTTON_CANCEL] = {text = "cancel"},
	[PfmPrompt.BUTTON_YES] = {text = "yes"},
	[PfmPrompt.BUTTON_NO] = {text = "no"}
}
function PfmPrompt:AddButton(bt)
	local text = buttonData[bt].text

	local elBt = gui.create("WIButton",self.m_boxButtons)
	elBt:SetSize(73,21)
	elBt:SetText(locale.get_text(text))
	elBt:AddCallback("OnMousePressed",function()
		if(self:CallCallbacks("OnButtonPressed",bt) == util.EVENT_REPLY_HANDLED) then return end
		self:GetFrame():Remove()
	end)
	gui.create("WIBase",self.m_boxButtons,0,0,8,1) -- Gap
	self.m_boxButtons:ScheduleUpdate()

	self:ScheduleUpdate()
end
function PfmPrompt:AddButtons(bts)
	local vals = math.get_power_of_2_values(bts)
	for i=#vals,1,-1 do
		self:AddButton(vals[i])
	end
end
function PfmPrompt:SetMessage(msg)
	self.m_message:SetText(msg)
	self.m_message:SizeToContents()
end
function PfmPrompt:OnSizeChanged(w,h)
	gui.PFMWindow.OnSizeChanged(self,w,h)
end
function PfmPrompt:OnUpdate()
	gui.PFMWindow.OnUpdate(self)
	self:SetWindowSize(Vector2i(self.m_message:GetWidth() +20,120))
end
gui.register("WIPFMPrompt",PfmPrompt)

pfm.open_message_prompt = function(title,message,buttons,cb)
	local p = gui.create("WIPFMPrompt")
	p:SetTitle(title)
	p:SetMessage(message)
	p:AddButtons(buttons)

	if(cb ~= nil) then
		p:AddCallback("OnButtonPressed",function(p,bt) return cb(bt) end)
	end
	return p
end
