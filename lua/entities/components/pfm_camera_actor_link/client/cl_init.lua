--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMCameraActorLink", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_listeners = {}
	self:BindEvent(ents.TransformComponent.EVENT_ON_POSE_CHANGED, "OnPoseChanged")
	local camC = self:GetEntityComponent(ents.COMPONENT_CAMERA)
	if camC ~= nil then
		table.insert(
			self.m_listeners,
			camC:GetFOVProperty():AddCallback(function()
				self:OnPoseChanged()
			end)
		)
	end
end
function Component:OnRemove()
	local pm = pfm.get_project_manager()
	local vp = util.is_valid(pm) and pm:GetViewport() or nil
	if util.is_valid(self.m_targetActor) and util.is_valid(vp) then
		local newPose = self:GetEntity():GetPose()
		local pfmActorC = self.m_targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
		if pfmActorC ~= nil then
			vp:ApplyPoseToKeyframeAnimation(pfmActorC:GetActorData(), self.m_origPose, {
				position = newPose:GetOrigin(),
				rotation = newPose:GetRotation(),
			})
		end
	end
	util.remove(self.m_listeners)
end
function Component:SetTargetActor(actor)
	if util.is_valid(actor) and actor == self:GetEntity() then
		return
	end
	self.m_targetActor = actor
	self.m_origPose = actor:GetPose()
end
function Component:OnPoseChanged()
	if util.is_valid(self.m_targetActor) == false then
		return
	end
	local pm = tool.get_filmmaker()
	local actorC = self.m_targetActor:GetComponent(ents.COMPONENT_PFM_ACTOR)
	if actorC == nil then
		return
	end
	local pose = self:GetEntity():GetPose()
	self.m_targetActor:SetPose(pose)
	pm:SetActorTransformProperty(actorC, "position", pose:GetOrigin(), true)
	pm:SetActorTransformProperty(actorC, "rotation", pose:GetRotation(), true)
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if camC == nil then
		return
	end
	local lightC = self.m_targetActor:GetComponent(ents.COMPONENT_LIGHT_SPOT)
	if lightC ~= nil then
		lightC:SetOuterConeAngle(camC:GetFOV())
		pm:SetActorGenericProperty(actorC, "ec/light_spot/outerConeAngle", camC:GetFOV(), udm.TYPE_FLOAT)
	end
	local camTargetC = self.m_targetActor:GetComponent(ents.COMPONENT_CAMERA)
	if camTargetC ~= nil then
		camTargetC:SetFOV(camC:GetFOV())
		pm:SetActorGenericProperty(actorC, "ec/camera/fov", camC:GetFOV(), udm.TYPE_FLOAT)
	end
end
ents.register_component("pfm_camera_actor_link", Component, "pfm")
