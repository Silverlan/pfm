--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.DebugIkControls", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
	self.m_controlEnts = {}
end

function Component:OnRemove()
	util.remove(self.m_controlEnts)
end

function Component:OnEntitySpawn()
	local ent = self:GetEntity()
	local mdl = ent:GetModel()
	if mdl == nil then
		return
	end
	local skel = mdl:GetSkeleton()
	local ikC = ent:GetComponent(ents.COMPONENT_IK_SOLVER)
	if ikC ~= nil then
		local solver = ikC:GetIkSolver()
		if solver ~= nil then
			local numControls = solver:GetControlCount()
			for i = 0, numControls - 1 do
				local ctrl = solver:GetControl(i)
				local bone = ctrl:GetTargetBone()
				local boneId = (bone ~= nil) and skel:LookupBone(bone:GetName()) or -1
				if boneId ~= -1 then
					local ent = self:GetEntity():CreateChild("entity")
					table.insert(self.m_controlEnts, ent)
					local ikControlC = ent:AddComponent("pfm_ik_control")
					if ikControlC ~= nil then
						ikControlC:SetIkControl(ikC, boneId)
					end
					ent:Spawn()
				end
			end
		end
	end
end
ents.COMPONENT_DEBUG_IK_CONTROLS = ents.register_component("debug_ik_controls", Component)
