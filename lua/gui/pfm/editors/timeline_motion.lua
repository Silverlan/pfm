--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMTimelineMotion",gui.Base)

function gui.PFMTimelineMotion:__init()
	gui.Base.__init(self)
end
function gui.PFMTimelineMotion:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(256,64)
	self.m_contentsScroll = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self:SetAutoSizeToContents()
end
gui.register("WIPFMTimelineMotion",gui.PFMTimelineMotion)
