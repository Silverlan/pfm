--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

local Component = util.register_class("ents.PFMSelectionWireframe",BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnEntitySpawn()
	self:UpdateWireframe()

	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	self.m_onRenderMeshesUpdated = mdlC:AddEventCallback(ents.ModelComponent.EVENT_ON_RENDER_MESHES_UPDATED,function(mdl)
		self:UpdateWireframe()
	end)
end
function Component:OnRemove()
	util.remove(self.m_onRenderMeshesUpdated)
	
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	mdlC:SetRenderMeshesDirty()
	mdlC:UpdateRenderMeshes()
end
function Component:UpdateWireframe()
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if(mdlC == nil) then return end
	local mat = game.load_material('wireframe')
	if(util.is_valid(mat) == false) then return end
	local renderMeshes = mdlC:GetRenderMeshes()
	for _,mesh in ipairs(renderMeshes) do
		mdlC:AddRenderMesh(mesh,mat,false)
	end
end
ents.COMPONENT_PFM_SELECTION_WIREFRAME = ents.register_component("pfm_selection_wireframe",Component)
