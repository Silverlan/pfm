--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/asseticon.lua")
include("/gui/modelexplorer.lua")

util.register_class("gui.PFMModelCatalog",gui.Base)

function gui.PFMModelCatalog:__init()
	gui.Base.__init(self)
end
function gui.PFMModelCatalog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	local scrollContainer = gui.create("WIScrollContainer",self.m_bg,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)

	local explorer = gui.create("WIModelExplorer",scrollContainer,0,0,self:GetWidth(),self:GetHeight())
	explorer:SetRootPath("models")
	explorer:SetExtensions({"wmd"})
	explorer:Update()
	self.m_explorer = explorer
end
gui.register("WIPFMModelCatalog",gui.PFMModelCatalog)
