--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMLightPoint",BaseEntityComponent)

function ents.PFMLightPoint:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_LIGHT_POINT)
	self:AddEntityComponent("pfm_light")
end
function ents.PFMLightPoint:Setup(actorData,lightData)
	local lightC = self:GetEntity():GetComponent("pfm_light")
	if(lightC ~= nil) then lightC:Setup(actorData,lightData) end
end
ents.COMPONENT_PFM_LIGHT_POINT = ents.register_component("pfm_light_point",ents.PFMLightPoint)
