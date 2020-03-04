--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/gridbox.lua")
include("/gui/wibasefileexplorer.lua")
include("/gui/asseticon.lua")

util.register_class("gui.ModelExplorer",gui.Base,gui.BaseFileExplorer)
function gui.ModelExplorer:__init()
	gui.Base.__init(self)
	gui.BaseFileExplorer.__init(self)
end
function gui.ModelExplorer:OnInitialize()
	gui.Base.OnInitialize(self)
	self:SetSize(64,64)

	self.m_iconContainer = gui.create("WIGridBox",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	self.m_icons = {}
end
function gui.ModelExplorer:Update()
	self:ListFiles()
end
function gui.ModelExplorer:SetIconSelected(icon)
	if(util.is_valid(self.m_selectedIcon)) then self.m_selectedIcon:SetSelected(false) end
	icon:SetSelected(true)
	self.m_selectedIcon = icon
end
function gui.ModelExplorer:AddIcon(assetPath)
	local el = gui.create("WIAssetIcon",self.m_iconContainer)
	el:SetAsset(assetPath)
	table.insert(self.m_icons,el)

	el:SetMouseInputEnabled(true)
	el:AddCallback("OnMouseEvent",function(pRow,button,action,mods)
		if(util.is_valid(self) == false) then return end
		if(button == input.MOUSE_BUTTON_LEFT and action == input.STATE_PRESS) then
			self:CallCallbacks("OnFileClicked",assetPath)
			self:SetIconSelected(el)
		end
	end)
	el:AddCallback("OnDoubleClick",function(pRow)
		if(util.is_valid(self) == false) then return end
		--self:CallCallbacks("OnFileSelected",fPath)
	end)
	--[[	row:AddCallback("OnMouseEvent",function(pRow,button,action,mods)
				if(util.is_valid(self) == false) then return end
				if(button == input.MOUSE_BUTTON_LEFT and action == input.STATE_PRESS) then
					self:CallCallbacks("OnFileClicked",fName)
				end
			end)
			row:AddCallback("OnDoubleClick",function(pRow)
				if(util.is_valid(self) == false) then return end
				self:CallCallbacks("OnFileSelected",fPath)
			end)]]

end
function gui.ModelExplorer:ListFiles()
	local tFiles,tDirectories = self:FindFiles()
	for _,f in ipairs(tFiles) do
		self:AddIcon(f)
	end
	-- TODO: Directory icon
	self.m_iconContainer:Update()
end
gui.register("WIModelExplorer",gui.ModelExplorer)
