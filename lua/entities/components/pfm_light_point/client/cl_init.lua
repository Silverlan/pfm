--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMLightPoint",BaseEntityComponent)

function ents.PFMLightPoint:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self:AddEntityComponent(ents.COMPONENT_LIGHT)
	self:AddEntityComponent(ents.COMPONENT_LIGHT_POINT)
	self:AddEntityComponent("pfm_actor")

	self.m_listeners = {}
end
function ents.PFMLightPoint:OnRemove()
	for _,cb in ipairs(self.m_listeners) do
		if(cb:IsValid()) then cb:Remove() end
	end
end
function ents.PFMLightPoint:Setup(actorData,lightData)
	-- TODO
end
ents.COMPONENT_PFM_LIGHT_POINT = ents.register_component("pfm_light_point",ents.PFMLightPoint)
