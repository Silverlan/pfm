-- SPDX-FileCopyrightText: (c) 2020 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

util.register_class("ents.PFMLightPoint", BaseEntityComponent)

function ents.PFMLightPoint:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_LIGHT_POINT)
	self:AddEntityComponent("pfm_light")
end
function ents.PFMLightPoint:Setup(actorData, lightData)
	local lightC = self:GetEntity():GetComponent("pfm_light")
	if lightC ~= nil then
		lightC:Setup(actorData, lightData)
	end
end
ents.register_component("pfm_light_point", ents.PFMLightPoint, "rendering/lighting")
