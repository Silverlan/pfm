--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMBloom",BaseEntityComponent)

Component:RegisterMember("BlurRadius",udm.TYPE_UINT32,6,{
	onChange = function(self)
		self:UpdateBlurProperties()
	end,
    min = 0,
    max = 15
})
Component:RegisterMember("BlurSigma",udm.TYPE_FLOAT,10.0,{
	onChange = function(self)
		self:UpdateBlurProperties()
	end,
    min = 0,
    max = 10
})
Component:RegisterMember("BloomThreshold",udm.TYPE_FLOAT,1.0,{
	onChange = function(self)
		self:UpdateBlurProperties()
	end,
    min = 0,
    max = 10
})
Component:RegisterMember("BlurAmount",udm.TYPE_INT32,-1.0,{
    onChange = function(self)
        self:UpdateBlurProperties()
    end,
    min = -1,
    max = 20
})

function Component:GetRenderer()
    return game.get_scene():GetRenderer()
end

function Component:OnRemove()
    local renderer = self:GetRenderer()
    if(renderer == nil) then return end
    renderer:RemoveComponent(ents.COMPONENT_RENDERER_PP_BLOOM)
end

function Component:UpdateBlurProperties()
    local renderer = self:GetRenderer()
    if(renderer == nil) then return end
    local ppBloom = renderer:GetEntity():GetComponent(ents.COMPONENT_RENDERER_PP_BLOOM)
    if(ppBloom == nil) then return end
    ppBloom:SetBlurRadius(self:GetBlurRadius())
    ppBloom:SetBlurSigma(self:GetBlurSigma())
    ppBloom:SetBloomThreshold(self:GetBloomThreshold())
    ppBloom:SetBlurAmount(self:GetBlurAmount())
end

function Component:OnEntitySpawn()
    local renderer = self:GetRenderer()
    if(renderer == nil) then return end
    renderer:GetEntity():AddComponent(ents.COMPONENT_RENDERER_PP_BLOOM)
end
ents.COMPONENT_PFM_BLOOM = ents.register_component("pfm_bloom",Component)
