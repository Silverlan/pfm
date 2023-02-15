--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMLightSpot",BaseEntityComponent)

function ents.PFMLightSpot:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_LIGHT_SPOT)
	self:AddEntityComponent("pfm_light")

	self:BindEvent(ents.PFMActorComponent.EVENT_ON_SELECTION_CHANGED,"OnSelectionChanged")
end
function ents.PFMLightSpot:OnTick()
	self:SetTickPolicy(ents.TICK_POLICY_NEVER)

	local selected = self.m_updateSelectionWireframe
	if(selected and self:GetEntity():HasComponent("pfm_cone_wireframe") == false) then
		local c = self:AddEntityComponent("pfm_cone_wireframe")
		if(c ~= nil) then
			local lightSpotC = self:GetEntityComponent(ents.COMPONENT_LIGHT_SPOT)
			if(lightSpotC ~= nil) then
				lightSpotC:GetOuterConeAngleProperty():AddCallback(function() if(c:IsValid()) then c:SetConeModelDirty() end end)
			end

			local radiusC = self:GetEntityComponent(ents.COMPONENT_RADIUS)
			if(radiusC ~= nil) then
				radiusC:GetRadiusProperty():AddCallback(function() if(c:IsValid()) then c:SetConeModelDirty() end end)
			end
		end
	end
	local c = self:GetEntityComponent("pfm_cone_wireframe")
	if(c ~= nil) then c:SetConeModelVisible(selected) end
	self.m_updateSelectionWireframe = nil
end
function ents.PFMLightSpot:OnSelectionChanged(selected)
	-- We need to update the selection wireframe, but we're not allowed to add
	-- or remove components in this event, so we defer it to the next tick instead.
	self.m_updateSelectionWireframe = selected
	self:SetTickPolicy(ents.TICK_POLICY_ALWAYS)
end
function ents.PFMLightSpot:Setup(actorData,lightData)
	local lightC = self:GetEntity():GetComponent("pfm_light")
	if(lightC ~= nil) then lightC:Setup(actorData,lightData) end
end
ents.COMPONENT_PFM_LIGHT_SPOT = ents.register_component("pfm_light_spot",ents.PFMLightSpot)
