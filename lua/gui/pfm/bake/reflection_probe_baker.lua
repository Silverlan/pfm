--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/button.lua")

util.register_class("WIReflectionProbeBaker",gui.PFMButton)
function WIReflectionProbeBaker:OnInitialize()
	gui.PFMButton(self)

	self:SetSize(64,64)
	self:InitializeProgressBar()
	self:SetMouseInputEnabled(true)

	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:SetActor(actorData,entActor)
	self.m_baker = pfm.bake.ReflectionProbeBaker(actorData,entActor)
end
function WIReflectionProbeBaker:OnPressed()
	if(self.m_baking == true) then
		self:Cancel()
		return
	end
	self:StartBake()
end
function WIReflectionProbeBaker:Cancel()
	if(self.m_baking == true) then
		self.m_baker:Clear()
		self:SetText(locale.get_text("pfm_bake_reflection_probe"))
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self.m_baking = false
end
function WIReflectionProbeBaker:OnRemove()
	self:Cancel()
end
function WIReflectionProbeBaker:StartBake()
	self.m_progressBar:SetColor(pfm.get_color_scheme_color("darkGrey"))
	self.m_baker:Start()
	self.m_baking = true
	self:SetText(locale.get_text("cancel"))

	self:SetThinkingEnabled(true)
end
function WIReflectionProbeBaker:OnThink()
	if(self.m_baking ~= true) then return end
	self.m_baker:Poll()
	self.m_progressBar:SetProgress(self.m_baker:GetProgress())

	if(self.m_baker:IsComplete()) then
		self:OnComplete()
	end
end
function WIReflectionProbeBaker:OnComplete()
	if(self.m_baker:IsSuccessful()) then
		local ent = self.m_baker:GetActorEntity()
		local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
		local res = reflC:GenerateFromEquirectangularImage(self.m_baker:GetResult())
		if(res == false) then
			self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
		else
			self.m_progressBar:SetColor(pfm.get_color_scheme_color("green"))
		end
	else
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self.m_baking = false
	self:SetThinkingEnabled(false)
	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:InitializeProgressBar()
	local progressBar = gui.create("WIProgressBar",self)
	progressBar:SetSize(self:GetWidth(),self:GetHeight())
	progressBar:SetPos(0,0)
	progressBar:SetColor(Color.Gray)
	progressBar:SetAnchor(0,0,1,1)
	progressBar:SetZPos(-2)
	progressBar:SetLabelVisible(false)
	self.m_progressBar = progressBar
end
gui.register("WIReflectionProbeBaker",WIReflectionProbeBaker)
