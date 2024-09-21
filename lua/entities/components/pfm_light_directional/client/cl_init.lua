--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

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
ents.register_component("pfm_light_directional", ents.PFMLightDirectional, "pfm")
