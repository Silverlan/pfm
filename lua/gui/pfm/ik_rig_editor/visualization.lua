--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Element = gui.IkRigEditor
function Element:UpdateDebugVisualization()
	util.remove(self.m_constraintVisualizers)
	local function iterate_items(item)
		if item.__jointType ~= nil and item.__jointType ~= util.IkRigConfig.Constraint.TYPE_FIXED then
			local icon = item:GetIcons()[1]
			if util.is_valid(icon) then
				local parent = item:GetParentItem()
				local boneName = parent:GetIdentifier()
				if boneName ~= nil and item.__visualizationEnabled then
					local solver = self:GetIkSolver()
					if solver ~= nil then
						local joint, jointIndex = self:FindSolverJoint(solver, boneName, item.__jointType)
						if joint ~= nil then
							self:AddJointVisualization(jointIndex)
						end
					end
				end
			end
		end

		for _, child in ipairs(item:GetItems()) do
			if child:IsValid() then
				iterate_items(child)
			end
		end
	end
	local root = self.m_skelTree:GetRoot()
	if root:IsValid() then
		iterate_items(root)
	end
end
function Element:AddJointVisualization(jointIdx)
	local entActor = self.m_mdlView:GetEntity(1)
	local ikSolverC = entActor:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikSolverC == nil then
		return
	end
	local solver = ikSolverC:GetIkSolver()
	if solver == nil then
		return
	end
	local jointNextIndex = jointIdx + 1
	local jointNext = solver:GetJoint(jointNextIndex)
	if jointNext == nil then
		return
	end
	local hingeIndex
	if jointNext:GetType() == ik.Joint.TYPE_REVOLUTE_JOINT then
		hingeIndex = jointNextIndex
		jointNextIndex = jointNextIndex + 1
	end

	local ent = ents.create("debug_ik_constraint_visualizer")
	table.insert(self.m_constraintVisualizers, ent)
	ent:RemoveFromScene(game.get_scene())
	ent:AddToScene(self.m_mdlView:GetScene())
	ent:GetComponent("debug_ik_constraint_visualizer"):SetJoint(solver, jointIdx, jointNextIndex, hingeIndex)
	ent:Spawn()
end
