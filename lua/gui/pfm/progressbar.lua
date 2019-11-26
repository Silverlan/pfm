--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMProgressBar",gui.Base)

function gui.PFMProgressBar:__init()
	gui.Base.__init(self)
end
function gui.PFMProgressBar:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(128,5)

	self.m_progressBar = gui.create("WIProgressBar",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_progressBar:GetColorProperty():Link(self:GetColorProperty())

	self:SetColor(Color.Lime)
end
function gui.PFMProgressBar:SetProgress(progress)
	if(util.is_valid(self.m_progressBar) == false) then return end
	self.m_progressBar:SetProgress(progress)
end
function gui.PFMProgressBar:GetProgress()
	if(util.is_valid(self.m_progressBar) == false) then return 0.0 end
	return self.m_progressBar:GetProgress()
end
gui.register("WIPFMProgressBar",gui.PFMProgressBar)
