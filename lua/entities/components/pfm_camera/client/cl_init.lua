--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMCamera",BaseEntityComponent)

local g_activeCamera = nil
local g_cameraEnabled = false
local g_vrEnabled = false
ents.PFMCamera.get_active_camera = function() return g_activeCamera end
ents.PFMCamera.is_camera_enabled = function() return g_cameraEnabled end
ents.PFMCamera.set_camera_enabled = function(enabled)
	if(enabled) then pfm.log("Enabling camera...",pfm.LOG_CATEGORY_PFM_GAME)
	else pfm.log("Disabling camera...",pfm.LOG_CATEGORY_PFM_GAME) end
	g_cameraEnabled = enabled
	ents.PFMCamera.set_active_camera(g_activeCamera)
end
ents.PFMCamera.set_active_camera = function(cam)
	if(util.is_valid(g_activeCamera)) then
		local toggleC = g_activeCamera:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
		if(toggleC ~= nil) then toggleC:TurnOff() end
		g_activeCamera = nil
	end
	if(util.is_valid(cam) == false) then
		pfm.log("Setting active camera to: None",pfm.LOG_CATEGORY_PFM_GAME)
		return
	end
	pfm.log("Setting active camera to: " .. cam:GetEntity():GetName(),pfm.LOG_CATEGORY_PFM_GAME)
	g_activeCamera = cam
	local toggleC = g_activeCamera:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:SetTurnedOn(g_cameraEnabled) end
	g_activeCamera:UpdateVRView()
end
ents.PFMCamera.set_vr_view_enabled = function(enabled)
	if(enabled) then pfm.log("Enabling VR view...",pfm.LOG_CATEGORY_PFM_GAME)
	else pfm.log("Disabling VR view...",pfm.LOG_CATEGORY_PFM_GAME) end
	g_vrEnabled = enabled
	if(util.is_valid(g_activeCamera)) then
		g_activeCamera:UpdateVRView()
	end
end
ents.PFMCamera.is_vr_view_enabled = function() return g_vrEnabled end

function ents.PFMCamera:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_CAMERA)
	local toggleC = self:AddEntityComponent(ents.COMPONENT_TOGGLE)
	self:AddEntityComponent("pfm_actor")
end
function ents.PFMCamera:UpdateVRView()
	if(ents.PFMCamera.is_vr_view_enabled()) then
		self:GetEntity():AddComponent("pfm_vr_camera")
	else
		self:GetEntity():RemoveComponent("pfm_vr_camera")
	end
end
function ents.PFMCamera:GetCameraData() return self.m_cameraData end
function ents.PFMCamera:Setup(animSet,cameraData)
	self.m_cameraData = cameraData
	local camC = self:GetEntity():GetComponent(ents.COMPONENT_CAMERA)
	if(camC ~= nil) then
		camC:SetNearZ(cameraData:GetZNear())
		camC:SetFarZ(cameraData:GetZFar())
		camC:SetFOV(cameraData:GetFov())
		camC:UpdateProjectionMatrix()
	end
end
function ents.PFMCamera:OnEntitySpawn()
	local toggleC = self:GetEntity():GetComponent(ents.COMPONENT_TOGGLE)
	if(toggleC ~= nil) then toggleC:TurnOff() end
end
ents.COMPONENT_PFM_CAMERA = ents.register_component("pfm_camera",ents.PFMCamera)
