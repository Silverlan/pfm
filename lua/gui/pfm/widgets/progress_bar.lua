-- SPDX-FileCopyrightText: (c) 2019 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("gui.PFMProgressBar", gui.Base)

function gui.PFMProgressBar:__init()
	gui.Base.__init(self)
end
function gui.PFMProgressBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128, 5)

	self.m_progressBar = gui.create("WIProgressBar", self, 0, 0, self:GetWidth(), self:GetHeight(), 0, 0, 1, 1)
	self.m_progressBar:GetColorProperty():Link(self:GetColorProperty())

	self:SetColor(Color.Lime)
end
function gui.PFMProgressBar:SetProgress(progress)
	if util.is_valid(self.m_progressBar) == false then
		return
	end
	self.m_progressBar:SetProgress(progress)
end
function gui.PFMProgressBar:GetProgress()
	if util.is_valid(self.m_progressBar) == false then
		return 0.0
	end
	return self.m_progressBar:GetProgress()
end
gui.register("pfm_progress_bar", gui.PFMProgressBar)
