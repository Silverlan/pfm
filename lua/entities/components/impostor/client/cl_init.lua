--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.Impostor",BaseEntityComponent)

function ents.Impostor:__init()
	BaseEntityComponent.__init(self)
end

function ents.Impostor:OnRemove()
	self:UpdateModel() -- Make sure to reset the impersonatee
end

function ents.Impostor:Initialize()
	BaseEntityComponent.Initialize(self)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:BindEvent(ents.AnimatedComponent.EVENT_ON_ANIMATION_RESET,"OnAnimationReset")
end

function ents.Impostor:Impersonate(ent)
	local impersonateeC = ent:GetComponent("impersonatee")
	if(impersonateeC == self.m_impersonateeC) then return end
	impersonateeC = ent:AddComponent("impersonatee")
	if(impersonateeC == nil) then return end
	self.m_impersonateeC = impersonateeC

	if(util.is_valid(self.m_entImpostor)) then return self.m_entImpostor end
	local entImpersonatee = impersonateeC:GetEntity()
	local entThis = self:GetEntity()
	entThis:SetPose(entImpersonatee:GetPose())
	entThis:SetName(entImpersonatee:GetName() .. "_impostor")

	local renderCImpersonatee = entImpersonatee:GetComponent(ents.COMPONENT_RENDER)
	local renderCThis = entThis:GetComponent(ents.COMPONENT_RENDER)
	if(renderCImpersonatee ~= nil and renderCThis ~= nil) then renderCThis:SetCastShadows(renderCImpersonatee:ShouldCastShadows()) end

	local charComponents = {ents.COMPONENT_FLEX,ents.COMPONENT_VERTEX_ANIMATED,ents.COMPONENT_EYE}
	for _,c in ipairs(charComponents) do
		if(entImpersonatee:HasComponent(c)) then entThis:AddComponent(c) end
	end

	local attC = entThis:AddComponent(ents.COMPONENT_ATTACHABLE)
	if(attC ~= nil) then
		local attInfo = ents.AttachableComponent.AttachmentInfo()
		attInfo.flags = bit.bor(ents.AttachableComponent.FATTACHMENT_MODE_UPDATE_EACH_FRAME,ents.AttachableComponent.FATTACHMENT_MODE_SNAP_TO_ORIGIN)
		attC:AttachToEntity(entImpersonatee)
	end
	impersonateeC:SetImpostor(self)
	return entThis
end

function ents.Impostor:GetImpersonatee() return self.m_impersonateeC end

function ents.Impostor:OnAnimationReset() self:UpdateModel(self:GetEntity():GetModel()) end

function ents.Impostor:UpdateModel(mdl)
	local impersonateeC = self:GetImpersonatee()
	if(util.is_valid(impersonateeC) == false) then return end

	local renderCImpersonatee = impersonateeC:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if(renderCImpersonatee ~= nil) then renderCImpersonatee:SetRenderMode((mdl ~= nil) and ents.RenderComponent.RENDERMODE_NONE or ents.RenderComponent.RENDERMODE_WORLD) end

	local ent = self:GetEntity()
	local retargetC = ent:AddComponent("retarget_rig")
	if(retargetC ~= nil) then retargetC:RigToActor(impersonateeC:GetEntity()) end

	local headTarget = impersonateeC:GetEntity()
	local headhackC = headTarget:GetComponent("headhack")
	if(headhackC ~= nil) then
		local headhackHead = headhackC:GetHeadTarget()
		if(util.is_valid(headhackHead)) then headTarget = headhackHead end
	end
	local retargetMorphC = ent:AddComponent("retarget_morph")
	if(retargetMorphC ~= nil) then retargetMorphC:RigToActor(headTarget) end
end
ents.COMPONENT_IMPOSTOR = ents.register_component("impostor",ents.Impostor)
