--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMVolumetric",BaseEntityComponent)

Component:RegisterMember("MaterialName",udm.TYPE_STRING,"volumes/generic_volume",{
	specializationType = ents.ComponentInfo.MemberInfo.SPECIALIZATION_TYPE_FILE,
	onChange = function(c) c:UpdateMaterial() end,
	metaData = {
		rootPath = "materials/",
		initialPath = "volumes",
		extensions = asset.get_supported_extensions(asset.TYPE_MATERIAL),
		stripExtension = true
	}
})

function Component:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
end

function Component:OnEntitySpawn()
	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,"OnModelChanged")
end

function Component:OnModelChanged()
	self:UpdateMaterial()
end

function Component:UpdateMaterial()
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	mdlC:SetMaterialOverride(0,self:GetMaterialName())
	mdlC:UpdateRenderMeshes()
end
ents.COMPONENT_PFM_VOLUMETRIC = ents.register_component("pfm_volumetric",Component)
