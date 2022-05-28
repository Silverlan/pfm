--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/gui/pfm/button.lua")

util.register_class("WIBaseBaker",gui.PFMButton)
function WIBaseBaker:OnInitialize()
	gui.PFMButton.OnInitialize(self)

	self:SetSize(64,64)
	self:InitializeProgressBar()
	self:SetMouseInputEnabled(true)
end
function WIBaseBaker:SetActor(actorData,entActor)
	self.m_actorData = actorData
	self.m_entActor = entActor
end
function WIBaseBaker:GetActorData() return self.m_actorData end
function WIBaseBaker:GetActorEntity() return self.m_entActor end
function WIBaseBaker:OnPressed()
	if(self.m_baking == true) then
		self:Cancel()
		return
	end
	self:StartBake()
end
function WIBaseBaker:Cancel()
	if(self.m_baking == true) then
		self:CancelBaker()
		self.m_progressBar:SetColor(pfm.get_color_scheme_color("red"))
	end
	self.m_baking = false
end
function WIBaseBaker:OnRemove()
	self:Cancel()
end
function WIBaseBaker:StartBake()
	self.m_progressBar:SetColor(pfm.get_color_scheme_color("darkGrey"))
	self:StartBaker()
	self.m_baking = true
	self:SetText(locale.get_text("cancel"))

	self:SetThinkingEnabled(true)
end
function WIBaseBaker:OnThink()
	if(self.m_baking ~= true) then return end
	self:PollBaker()
	self.m_progressBar:SetProgress(self:GetBakerProgress())

	if(self:IsBakerComplete()) then
		self.m_baking = false
		self:SetThinkingEnabled(false)
		self:OnComplete()
	end
end
function WIBaseBaker:OnComplete()
	if(self:IsBakerSuccessful()) then
		local res = self:FinalizeBaker()
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
end
function WIBaseBaker:InitializeProgressBar()
	local progressBar = gui.create("WIProgressBar",self)
	progressBar:SetSize(self:GetWidth(),self:GetHeight())
	progressBar:SetPos(0,0)
	progressBar:SetColor(Color.Gray)
	progressBar:SetAnchor(0,0,1,1)
	progressBar:SetZPos(-2)
	progressBar:SetLabelVisible(false)
	self.m_progressBar = progressBar
end
function WIBaseBaker:FinalizeBaker() return false end
function WIBaseBaker:Reset() end
function WIBaseBaker:StartBaker() end
function WIBaseBaker:CancelBaker() end
function WIBaseBaker:PollBaker() end
function WIBaseBaker:IsBakerComplete() return false end
function WIBaseBaker:IsBakerSuccessful() return false end
function WIBaseBaker:GetBakerProgress() return 1.0 end
