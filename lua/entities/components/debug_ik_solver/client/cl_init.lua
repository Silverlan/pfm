-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/shaders/pfm/flat.lua")

local Component = util.register_class("ents.DebugIkSolver", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	self.m_jointLines = {}
	self.m_boneLines = {}
end

function Component:OnRemove()
	util.remove(self.m_jointLines)
	util.remove(self.m_boneLines)
end

local BONE_AXIS_LENGTH = 1.0
function Component:InitializeDebugLines()
	local ikSolverC = self:GetEntityComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	local ikSolver = ikSolverC:GetIkSolver()
	if ikSolver == nil then
		return
	end
	ikSolverC:Flush()
	local numJoints = ikSolver:GetJointCount()
	util.remove(self.m_jointLines)
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

	util.remove(self.m_boneLines)
	self.m_boneLines = {}
	local numBones = ikSolver:GetBoneCount()
	for i = 1, numBones do
		local bone = ikSolver:GetBone(i - 1)

		local drawInfo = debug.DrawInfo()
		drawInfo:SetIgnoreDepthBuffer(true)

		local pos = bone:GetPos()
		local rot = bone:GetRot()

		drawInfo:SetColor(util.Color.Red)
		local debugLine = debug.draw_line(pose * pos, pose * (pos + rot:GetRight() * BONE_AXIS_LENGTH), drawInfo)
		table.insert(self.m_boneLines, debugLine)

		drawInfo:SetColor(util.Color.Lime)
		local debugLine = debug.draw_line(pose * pos, pose * (pos + rot:GetUp() * BONE_AXIS_LENGTH), drawInfo)
		table.insert(self.m_boneLines, debugLine)

		drawInfo:SetColor(util.Color.Blue)
		local debugLine = debug.draw_line(pose * pos, pose * (pos + rot:GetForward() * BONE_AXIS_LENGTH), drawInfo)
		table.insert(self.m_boneLines, debugLine)
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
	ikSolver:Flush()

	local pose = self:GetEntity():GetPose()
	local numJoints = ikSolver:GetJointCount()
	local numBones = ikSolver:GetBoneCount()
	if numJoints ~= #self.m_jointLines or numBones ~= (#self.m_boneLines / 3) then
		self:InitializeDebugLines()
	end
	for i = 1, numJoints do
		local joint = ikSolver:GetJoint(i - 1)
		local bone0 = joint:GetConnectionA()
		local bone1 = joint:GetConnectionB()
		local line = self.m_jointLines[i]
		if util.is_valid(line) then
			line:SetVertexPosition(0, pose * bone0:GetPos())
			line:SetVertexPosition(1, pose * bone1:GetPos())
			line:UpdateVertexBuffer()
		end
	end
	for i = 1, numBones do
		local bone = ikSolver:GetBone(i - 1)
		local j = (i - 1) * 3 + 1
		local l0 = self.m_boneLines[j]
		local l1 = self.m_boneLines[j + 1]
		local l2 = self.m_boneLines[j + 2]
		if util.is_valid(l0) and util.is_valid(l1) and util.is_valid(l2) then
			local pos = bone:GetPos()
			local rot = bone:GetRot()

			l0:SetVertexPosition(0, pose * pos)
			l0:SetVertexPosition(1, pose * (pos + rot:GetRight() * BONE_AXIS_LENGTH))
			l0:UpdateVertexBuffer()

			l1:SetVertexPosition(0, pose * pos)
			l1:SetVertexPosition(1, pose * (pos + rot:GetUp() * BONE_AXIS_LENGTH))
			l1:UpdateVertexBuffer()

			l2:SetVertexPosition(0, pose * pos)
			l2:SetVertexPosition(1, pose * (pos + rot:GetForward() * BONE_AXIS_LENGTH))
			l2:UpdateVertexBuffer()
		end
	end
end
ents.register_component("debug_ik_solver", Component, "debug")
