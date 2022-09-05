--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = util.register_class("gui.PFMLoadingScreen",gui.Base)
function Element:OnInitialize()
	self:SetSize(1024,768)

	local fontSet = engine.get_default_font_set_name()
	local fontFeatures = bit.bor(engine.FONT_FEATURE_FLAG_SANS_BIT,engine.FONT_FEATURE_FLAG_MONO_BIT)
	engine.create_font("loading_main",fontSet,fontFeatures,60)

	engine.create_font("loading_small",fontSet,fontFeatures,14)

	local el = gui.create("WITexturedRect",self,0,0,self:GetWidth(),self:GetHeight(),0,0,1,1)
	el:SetMaterial("logo/bg_gradient")

	local elLogo = gui.create("WITexturedRect",self)
	elLogo:SetMaterial("logo/pragma_logo")
	elLogo:SetSize(220,220)
	elLogo:SetPos(120,256)
	elLogo:SetAnchor(0.5,0.5,0.5,0.5)

	local elPfm = gui.create("WIText",self)
	elPfm:SetText("pragma filmmaker")
	elPfm:SetColor(Color.White)
	elPfm:SetFont("loading_main")
	elPfm:SizeToContents()
	elPfm:SetHeight(elPfm:GetHeight() +20)
	elPfm:SetPos(380,300)
	elPfm:SetAnchor(0.5,0.5,0.5,0.5)

	local elText = gui.create("WIText",self)
	elText:SetText("Loading...")
	elText:SetColor(Color.White)
	elText:SetFont("loading_small")
	elText:SizeToContents()
	elText:SetPos(380,elPfm:GetBottom() +30)
	elText:SetAnchor(0.5,0.5,0.5,0.5)
	elText:SetHeight(elText:GetHeight() +10)
	self.m_elText = elText

	self:SetZPos(10000)
	self:SetName("loading_screen")
end
function Element:SetMap(mapName)
	self.m_elText:SetText("Loading map '" .. mapName .. "'...")
	self.m_elText:SizeToContents()
	self.m_elText:SetHeight(self.m_elText:GetHeight() +10)
end
gui.register("WIPFMLoadingScreen",Element)
