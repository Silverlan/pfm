-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMIKEffectorTarget", BaseEntityComponent)

function ents.PFMIKEffectorTarget:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end

function ents.PFMIKEffectorTarget:OnTick()
	local ikC = util.is_valid(self.m_target) and self.m_target:GetComponent(ents.COMPONENT_IK) or nil
	if ikC == nil then
		return
	end
	local pos = self:GetEntity():GetPos()
	debug.draw_line(pos, pos + Vector(0, 10, 0), Color.Red, 0.1)
	ikC:SetIKEffectorPos(self.m_ikControllerIdx, self.m_effectorIdx, pos)
end

function ents.PFMIKEffectorTarget:SetTargetActor(ent, ikControllerIdx, effectorIdx)
	self.m_target = ent
	self.m_ikControllerIdx = ikControllerIdx
	self.m_effectorIdx = effectorIdx
	local ikC = ent:GetComponent(ents.COMPONENT_IK)
	if ikC ~= nil then
		ikC:SetIKControllerEnabled(ikControllerIdx, true)
	end
end

function ents.PFMIKEffectorTarget:OnEntitySpawn()
	local ent = self:GetEntity()
	ent:SetModel("pfm/texture_sphere")
	ent:SetScale(Vector(0.02, 0.02, 0.02))
end
ents.register_component(
	"pfm_ik_effector_target",
	ents.PFMIKEffectorTarget,
	"pfm",
	ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR
)
