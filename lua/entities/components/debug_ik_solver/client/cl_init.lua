--[[
    Copyright (C) 2024 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/shaders/pfm/pfm_flat.lua")

local Component = util.register_class("ents.DebugIkSolver", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function Component:OnEntitySpawn()
	self:InitializeDebugLines()
end

function Component:OnRemove()
	util.remove(self.m_jointLines)
end

function Component:InitializeDebugLines()
	local ikSolverC = self:GetEntityComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	local ikSolver = ikSolverC:GetIkSolver()
	if ikSolver == nil then
		return
	end
	local numJoints = ikSolver:GetJointCount()
	self.m_jointLines = {}
	local pose = self:GetEntity():GetPose()
	for i = 1, numJoints do
		local joint = ikSolver:GetJoint(i - 1)
		local bone0 = joint:GetConnectionA()
		local bone1 = joint:GetConnectionB()
		local drawInfo = debug.DrawInfo()

		drawInfo:SetIgnoreDepthBuffer(true)
		drawInfo:SetColor(util.Color.Lime)

		-- Draw line
		local debugLine = debug.draw_line(pose * bone0:GetPos(), pose * bone1:GetPos(), drawInfo)
		table.insert(self.m_jointLines, debugLine)
	end
end

function Component:OnTick()
	local ikSolverC = self:GetEntityComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	local ikSolver = ikSolverC:GetIkSolver()
	if ikSolver == nil then
		return
	end

	local pose = self:GetEntity():GetPose()
	local numJoints = ikSolver:GetJointCount()
	for i = 1, numJoints do
		local joint = ikSolver:GetJoint(i - 1)
		local bone0 = joint:GetConnectionA()
		local bone1 = joint:GetConnectionB()
		local line = self.m_jointLines[i]
		line:SetVertexPosition(0, pose * bone0:GetPos())
		line:SetVertexPosition(1, pose * bone1:GetPos())
		line:UpdateVertexBuffer()
	end
end
ents.COMPONENT_DEBUG_IK_SOLVER = ents.register_component("debug_ik_solver", Component)
