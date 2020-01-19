--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/selection.lua")

util.register_class("gui.PFMGraphKey",gui.Base)

function gui.PFMGraphKey:__init()
	gui.Base.__init(self)
end
function gui.PFMGraphKey:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(4,4)
	
	local bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	bg:GetColorProperty():Link(self:GetColorProperty())

	gui.set_mouse_selectable(self,true)
	self:AddCallback("OnMouseSelected",function(el)
		self:SetColor(Color(255,255,32))
	end)
	self:AddCallback("OnMouseDeselected",function(el)
		self:SetColor(Color.Black)
	end)
	self:AddCallback("OnMouseSelectionHover",function(el)
		self:SetColor(Color(32,255,32))
	end)
end
gui.register("WIPFMGraphKey",gui.PFMGraphKey)
