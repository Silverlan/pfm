-- SPDX-FileCopyrightText: (c) 2024 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/shaders/pfm/flat.lua")

local Component = util.register_class("ents.DebugMetaRig", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
	self.m_jointLines = {}
end

function Component:OnRemove()
	self:ClearLines()
end

function Component:OnEntitySpawn()
	self:InitializeDebugLines()
end

function Component:ClearLines()
	for _, lineData in ipairs(self.m_jointLines) do
		util.remove({
			lineData.debugLine,
			lineData.debugLineX,
			lineData.debugLineY,
			lineData.debugLineZ,
		})
	end
	self.m_jointLines = {}
end

local BONE_AXIS_LENGTH = 1.0
function Component:InitializeDebugLines()
	self:ClearLines()
	local animC = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if animC == nil then
		return
	end
	local function initialize_debug_lines(metaBoneId, parentMetaBoneId, parentPose)
		local pose = animC:GetMetaBonePose(metaBoneId, math.COORDINATE_SPACE_WORLD)
		if pose ~= nil and parentMetaBoneId ~= nil then
			local drawInfo = debug.DrawInfo()

			drawInfo:SetIgnoreDepthBuffer(true)
			drawInfo:SetColor(util.Color.White)

			local debugLine = debug.draw_line(parentPose:GetOrigin(), pose:GetOrigin(), drawInfo)

			local drawInfoAxis = debug.DrawInfo()
			drawInfoAxis:SetIgnoreDepthBuffer(true)

			local pos = pose:GetOrigin()
			local rot = pose:GetRotation()
			drawInfoAxis:SetColor(util.Color.Red)
			local debugLineX = debug.draw_line(pos, (pos + rot:GetRight() * BONE_AXIS_LENGTH), drawInfoAxis)

			drawInfoAxis:SetColor(util.Color.Lime)
			local debugLineY = debug.draw_line(pos, (pos + rot:GetUp() * BONE_AXIS_LENGTH), drawInfoAxis)

			drawInfoAxis:SetColor(util.Color.Blue)
			local debugLineZ = debug.draw_line(pos, (pos + rot:GetForward() * BONE_AXIS_LENGTH), drawInfoAxis)

			table.insert(self.m_jointLines, {
				debugLine = debugLine,
				parentMetaBoneId = parentMetaBoneId,
				metaBoneId = metaBoneId,
				debugLineX = debugLineX,
				debugLineY = debugLineY,
				debugLineZ = debugLineZ,
			})
		end
		local childIds = game.Model.MetaRig.get_bone_children(metaBoneId)
		for _, childId in ipairs(childIds) do
			initialize_debug_lines(childId, (pose ~= nil) and metaBoneId or parentMetaBoneId, pose or parentPose)
		end
	end
	initialize_debug_lines(game.Model.MetaRig.ROOT_BONE)
end

function Component:OnTick()
	local animC = self:GetEntityComponent(ents.COMPONENT_ANIMATED)
	if animC == nil then
		return
	end

	for _, lineData in ipairs(self.m_jointLines) do
		local parentPose = animC:GetMetaBonePose(lineData.parentMetaBoneId, math.COORDINATE_SPACE_WORLD)
		local pose = animC:GetMetaBonePose(lineData.metaBoneId, math.COORDINATE_SPACE_WORLD)
		if parentPose ~= nil and pose ~= nil then
			if util.is_valid(lineData.debugLine) then
				lineData.debugLine:SetVertexPosition(0, parentPose:GetOrigin())
				lineData.debugLine:SetVertexPosition(1, pose:GetOrigin())
				lineData.debugLine:UpdateVertexBuffer()
			end
		end
		if pose ~= nil then
			local pos = pose:GetOrigin()
			local rot = pose:GetRotation()
			local dbgLines = { lineData.debugLineX, lineData.debugLineY, lineData.debugLineZ }
			local axes = { rot:GetRight(), rot:GetUp(), rot:GetForward() }
			for i = 1, #axes do
				local dbgLine = dbgLines[i]
				local axis = axes[i]
				if util.is_valid(dbgLine) then
					dbgLine:SetVertexPosition(0, pos)
					dbgLine:SetVertexPosition(1, pos + (axis * BONE_AXIS_LENGTH))
					dbgLine:UpdateVertexBuffer()
				end
			end
		end
	end
end
ents.register_component("debug_meta_rig", Component, "debug")
