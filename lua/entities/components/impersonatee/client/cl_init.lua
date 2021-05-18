--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.Impersonatee",BaseEntityComponent)

function ents.Impersonatee:__init()
	BaseEntityComponent.__init(self)
end

function ents.Impersonatee:OnRemove()
	if(util.is_valid(self.m_impostorC)) then self.m_impostorC:GetEntity():Remove() end
	util.remove(self.m_onImpostorModelChanged)
end

function ents.Impersonatee:Initialize()
	BaseEntityComponent.Initialize(self)
end

function ents.Impersonatee:GetImpostor() return self.m_impostorC end

function ents.Impersonatee:IsImpersonated()
	if(util.is_valid(self.m_impostorC) == false) then return false end
	local renderC = self.m_impostorC:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	return (renderC ~= nil) and (renderC:GetRenderMode() ~= ents.RenderComponent.RENDERMODE_NONE) or false
end

function ents.Impersonatee:InitializeImpostor()
	if(util.is_valid(self.m_impostorC)) then return self.m_impostorC end
	local entThis = self:GetEntity()
	local ent = ents.create("impostor")
	if(util.is_valid(ent) == false) then return end
	local impostorC = ent:GetComponent(ents.COMPONENT_IMPOSTOR)
	if(impostorC == nil) then
		util.remove(ent)
		return
	end
	ent:Spawn()
	self:SetImpostor(impostorC)
	return impostorC
end

function ents.Impersonatee:SetImpostor(impostorC)
	if(util.is_valid(impostorC) == util.is_valid(self.m_impostorC) and util.is_same_object(impostorC,self.m_impostorC)) then return end
	util.remove(self.m_onImpostorModelChanged)
	self.m_impostorC = impostorC
	if(util.is_valid(impostorC) == false) then
		self:BroadcastEvent(ents.Impersonatee.EVENT_ON_IMPOSTOR_MODEL_CHANGED,{})
		return
	end
	impostorC:Impersonate(self:GetEntity())
	local mdlC = impostorC:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if(mdlC ~= nil) then
		self.m_onImpostorModelChanged = mdlC:AddEventCallback(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,function(mdl)
			self:BroadcastEvent(ents.Impersonatee.EVENT_ON_IMPOSTOR_MODEL_CHANGED,{mdl})
		end)
		self:BroadcastEvent(ents.Impersonatee.EVENT_ON_IMPOSTOR_MODEL_CHANGED,{mdlC:GetModel()})
	end
end

function ents.Impersonatee:SetImpostorModel(mdl)
	local impostorC = self:InitializeImpostor()
	if(util.is_valid(impostorC) == false) then return end
	impostorC:GetEntity():SetPose(self:GetEntity():GetPose() *impostorC:GetRelativePose())
	impostorC:GetEntity():SetModel(mdl)
end
ents.COMPONENT_IMPERSONATEE = ents.register_component("impersonatee",ents.Impersonatee)
ents.Impersonatee.EVENT_ON_IMPOSTOR_MODEL_CHANGED = ents.register_component_event(ents.COMPONENT_IMPERSONATEE,"on_impostor_model_changed")
