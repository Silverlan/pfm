-- SPDX-FileCopyrightText: (c) 2022 Silverlan <opensource@pragma-engine.com>
-- SPDX-License-Identifier: MIT

include("/shaders/pfm/selection_outline.lua")

local Component = util.register_class("ents.PFMSelectionWireframe", BaseEntityComponent)
function Component:Initialize()
	BaseEntityComponent.Initialize(self)
end
function Component:OnEntitySpawn()
	self:UpdateEffect()

	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	self.m_onRenderMeshesUpdated = mdlC:AddEventCallback(
		ents.ModelComponent.EVENT_ON_RENDER_MESHES_UPDATED,
		function(mdl)
			self:UpdateEffect()
		end
	)
	mdlC:SetRenderMeshesDirty()
	mdlC:UpdateRenderMeshes(false)
end
function Component:SetPersistent(persistent)
	self.m_persistent = persistent

	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	mdlC:SetRenderMeshesDirty()
	mdlC:UpdateRenderMeshes(false)
end
function Component:IsPersistent()
	return self.m_persistent or false
end
function Component:OnRemove()
	util.remove(self.m_onRenderMeshesUpdated)

	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil then
		return
	end
	mdlC:SetRenderMeshesDirty()
	mdlC:UpdateRenderMeshes(false)
end
function Component:UpdateEffect()
	local ent = self:GetEntity()
	local mdlC = ent:GetComponent(ents.COMPONENT_MODEL)
	if mdlC == nil or ent:GetColor().a < 255 then
		return
	end
	local mat = game.load_material(self:IsPersistent() and "pfm/selection_outline" or "pfm/selection_outline_hover")
	if util.is_valid(mat) == false then
		return
	end
	local renderMeshes = mdlC:GetRenderMeshes()
	for _, mesh in ipairs(renderMeshes) do
		if mesh:GetGeometryType() == game.Model.Mesh.Sub.GEOMETRY_TYPE_TRIANGLES then
			mdlC:AddRenderMesh(
				mesh,
				mat,
				ents.ModelComponent.RenderBufferData.STATE_FLAG_EXCLUDE_FROM_ACCELERATION_STRUCTURES_BIT
			)
		end
	end
end
ents.register_component("pfm_selection_wireframe", Component, "pfm", ents.EntityComponent.FREGISTER_BIT_HIDE_IN_EDITOR)
