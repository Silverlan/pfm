--[[
	Copyright (C) 2021 Silverlan

	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("base_baker.lua")

util.register_class("WIReflectionProbeBaker",WIBaseBaker)
function WIReflectionProbeBaker:OnInitialize()
	WIBaseBaker.OnInitialize(self)

	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:SetActor(actorData,entActor)
	WIBaseBaker.SetActor(self,actorData,entActor)
	self.m_baker = pfm.bake.ReflectionProbeBaker(actorData,entActor)
end
function WIBaseBaker:Reset()
	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
function WIReflectionProbeBaker:StartBaker() self.m_baker:Start() end
function WIReflectionProbeBaker:CancelBaker() self.m_baker:Clear() end
function WIReflectionProbeBaker:PollBaker() self.m_baker:Poll() end
function WIReflectionProbeBaker:IsBakerComplete() return self.m_baker:IsComplete() end
function WIReflectionProbeBaker:IsBakerSuccessful() return self.m_baker:IsSuccessful() end
function WIReflectionProbeBaker:GetBakerProgress() return self.m_baker:GetProgress() end
function WIReflectionProbeBaker:FinalizeBaker()
	local ent = self:GetActorEntity()
	local reflC = ent:GetComponent(ents.COMPONENT_REFLECTION_PROBE)
	return reflC:GenerateFromEquirectangularImage(self.m_baker:GetResult())
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
	self:SetText(locale.get_text("pfm_bake_reflection_probe"))
end
gui.register("WIReflectionProbeBaker",WIReflectionProbeBaker)
