--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.Impostor",BaseEntityComponent)

function Component:__init()
	BaseEntityComponent.__init(self)
end

function Component:OnRemove()
	self:UpdateModel() -- Make sure to reset the impersonatee
	local impersonateeC = self:GetImpersonatee()
	if(util.is_valid(impersonateeC)) then impersonateeC:SetImpostor() end
end

function Component:SetRelativePose(pose)
	self.m_relPose = pose
	local impersonateeC = self:GetImpersonatee()
	if(util.is_valid(impersonateeC)) then
		local absPose = impersonateeC:GetEntity():GetPose()
		absPose:SetScale(self:GetEntity():GetScale())
		self:GetEntity():SetPose(absPose *pose)
	end
end
function Component:GetRelativePose() return self.m_relPose end

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self:SetRelativePose(math.Transform())
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED)
	self:BindEvent(ents.AnimatedComponent.EVENT_ON_ANIMATION_RESET,"OnAnimationReset")
end

function Component:Impersonate(ent)
	local impersonateeC = ent:GetComponent("impersonatee")
	if(impersonateeC == self.m_impersonateeC) then return end
	impersonateeC = ent:AddComponent("impersonatee")
	if(impersonateeC == nil) then return end
	self.m_impersonateeC = impersonateeC

	if(util.is_valid(self.m_entImpostor)) then return self.m_entImpostor end
	local entImpersonatee = impersonateeC:GetEntity()
	local entThis = self:GetEntity()
	local pose = entImpersonatee:GetPose()
	pose:SetScale(entThis:GetScale())
	pose = pose *self.m_relPose
	entThis:SetPose(pose)
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
	self:OnAnimationReset()
	return entThis
end

function Component:GetImpersonatee() return self.m_impersonateeC end

function Component:OnAnimationReset() self:UpdateModel(self:GetEntity():GetModel()) end

function Component:UpdateModel(mdl)
	local impersonateeC = self:GetImpersonatee()
	if(util.is_valid(impersonateeC) == false) then return end

	if(mdl == impersonateeC:GetEntity():GetModel()) then mdl = nil end

	local renderModeImpostor = (mdl ~= nil) and game.SCENE_RENDER_PASS_WORLD or game.SCENE_RENDER_PASS_NONE
	local renderModeImpostee = (renderModeImpostor == game.SCENE_RENDER_PASS_WORLD) and game.SCENE_RENDER_PASS_NONE or game.SCENE_RENDER_PASS_WORLD

	local entImpersonatee = impersonateeC:GetEntity()
	local tEnts = {}
	local c = entImpersonatee:GetComponent(ents.COMPONENT_COMPOSITE)
	if(c ~= nil) then tEnts = c:GetEntities() end
	table.insert(tEnts,entImpersonatee)
	for _,ent in ipairs(tEnts) do
		local renderC = ent:GetComponent(ents.COMPONENT_RENDER)
		if(renderC ~= nil) then
			renderC:SetSceneRenderPass(renderModeImpostee)
		end
	end

	local renderC = self:GetEntity():GetComponent(ents.COMPONENT_RENDER)
	if(renderC ~= nil) then renderC:SetSceneRenderPass(renderModeImpostor) end

	local shouldRig = (mdl ~= nil)
	local ent = self:GetEntity()
	local retargetC = ent:AddComponent("retarget_rig")
	if(retargetC ~= nil) then
		if(shouldRig) then retargetC:RigToActor(entImpersonatee)
		else retargetC:Unrig() end
	end

	local headTarget = entImpersonatee
	local headhackC = headTarget:GetComponent("head_controller")
	if(headhackC ~= nil) then
		local headhackHead = headhackC:GetHeadTarget()
		if(util.is_valid(headhackHead)) then headTarget = headhackHead end
	end
	local retargetMorphC = ent:AddComponent("retarget_morph")
	if(retargetMorphC ~= nil) then
		if(shouldRig) then retargetMorphC:RigToActor(headTarget)
		else retargetMorphC:Unrig() end
	end
end
ents.COMPONENT_IMPOSTOR = ents.register_component("impostor",Component)
