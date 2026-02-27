-- SPDX-FileCopyrightText: (c) 2023 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Element = util.register_class("gui.ProgressStatusInfo", gui.Base)

local g_activeProcesses = 0
function Element:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256, 24)
	local progressBarBg =
		gui.create("WIRect", self, 0, self:GetHeight() / 4.0, self:GetWidth(), self:GetHeight() / 2.0, 0, 0, 1, 1)
	local progressBar =
		gui.create("WIRect", progressBarBg, 0, 0, progressBarBg:GetWidth(), progressBarBg:GetHeight(), 0, 0, 1, 1)
	progressBar:SetColor(Color(153, 204, 255))
	self.m_progressBar = progressBar
	self.m_progressBarBg = progressBarBg

	local elText = gui.create("WIText", self)
	elText:SetColor(Color(51, 51, 51))
	elText:AddStyleClass("input_field_text")
	self.m_elText = elText

	if g_activeProcesses == 0 then
		-- Disable automatic sleep mode as long as the process is active
		os.set_prevent_os_sleep_mode(true)
	end
	g_activeProcesses = g_activeProcesses + 1
end
function Element:SetProgress(progress)
	local width = self.m_progressBarBg:GetWidth() * progress
	self.m_progressBar:SetWidth(width)
end
function Element:OnSizeChanged()
	if util.is_valid(self.m_elText) == false then
		return
	end
	self.m_elText:SetX(5)
	self.m_elText:SetY((self:GetHeight() - self.m_elText:GetHeight()) / 2)

	self.m_progressBarBg:SetX(self.m_elText:GetRight() + 5)
	self.m_progressBarBg:SetWidth(self:GetWidth() - self.m_elText:GetRight() - 5)
end
function Element:SetText(text)
	self.m_elText:SetText(text)
	self.m_elText:SizeToContents()

	self:SetWidth(self.m_elText:GetWidth() + 100)
	self:ScheduleUpdate()
end
function Element:OnRemove()
	g_activeProcesses = g_activeProcesses - 1
	if g_activeProcesses == 0 then
		-- Re-enable automatic sleep mode
		os.set_prevent_os_sleep_mode(false)
	end
end
gui.register("progress_status_info", Element)
