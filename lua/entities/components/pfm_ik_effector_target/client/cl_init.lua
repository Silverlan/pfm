--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMIKEffectorTarget",BaseEntityComponent)

function ents.PFMIKEffectorTarget:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.PFMIKEffectorTarget:OnTick()
	local ikC = util.is_valid(self.m_target) and self.m_target:GetComponent(ents.COMPONENT_IK) or nil
	if(ikC == nil) then return end
	local pos = self:GetEntity():GetPos()
	debug.draw_line(pos,pos +Vector(0,10,0),Color.Red,0.1)
	ikC:SetIKEffectorPos(self.m_ikControllerIdx,self.m_effectorIdx,pos)
end

function ents.PFMIKEffectorTarget:SetTargetActor(ent,ikControllerIdx,effectorIdx)
	self.m_target = ent
	self.m_ikControllerIdx = ikControllerIdx
	self.m_effectorIdx = effectorIdx
	local ikC = ent:GetComponent(ents.COMPONENT_IK)
	if(ikC ~= nil) then
		ikC:SetIKControllerEnabled(ikControllerIdx,true)
	end
end

function ents.PFMIKEffectorTarget:OnEntitySpawn()
	local ent = self:GetEntity()
	ent:SetModel("pfm/texture_sphere")
	ent:SetScale(Vector(0.02,0.02,0.02))
end
ents.COMPONENT_PFM_IK_EFFECTOR_TARGET = ents.register_component("pfm_ik_effector_target",ents.PFMIKEffectorTarget)
