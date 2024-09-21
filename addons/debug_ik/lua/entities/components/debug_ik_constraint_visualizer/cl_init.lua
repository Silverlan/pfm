--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include_component("debug_ik_constraint_visualizer_ball_socket")
include_component("debug_ik_constraint_visualizer_hinge")

local Component = util.register_class("ents.DebugIkConstraintVisualizer", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_items = {}
end
function Component:OnRemove()
	util.remove(self.m_items)
end
function Component:SetJoint(solver, jointIndex, swingLimitIndex, hingeIndex)
	local ballSocket = solver:GetJoint(jointIndex)
	local swingLimit = solver:GetJoint(swingLimitIndex)
	if
		ballSocket:GetType() ~= ik.Joint.TYPE_BALL_SOCKET_JOINT
		or (
			swingLimit:GetType() ~= ik.Joint.TYPE_SWING_LIMIT
			and swingLimit:GetType() ~= ik.Joint.TYPE_ELLIPSE_SWING_LIMIT
		)
	then
		return
	end
	self.m_solver = solver
	self.m_jointIndex = jointIndex
	self.m_hingeIndex = hingeIndex
	self.m_swingLimitIndex = swingLimitIndex
end
function Component:GetSolverJoint()
	return self.m_solver, self.m_jointIndex, self.m_swingLimitIndex, self.m_hingeIndex
end
function Component:OnEntitySpawn()
	self:Reload()
end
function Component:Reload()
	if self.m_solver == nil or self:GetEntity():IsSpawned() == false then
		return
	end
	util.remove(self.m_items)
	self:GetEntity():RemoveComponent(ents.COMPONENT_DEBUG_IK_CONSTRAINT_VISUALIZER_BALL_SOCKET)
	self:GetEntity():RemoveComponent(ents.COMPONENT_DEBUG_IK_CONSTRAINT_VISUALIZER_HINGE)
	self.m_items = {}

	local joint = self.m_solver:GetJoint(self.m_jointIndex)
	local jointNext = self.m_solver:GetJoint(self.m_jointIndex + 1)
	if joint == nil or jointNext == nil then
		return
	end
	local type = joint:GetType()
	local nextType = jointNext:GetType()
	if type == ik.Joint.TYPE_BALL_SOCKET_JOINT then
		if nextType == ik.Joint.TYPE_SWIVEL_HINGE_JOINT or nextType == ik.Joint.TYPE_REVOLUTE_JOINT then
			self:AddEntityComponent(ents.COMPONENT_DEBUG_IK_CONSTRAINT_VISUALIZER_HINGE)
		else
			self:AddEntityComponent(ents.COMPONENT_DEBUG_IK_CONSTRAINT_VISUALIZER_BALL_SOCKET)
		end
	end
end
function Component:CreateTextElement(text, col)
	local el = gui.create("WIText")
	el:SetText(text)
	if col ~= nil then
		el:SetColor(col)
	end
	el:SizeToContents()

	local ent = self:GetEntity():CreateChild("gui_3d")
	ent:SyncScenes(self:GetEntity())
	local guiC = ent:GetComponent(ents.COMPONENT_GUI3D)
	guiC:SetAutoCursorUpdateEnabled(false)
	guiC:SetGUIElement(el)
	guiC:SetUnlit(true)
	guiC:SetClearColor(Color.Clear)
	ent:Spawn()

	ent:SetScale(Vector(10, 10, 10))
	table.insert(self.m_items, ent)
	return ent
end
ents.register_component("debug_ik_constraint_visualizer", Component, "debug")
