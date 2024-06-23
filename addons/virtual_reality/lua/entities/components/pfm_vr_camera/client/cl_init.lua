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

local g_vrModuleLoaded = false
local g_vrModuleReady = false
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent("pfm_camera")
	if g_vrModuleLoaded == false then -- Lazy initialization
		g_vrModuleLoaded = true
		if pfm.util.init_openvr() == false then
			return
		end

		debug.start_profiling_task("vr_initialize_openvr")
		local result = openvr.initialize()
		debug.stop_profiling_task()
		if result ~= openvr.INIT_ERROR_NONE then
			self:LogErr("Unable to initialize openvr library: " .. openvr.init_error_to_string(result))
			return
		end
		g_vrModuleReady = true
	end
	if g_vrModuleReady ~= true then
		return
	end
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_ON, "OnTurnOn")
	self:BindEvent(ents.ToggleComponent.EVENT_ON_TURN_OFF, "OnTurnOff")
	self:BindEvent(ents.PFMCamera.EVENT_ON_ACTIVE_STATE_CHANGED, "OnActiveStateChanged")

	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if toggleC == nil or toggleC:IsTurnedOn() then
		self:OnTurnOn()
	end
end
-- If enabled, the VR body will be simulated even if the camera isn't active. For debugging
-- purpose only.
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

	if self.m_vrBodyEnabledWhenDisabled then
		active = true
	end
	if util.is_valid(self.m_vrPovControllerC) then
		self.m_vrPovControllerC:SetEnabled(active)
	end
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

	local povC = self:GetEntity():AddComponent("pov_camera")
	if povC ~= nil then
		povC:SetEnabled(false)
	end
	if util.is_valid(self.m_vrPovControllerC) then
		self.m_vrPovControllerC:SetEnabled(false)
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
		vrPovControllerC:SetEnabled(true)
		vrPovControllerC:SetCamera(self:GetEntity())
		vrPovControllerC:SetPov(self:IsPov())
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
ents.COMPONENT_PFM_VR_CAMERA = ents.register_component("pfm_vr_camera", Component)
