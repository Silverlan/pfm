--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.Impersonatee", BaseEntityComponent)

Component:RegisterMember("ImpostorTarget", ents.MEMBER_TYPE_ENTITY, "", {
	onChange = function(c)
		c:UpdateImpostor()
	end,
})
Component:RegisterMember("Enabled", udm.TYPE_BOOLEAN, true, {
	onChange = function(self)
		if self:IsEnabled() == self.m_curEnabled then
			return
		end
		self.m_curEnabled = self:IsEnabled()
		self:UpdateVisibility()
		self:UpdateAvailability()
	end,
}, "def+is")
function Component:OnRemove()
	util.remove(self.m_ownedImpostor)
	util.remove(self.m_onImpostorModelChanged)
end

function Component:UpdateAvailability()
	local impostorC = self:GetImpostor()
	local retargetRigC = util.is_valid(impostorC) and impostorC:GetEntity():GetComponent(ents.COMPONENT_RETARGET_RIG)
		or nil
	if retargetRigC == nil then
		return
	end
	retargetRigC:SetEnabled(self:IsEnabled())
end

function Component:InitializeImpostor()
	if util.is_valid(self.m_impostorC) then
		return self.m_impostorC
	end
	local entThis = self:GetEntity()
	local ent = ents.create("impostor")
	if util.is_valid(ent) == false then
		return
	end
	local impostorC = ent:GetComponent(ents.COMPONENT_IMPOSTOR)
	if impostorC == nil then
		util.remove(ent)
		return
	end
	ent:Spawn()
	self.m_ownedImpostor = ent
	self:SetImpostor(impostorC)
	return impostorC
end

function Component:SetImpostorModel(mdlName)
	local impostorC = self:InitializeImpostor()
	if util.is_valid(impostorC) == false then
		return
	end
	impostorC:GetEntity():SetPose(self:GetEntity():GetPose() * impostorC:GetRelativePose())
	impostorC:GetEntity():SetModel(mdlName)
	impostorC:OnAnimationReset()
end

function Component:UpdateVisibility(updateIfDisabled)
	if updateIfDisabled == nil then
		updateIfDisabled = true
	end
	local vis = game.SCENE_RENDER_PASS_NONE
	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	local impostorC = self:GetImpostor()
	local renderCImpostor = util.is_valid(impostorC) and impostorC:GetEntity():GetComponent(ents.COMPONENT_RENDER)
		or nil
	if self:IsEnabled() then
		if renderC ~= nil then
			vis = renderC:GetSceneRenderPass()
			renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE)
		end
	elseif renderC ~= nil and updateIfDisabled then
		renderC:SetSceneRenderPass((renderCImpostor ~= nil) and renderCImpostor:GetSceneRenderPass() or vis)
	end

	if renderCImpostor == nil then
		return
	end
	renderCImpostor:SetSceneRenderPass(vis)
end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:BindEvent(ents.PFMActorComponent.EVENT_ON_VISIBILITY_CHANGED, "OnVisibilityChanged")
	self.m_curEnabled = true
end

function Component:GetImpostor()
	return self.m_impostorC
end

function Component:OnVisibilityChanged()
	self:UpdateVisibility(false)
end

function Component:IsImpersonated()
	return util.is_valid(self.m_impostorC) and self:IsEnabled()
end

function Component:UpdateImpostor()
	local impostorTarget = self:GetImpostorTarget()
	local impostorC = util.is_valid(impostorTarget) and impostorTarget:GetComponent(ents.COMPONENT_IMPOSTOR) or nil
	self:SetImpostor(impostorC)
end

function Component:SetImpostor(impostorC)
	if
		util.is_valid(impostorC) == util.is_valid(self.m_impostorC)
		and util.is_same_object(impostorC, self.m_impostorC)
	then
		return
	end
	util.remove(self.m_onImpostorModelChanged)
	self.m_impostorC = impostorC
	if util.is_valid(impostorC) == false then
		self:BroadcastEvent(Component.EVENT_ON_IMPOSTOR_MODEL_CHANGED, {})
		return
	end
	impostorC:Impersonate(self:GetEntity())
	local mdlC = impostorC:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if mdlC ~= nil then
		self.m_onImpostorModelChanged = mdlC:AddEventCallback(ents.ModelComponent.EVENT_ON_MODEL_CHANGED, function(mdl)
			self:BroadcastEvent(Component.EVENT_ON_IMPOSTOR_MODEL_CHANGED, { mdl })
		end)
		self:BroadcastEvent(Component.EVENT_ON_IMPOSTOR_MODEL_CHANGED, { mdlC:GetModel() })
	end

	local retargetRigC = impostorC:GetEntity():GetComponent(ents.COMPONENT_RETARGET_RIG)
	if retargetRigC ~= nil then
		retargetRigC:SetEnabled(self:IsEnabled())
	end
end
ents.COMPONENT_IMPERSONATEE = ents.register_component("impersonatee", Component)
Component.EVENT_ON_IMPOSTOR_MODEL_CHANGED =
	ents.register_component_event(ents.COMPONENT_IMPERSONATEE, "on_impostor_model_changed")
