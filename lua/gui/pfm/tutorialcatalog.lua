--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/tutorialexplorer.lua")
include("/gui/editableentry.lua")

util.register_class("gui.PFMTutorialCatalog",gui.Base)

function gui.PFMTutorialCatalog:__init()
	gui.Base.__init(self)
end
function gui.PFMTutorialCatalog:OnInitialize()
	gui.Base.OnInitialize(self)

	self:SetSize(64,128)

	self.m_bg = gui.create("WIRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_bg:SetColor(Color(54,54,54))

	self.m_contents = gui.create("WIVBox",self.m_bg,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_contents:SetFixedSize(true)
	self.m_contents:SetAutoFillContents(true)

	self.m_teLocation = gui.create("WITextEntry",self.m_contents,0,0,self:GetWidth(),24)
	self.m_teLocation:AddCallback("OnTextEntered",function(pEntry)
		self.m_explorer:SetPath(pEntry:GetText())
		self.m_explorer:Update()
	end)
	self.m_teLocation:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_location"))

	local scrollContainer = gui.create("WIScrollContainer",self.m_contents,0,0,self:GetWidth(),self:GetHeight() -48)
	scrollContainer:SetContentsWidthFixed(true)
	--[[scrollContainer:AddCallback("SetSize",function(el)
		if(self:IsValid() and util.is_valid(self.m_explorer)) then
			self.m_explorer:SetWidth(el:GetWidth())
		end
	end)]]

	self.m_teFilter = gui.create("WITextEntry",self.m_contents,0,0,self:GetWidth(),24)
	self.m_teFilter:AddCallback("OnTextEntered",function(pEntry)
		self.m_explorer:Refresh()
		self.m_explorer:ListFiles()
	end)
	self.m_teFilter:Wrap("WIEditableEntry"):SetText(locale.get_text("pfm_filter"))

	local explorer = gui.create("WITutorialExplorer",scrollContainer,0,0,self:GetWidth(),self:GetHeight())
	explorer:SetAutoAlignToParent(true,false)
	explorer:SetRootPath("tutorials")
	explorer:SetExtensions({"pvr"})
	explorer:AddCallback("OnPathChanged",function(explorer,path)
		self.m_teLocation:SetText(path)
	end)
	self.m_explorer = explorer

	self.m_contents:Update()
	scrollContainer:SetAnchor(0,0,1,1)
	self.m_teLocation:SetAnchor(0,0,1,1)
	self.m_teFilter:SetAnchor(0,0,1,1)

	self:EnableThinking()
end
function gui.PFMTutorialCatalog:OnThink()
	-- Lazy initialization
	self.m_explorer:Update()

	self:DisableThinking()
end
gui.register("WIPFMTutorialCatalog",gui.PFMTutorialCatalog)
