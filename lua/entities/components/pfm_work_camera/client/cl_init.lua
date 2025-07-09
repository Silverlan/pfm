-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

local Component = util.register_class("ents.PFMWorkCamera", BaseEntityComponent)
Component:RegisterMember("PivotDistance", udm.TYPE_FLOAT, 50.0, {
	onChange = function(self)
		self:UpdatePivotDistance()
	end,
	min = 0.0,
	max = 100000,
})
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:UpdatePivotDistance()
	local viewerCameraC = self:GetEntity():GetComponent(ents.COMPONENT_VIEWER_CAMERA)
	if viewerCameraC == nil then
		return
	end
	viewerCameraC:SetZoom(math.max(self:GetPivotDistance(), 1))
end
function Component:OnRemove()
	util.remove(self.m_cbOnUpdateMovement)
	local entCam = self:GetEntity()
	entCam:RemoveComponent(ents.COMPONENT_VIEWER_CAMERA)
	local observerC = entCam:GetComponent(ents.COMPONENT_OBSERVER)
	if observerC ~= nil then
		observerC:Activate()
	end

	entCam:RemoveComponent(ents.COMPONENT_OBSERVABLE)
	entCam:RemoveComponent(ents.COMPONENT_MOVEMENT)
	entCam:RemoveComponent(ents.COMPONENT_PHYSICS)

	local observerC = entCam:GetComponent(ents.COMPONENT_OBSERVER)
	if observerC ~= nil and util.is_valid(self.m_origObserverTarget) then
		observerC:SetObserverTarget(self.m_origObserverTarget)
	end
end
function Component:OnEntitySpawn()
	local entCam = self:GetEntity()
	entCam:AddComponent("viewer_camera")
	local observerC = entCam:GetComponent(ents.COMPONENT_OBSERVER)
	if observerC ~= nil then
		local observableC = entCam:AddComponent(ents.COMPONENT_OBSERVABLE)
		if observableC ~= nil then
			self.m_origObserverTarget = observerC:GetObserverTarget()
			observerC:SetObserverTarget(observableC)
		end
	end

	local physicsC = entCam:AddComponent(ents.COMPONENT_PHYSICS)
	physicsC:SetCollisionBounds(Vector(-5, -5, -5), Vector(5, 5, 5))
	physicsC:InitializePhysics(phys.TYPE_CAPSULECONTROLLER)
	physicsC:SetMoveType(ents.PhysicsComponent.MOVETYPE_NOCLIP)
	physicsC:SetCollisionFilterGroup(phys.COLLISIONMASK_NO_COLLISION)

	local movementC = entCam:AddComponent(ents.COMPONENT_MOVEMENT)
	-- Smooth camera acceleration
	movementC:SetAccelerationRampUpTime(0.5)
	movementC:SetAcceleration(33.0)
	self.m_cbOnUpdateMovement = movementC:AddEventCallback(ents.MovementComponent.EVENT_ON_UPDATE_MOVEMENT, function()
		self:UpdateMovementProperties()
	end)

	local pl = ents.get_local_player()
	local ent = (pl ~= nil) and pl:GetEntity() or nil
	self.m_actionInputC = (ent ~= nil) and ent:GetComponent(ents.COMPONENT_ACTION_INPUT_CONTROLLER) or nil
end
function Component:UpdateMovementProperties()
	if util.is_valid(self.m_actionInputC) == false then
		return
	end
	local movementC = self:GetEntity():AddComponent(ents.COMPONENT_MOVEMENT)
	local speed = console.get_convar_float("pfm_camera_speed")
	if input.is_shift_key_down() then
		speed = speed * console.get_convar_float("pfm_camera_speed_shift_multiplier")
	end
	movementC:SetSpeed(Vector2(speed, 0))
	movementC:SetDirectionMagnitude(
		ents.MovementComponent.MOVE_DIRECTION_FORWARD,
		self.m_actionInputC:GetActionInputAxisMagnitude(input.ACTION_MOVEFORWARD)
	)
	movementC:SetDirectionMagnitude(
		ents.MovementComponent.MOVE_DIRECTION_BACKWARD,
		self.m_actionInputC:GetActionInputAxisMagnitude(input.ACTION_MOVEBACKWARD)
	)
	movementC:SetDirectionMagnitude(
		ents.MovementComponent.MOVE_DIRECTION_LEFT,
		self.m_actionInputC:GetActionInputAxisMagnitude(input.ACTION_MOVELEFT)
	)
	movementC:SetDirectionMagnitude(
		ents.MovementComponent.MOVE_DIRECTION_RIGHT,
		self.m_actionInputC:GetActionInputAxisMagnitude(input.ACTION_MOVERIGHT)
	)
end
ents.register_component("pfm_work_camera", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
