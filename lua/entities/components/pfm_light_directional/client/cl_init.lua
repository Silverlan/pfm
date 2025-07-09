-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMLightDirectional", BaseEntityComponent)

function ents.PFMLightDirectional:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LIGHT)
	self:AddEntityComponent(ents.COMPONENT_LIGHT_DIRECTIONAL)
	self:AddEntityComponent("pfm_actor")
	self:AddEntityComponent("pfm_light")

	self.m_listeners = {}
end
function ents.PFMLightDirectional:OnRemove()
	for _, cb in ipairs(self.m_listeners) do
		if cb:IsValid() then
			cb:Remove()
		end
	end
end
function ents.PFMLightDirectional:Setup(actorData, lightData)
	-- TODO
end
ents.register_component("pfm_light_directional", ents.PFMLightDirectional, "rendering/lighting")
