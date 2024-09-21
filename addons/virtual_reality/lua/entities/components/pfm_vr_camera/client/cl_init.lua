--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVRCamera", BaseEntityComponent)

Component:RegisterMember("TargetActor", ents.MEMBER_TYPE_ENTITY, "", {
	onChange = function(c)
		c:UpdateTargetActor()
	end,
})
Component:RegisterMember("Pov", ents.MEMBER_TYPE_BOOLEAN, true, {
	onChange = function(self)
		self:UpdatePovState()
	end,
}, "def+is")
Component:RegisterMember("UpperBodyOnly", udm.TYPE_BOOLEAN, true, {}, "def+is")

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("pfm_camera")
	local result, msg = util.initialize_vr()
	if result == false then
		self:LogErr("Failed to initialize vr: {}", msg)
		self:GetEntity():RemoveSafely()
		return
	end

	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON, "OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF, "OnTurnOff")
	self:BindEvent(ents.PFMCamera.EVENT_ON_ACTIVE_STATE_CHANGED, "OnActiveStateChanged")

	self.m_isActive = false
	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if toggleC == nil or toggleC:IsTurnedOn() then
		self:OnTurnOn()
		self:OnActiveStateChanged(true)
	end
end
-- If enabled, the VR body will be simulated even if the camera isn't active. For debugging
-- purposes only.
function Component:SetVrBodyEnabledWhenDisabled(enabled)
	self.m_vrBodyEnabledWhenDisabled = enabled
end
function Component:OnActiveStateChanged(active)
	if ents.COMPONENT_PFM_VR_MANAGER ~= nil then
		local entManager, managerC = ents.citerator(ents.COMPONENT_PFM_VR_MANAGER)()
		if managerC ~= nil then
			managerC:SetIkTrackingEnabled(active)
		end
	end

	self.m_active = active
	self:UpdatePovControllerAvailability()
end
function Component:UpdatePovControllerAvailability()
	if util.is_valid(self.m_vrPovControllerC) == false then
		return
	end
	local active = self.m_active
	if self.m_vrBodyEnabledWhenDisabled then
		active = true
	end
	self.m_vrPovControllerC:SetActive(active or false)
end
function Component:UpdateTargetActor()
	local targetActor = self:GetTargetActor()
	if util.is_valid(targetActor) then
		self:SetAnimationTarget(targetActor)
	else
		self:ClearAnimationTarget()
	end
end
function Component:ClearAnimationTarget()
	util.remove(self.m_cbUpdateCameraPose)
	util.remove(self.m_cbPovControllerAvail)

	local povC = self:GetEntity():AddComponent("pov_camera")
	if povC ~= nil then
		povC:SetEnabled(false)
	end
	if util.is_valid(self.m_vrPovControllerC) then
		self.m_vrPovControllerC:SetActive(false)
	end
	if util.is_valid(self.m_animationTarget) then
		self.m_animationTarget:RemoveComponent("vr_pov_controller")
	end
end

function Component:GetBodyTarget()
	local ent = self.m_animationTarget
	if util.is_valid(ent) == false then
		return
	end
	local imposteeC = ent:GetComponent("impersonatee")
	if imposteeC == nil then
		return ent
	end
	local impostorC = imposteeC:GetImpostor()
	return util.is_valid(impostorC) and impostorC:GetEntity() or ent
end

function Component:SetAnimationTarget(ent)
	self:ClearAnimationTarget()

	local cam = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if cam == nil then
		self:LogErr("Cannot apply animation target: Component is not part of a camera!")
		return
	end
	local povC = self:GetEntity():AddComponent("pov_camera")
	povC:SetEnabled(true)

	self.m_animationTarget = ent

	ent:PlayAnimation("reference")

	local entHmd, hmdC = ents.citerator(ents.COMPONENT_VR_HMD)()
	if hmdC ~= nil then
		local vrPovControllerC = self:GetBodyTarget():AddComponent("vr_pov_controller")
		vrPovControllerC:SetHMD(entHmd)
		vrPovControllerC:SetActive(true)
		vrPovControllerC:SetCamera(self:GetEntity())
		vrPovControllerC:SetPov(self:IsPov())
		vrPovControllerC:SetUpperBodyOnly(self:IsUpperBodyOnly())
		self.m_cbPovControllerAvail = vrPovControllerC:AddEventCallback(
			ents.VrPovController.EVENT_ON_UPDATE_AVAILABILITY,
			function()
				self:UpdatePovControllerAvailability()
			end
		)
		self.m_vrPovControllerC = vrPovControllerC
	end
end
function Component:UpdatePovState()
	if util.is_valid(self.m_vrPovControllerC) then
		self.m_vrPovControllerC:SetPov(self:IsPov())
	end
end
function Component:OnRemove()
	self:ClearAnimationTarget()
	self:OnTurnOff()
end
function Component:OnTurnOn() end
function Component:OnTurnOff() end
ents.register_component("pfm_vr_camera", Component, "vr")
