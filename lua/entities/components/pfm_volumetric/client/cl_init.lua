--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.register_class("ents.PFMVolumetric",BaseEntityComponent)

function ents.PFMVolumetric:Initialize()
	BaseEntityComponent.Initialize(self)

	self:AddEntityComponent(ents.COMPONENT_MODEL)
	self:AddEntityComponent(ents.COMPONENT_RENDER)
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM)
	self.m_listeners = {}
end

function ents.PFMVolumetric:OnRemove()
	util.remove(self.m_listeners)
end

function ents.PFMVolumetric:OnEntitySpawn()
	self:BindEvent(ents.ModelComponent.EVENT_ON_MODEL_CHANGED,"OnModelChanged")
end

function ents.PFMVolumetric:OnModelChanged()
	self:UpdateMaterial()
end

function ents.PFMVolumetric:UpdateMaterial()
	local matName = self.m_volData:GetMaterialName()
	local mdlC = self:GetEntity():GetComponent(ents.COMPONENT_PFM_MODEL)
	if(mdlC ~= nil) then
		local matMappings = mdlC:GetModelData():GetMaterialMappings()
		matMappings:Insert(asset.get_normalized_path("white",asset.TYPE_MATERIAL),fudm.String(asset.get_normalized_path(matName,asset.TYPE_MATERIAL)))
		mdlC:UpdateModel()
	end
end

function ents.PFMVolumetric:Setup(actorData,volData)
	self.m_volData = volData
	self:UpdateMaterial()
	table.insert(self.m_listeners,volData:GetMaterialNameAttr():AddChangeListener(function(newMat) self:UpdateMaterial() end))
end
ents.COMPONENT_PFM_VOLUMETRIC = ents.register_component("pfm_volumetric",ents.PFMVolumetric)
