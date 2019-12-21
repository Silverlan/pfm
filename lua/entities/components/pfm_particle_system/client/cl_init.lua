--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMParticleSystem",BaseEntityComponent)

function ents.PFMParticleSystem:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	self:AddEntityComponent("pfm_actor")

	self.m_listeners = {}
end
function ents.PFMParticleSystem:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
end
function ents.PFMParticleSystem:GetParticleData() return self.m_particleData end
function ents.PFMParticleSystem:Setup(actorData,particleData)
	self.m_particleData = particleData

	local ent = self:GetEntity()
	local def = particleData:GetDefinition()
	ent:SetKeyValue("maxparticles",tostring(def:GetMaxParticles()))
	ent:SetKeyValue("material",def:GetMaterial())
	ent:SetKeyValue("radius",tostring(def:GetRadius()))
	ent:SetKeyValue("lifetime",tostring(def:GetLifetime()))
	ent:SetKeyValue("color",tostring(def:GetColor()))
	ent:SetKeyValue("soft_particles",tostring(def:ShouldSortParticles()))

	for _,rendererData in ipairs(def:GetRenderers():GetTable()) do
		print("Renderer: ",rendererData)
	end
	for _,operatorData in ipairs(def:GetOperators():GetTable()) do
		print("Operator: ",operatorData)
	end
	for _,initializerData in ipairs(def:GetInitializers():GetTable()) do
		print("Initializer: ",initializerData)
	end

	local ptC = ent:GetComponent(ents.COMPONENT_PARTICLE_SYSTEM)
	if(ptC ~= nil) then
		ptC:Start()
	end
end
ents.COMPONENT_PFM_PARTICLE_SYSTEM = ents.register_component("pfm_particle_system",ents.PFMParticleSystem)
