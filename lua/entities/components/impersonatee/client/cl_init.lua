--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.Impersonatee", BaseEntityComponent)

Component:RegisterMember("ImpostorModel", udm.TYPE_STRING, "", {
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c)
		local actorC = c:GetEntity():GetComponent(ents.COMPONENT_PFM_ACTOR)
		local pm = pfm.get_project_manager()
		local mdlName = c:GetImpostorModel()
		if actorC ~= nil and util.is_valid(pm) and #mdlName > 0 then
			util.retarget.change_actor_model(actorC, mdlName)
		end
	end,
	metaData = {
		rootPath = "models/",
		extensions = asset.get_supported_extensions(asset.TYPE_MODEL),
		stripExtension = true,
	},
})

function Component:__init()
	BaseEntityComponent.__init(self)
end

function Component:OnRemove()
	if util.is_valid(self.m_impostorC) then
		self.m_impostorC:GetEntity():Remove()
	end
	util.remove(self.m_onImpostorModelChanged)
end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:BindEvent(ents.PFMActorComponent.EVENT_ON_VISIBILITY_CHANGED, "OnVisibilityChanged")
end

function Component:GetImpostor()
	return self.m_impostorC
end

function Component:OnVisibilityChanged()
	if self:IsImpersonated() then
		local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
		if renderC ~= nil then
			renderC:SetSceneRenderPass(game.SCENE_RENDER_PASS_NONE)
		end
	end
end

function Component:IsImpersonated()
	if util.is_valid(self.m_impostorC) == false then
		return false
	end
	local renderC = self.m_impostorC:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	return (renderC ~= nil) and (renderC:GetSceneRenderPass() ~= game.SCENE_RENDER_PASS_NONE) or false
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
	self:SetImpostor(impostorC)
	return impostorC
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
end

function Component:SetImpostorModel(mdl)
	local impostorC = self:InitializeImpostor()
	if util.is_valid(impostorC) == false then
		return
	end
	impostorC:GetEntity():SetPose(self:GetEntity():GetPose() * impostorC:GetRelativePose())
	impostorC:GetEntity():SetModel(mdl)
	impostorC:OnAnimationReset()
end
ents.COMPONENT_IMPERSONATEE = ents.register_component("impersonatee", Component)
Component.EVENT_ON_IMPOSTOR_MODEL_CHANGED =
	ents.register_component_event(ents.COMPONENT_IMPERSONATEE, "on_impostor_model_changed")
