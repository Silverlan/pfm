--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.DebugIkVisualizer", BaseEntityComponent)

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self.m_dottedLines = {}
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function Component:SetSolver(solver)
	self.m_solver = solver
end
function Component:GetDottedLine(i)
	if util.is_valid(self.m_dottedLines[i]) then
		return self.m_dottedLines[i]
	end
	local ent = self:GetEntity():CreateChild("debug_dotted_line")
	ent:Spawn()
	ent:SetColor(Color.Red)
	self.m_dottedLines[i] = ent
	return ent
end
function Component:OnRemove()
	util.remove(self.m_dottedLines)
end
function Component:OnTick()
	if self.m_solver == nil then
		return
	end

	local drawInfo = debug.DrawInfo()
	drawInfo:SetColor(Color.Red)
	drawInfo:SetDuration(0.1)
	local numControls = self.m_solver:GetControlCount()
	-- Remove excess dotted lines
	for i = #self.m_dottedLines, numControls + 1 do
		util.remove(self.m_dottedLines[i])
		self.m_dottedLines[i] = nil
	end
	for i = 0, numControls - 1 do
		local ctrl = self.m_solver:GetControl(i)
		local bone = ctrl:GetTargetBone()
		local entLine = self:GetDottedLine(i + 1)
		local lineC = entLine:GetComponent(ents.COMPONENT_DEBUG_DOTTED_LINE)
		assert(lineC ~= nil)
		lineC:SetStartPosition(bone:GetPos())
		lineC:SetEndPosition(ctrl:GetTargetPosition())

		drawInfo:SetOrigin(ctrl:GetTargetPosition())
		debug.draw_point(drawInfo)
	end
end
ents.COMPONENT_DEBUG_IK_VISUALIZER = ents.register_component("debug_ik_visualizer", Component)
