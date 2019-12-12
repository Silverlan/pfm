--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("gui.PFMBookmark",gui.Base)

function gui.PFMBookmark:__init()
	gui.Base.__init(self)
end
function gui.PFMBookmark:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetMouseInputEnabled(true)
	self:SetSize(7,16)
	self.m_icon = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_icon:SetMaterial("gui/pfm/timeline_bookmark")
	self.m_icon:GetColorProperty():Link(self:GetColorProperty())

	self:SetMouseInputEnabled(true)
end
function gui.PFMBookmark:MouseCallback(button,state,mods)
	if(button == input.MOUSE_BUTTON_LEFT) then
		if(state == input.STATE_PRESS) then
			if(util.is_valid(self.m_icon)) then
				self.m_icon:SetMaterial("gui/pfm/timeline_bookmark_selected")
			end
		end
	end
	return util.EVENT_REPLY_HANDLED
end
gui.register("WIPFMBookmark",gui.PFMBookmark)
